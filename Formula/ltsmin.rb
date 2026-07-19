class Ltsmin < Formula
  desc "Language-independent model checker"
  homepage "https://github.com/utwente-fmt/ltsmin"
  url "https://github.com/utwente-fmt/ltsmin/releases/download/v3.0.2/ltsmin-v3.0.2-source.tgz"
  sha256 "752b78505e1e6eeff92c455f17df77ae6707ad41e0c06571d118221f62016e7d"
  license all_of: ["BSD-3-Clause", "GPL-2.0-or-later"]

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on "bison" => :build
  depends_on "flex" => :build
  depends_on "pkgconf" => :build
  depends_on "prob" => :test
  depends_on "czmq"
  depends_on "gmp"
  depends_on macos: :big_sur
  depends_on "popt"

  uses_from_macos "libxml2"
  uses_from_macos "zlib"

  # LTSmin 3.0.2 predates CZMQ's zsock API, hides the Lace option ProB passes
  # without Sylvan, and hard-codes x86 fence/pause instructions. The ARM changes
  # make the sources compile, but do not turn its explicitly x86-ordered
  # multicore algorithms into supported ARM code.
  patch :DATA

  def install
    ENV.append_path "PATH", formula_opt_bin("bison")
    ENV.append_path "PATH", formula_opt_bin("flex")
    ENV.append "CPPFLAGS", "-I#{formula_opt_include("popt")}"

    args = std_configure_args + %w[
      --disable-dependency-tracking
      --disable-dist
      --disable-opaal
      --disable-scoop
      --disable-werror
      --with-bignum=gmp
      --with-spins=no
      --without-buddy
      --without-spot
      --without-sylvan
    ]

    system "./configure", *args
    system "make"
    system "make", "install"

    # These launchers are built even when their optional compiler/runtime is
    # disabled. Do not expose commands that cannot work in this formula.
    [bin/"spins", bin/"ce-mpi", bin/"ltsmin-reduce-dist"].select(&:exist?).each(&:unlink)
    bin.glob("*-dist").each(&:unlink)

    # Upstream's multicore memory model assumes x86 strong ordering. Sequential
    # and symbolic backends are native on both architectures; multicore remains
    # available only on Intel.
    bin.glob("*-mc").each(&:unlink) if Hardware::CPU.arm?

    # The release archive contains generated manual pages, but upstream only
    # installs them when AsciiDoc and xmlto are present. Install pages matching
    # the commands retained above without adding documentation build tools.
    bin.children.each do |command|
      page = buildpath/"doc/#{command.basename}.1"
      man1.install page if page.exist?
    end
    man5.install Dir["doc/*.5"]
    man7.install "doc/ltsmin.7"
    bash_completion.install "contrib/bash-completion/ltsmin"
  end

  def caveats
    <<~EOS
      This is a native core build with ETF, PNML and ProB sequential/symbolic
      backends. SpinS, MPI/distributed, Spot/BuDDy, Sylvan and legacy mCRL
      adapters are not included. Multicore backends are Intel-only because
      LTSmin 3.0.2's concurrency implementation assumes x86 memory ordering.

      The native 64-bit ListDD symbolic backend supports ProB deadlock and
      invariant checking. Sylvan's parallel symbolic backends are not included.

      To use LTSmin with this tap's ProB formula:
        probcli MODEL -mc_with_lts_seq -nodead -p LTSMIN "#{opt_bin}"
    EOS
  end

  test do
    assert_match "v#{version}", shell_output("#{bin}/ltsmin-convert --version 2>&1", 255)
    assert_path_exists bin/"prob2lts-seq"
    assert_path_exists bin/"prob2lts-sym"
    assert_path_exists bin/"ltsmin-printtrace"
    assert_match "--lace-workers", shell_output("#{bin}/prob2lts-sym --help 2>&1", 255)

    (testpath/"cycle.etf").write <<~EOS
      begin state
      x:int
      end state
      begin edge
      end edge
      begin init
      0
      end init
      begin trans
      0/1
      1/0
      end trans
    EOS

    assert_match "2 states 2 transitions", shell_output("#{bin}/etf2lts-seq cycle.etf 2>&1")
    assert_match "state space has 2", shell_output("#{bin}/etf2lts-sym cycle.etf 2>&1")

    if Hardware::CPU.arm?
      refute_path_exists bin/"etf2lts-mc"
    else
      assert_match "2 states 2 transitions", shell_output("#{bin}/etf2lts-mc cycle.etf 2>&1")
    end

    (testpath/"safe.mch").write <<~EOS
      MACHINE LTSminSafe
      VARIABLES x
      INVARIANT x : 0..1
      INITIALISATION x := 0
      OPERATIONS
        toggle = PRE x = 0 THEN x := 1 END;
        reset = PRE x = 1 THEN x := 0 END
      END
    EOS

    probcli = formula_opt_bin("prob")/"probcli"
    output = shell_output("#{probcli} safe.mch -mc_with_lts_sym -nodead -p LTSMIN #{bin} 2>&1")
    assert_match "Creating a native ListDD 64-bit domain", output
    assert_match "LTSMin found no counter example", output
  end
end

__END__
diff --git a/configure b/configure
index e446d04..56f0857 100755
--- a/configure
+++ b/configure
@@ -24846,7 +24846,7 @@ fi
 fi
 
 fi
-     if text x"$with_bignum" = xyes || test x"$with_bignum" = xtommath; then :
+     if test x"$with_bignum" = xyes || test x"$with_bignum" = xtommath; then :
   { $as_echo "$as_me:${as_lineno-$LINENO}: checking for mp_init in -ltommath" >&5
 $as_echo_n "checking for mp_init in -ltommath... " >&6; }
 if ${ac_cv_lib_tommath_mp_init+:} false; then :
diff --git a/src/mc-lib/atomics.h b/src/mc-lib/atomics.h
index 2ea3c0c..698fbd2 100644
--- a/src/mc-lib/atomics.h
+++ b/src/mc-lib/atomics.h
@@ -29,15 +29,24 @@ foreseeable future.
 #define sub_fetch(a, b)     __sync_sub_and_fetch(a,b)
 #define prefetch(a)         __builtin_prefetch(a)
 
+#if defined(__aarch64__) || defined(__arm64__)
+
+#define mfence() __sync_synchronize()
+
+/* Yield execution priority while polling on ARM. */
+#define cpu_relax() asm volatile("yield\n": : :"memory")
+
+#else
+
 #define mfence() { asm volatile("mfence" ::: "memory"); }
 
-/* Compile read-write barrier */
-#define compile_barrier() asm volatile("": : :"memory")
-
 /* Pause instruction to prevent excess processor bus usage */
 #define cpu_relax() asm volatile("pause\n": : :"memory")
 
+#endif
 
+/* Compile read-write barrier */
+#define compile_barrier() asm volatile("": : :"memory")
 
 /**
  * rwticket lock
diff --git a/src/prob-lib/prob_client.c b/src/prob-lib/prob_client.c
index 62b68b5..06aa675 100644
--- a/src/prob-lib/prob_client.c
+++ b/src/prob-lib/prob_client.c
@@ -15,8 +15,7 @@
 #include <hre/user.h>
 
 struct prob_client {
-    zctx_t* ctx;
-    void* zocket;
+    zsock_t* zocket;
     uint32_t id_count;
     char* file;
 };
@@ -47,21 +46,18 @@ prob_client_destroy(prob_client_t pc)
 void
 prob_connect(prob_client_t pc, const char* file)
 {
-    pc->ctx = zctx_new();
-    if (pc->ctx == NULL) Abort("Could not create zctx");
-    pc->zocket = zsocket_new(pc->ctx, ZMQ_REQ);
+    pc->zocket = zsock_new(ZMQ_REQ);
     if (pc->zocket == NULL) Abort("Could not create zsocket");
     pc->file = strdup(file);
 
-    if (zsocket_connect(pc->zocket, "%s", pc->file) != 0) Abort("Could not connect to zocket %s", pc->file);
+    if (zsock_connect(pc->zocket, "%s", pc->file) != 0) Abort("Could not connect to zocket %s", pc->file);
 }
 
 void
 prob_disconnect(prob_client_t pc)
 {
-    if (zsocket_disconnect(pc->zocket, "%s", pc->file) != 0) Warning(info, "Could not disconnect from zocket %s", pc->file);
-    zsocket_destroy(pc->ctx, pc->zocket);
-    zctx_destroy(&(pc->ctx));
+    if (zsock_disconnect(pc->zocket, "%s", pc->file) != 0) Warning(info, "Could not disconnect from zocket %s", pc->file);
+    zsock_destroy(&(pc->zocket));
 }
 
 const char*
diff --git a/src/vset-lib/vector_set.c b/src/vset-lib/vector_set.c
index 6d8c648..5051905 100644
--- a/src/vset-lib/vector_set.c
+++ b/src/vset-lib/vector_set.c
@@ -38,7 +38,7 @@ extern vdom_t vdom_create_lddmc_from_file(FILE *f);
 
 vset_implementation_t vset_default_domain = VSET_LDDmc;
 #else
-vset_implementation_t vset_default_domain = VSET_ListDD;
+vset_implementation_t vset_default_domain = VSET_ListDD64;
 #endif
 
 int vset_cache_diff = 0;
diff --git a/src/pins2lts-sym/options.c b/src/pins2lts-sym/options.c
index 1992ce3..7419e20 100644
--- a/src/pins2lts-sym/options.c
+++ b/src/pins2lts-sym/options.c
@@ -227,9 +227,9 @@ struct poptOption options[] = {
     { NULL, 0 , POPT_ARG_INCLUDE_TABLE, spg_solve_options , 0, "Symbolic parity game solver options", NULL},
     { "pg-write" , 0 , POPT_ARG_STRING , &pg_output, 0, "file to write symbolic parity game to","<pg-file>.spg" },
-#ifdef HAVE_SYLVAN
+#if defined(HAVE_SYLVAN) || defined(PROB)
     { NULL, 0 , POPT_ARG_INCLUDE_TABLE, lace_options , 0 , "Lace options",NULL},
 #endif
     { "no-matrix" , 0 , POPT_ARG_VAL , &no_matrix , 1 , "do not print the dependency matrix when -v (verbose) is used" , NULL},
     SPEC_POPT_OPTIONS,
     { NULL, 0 , POPT_ARG_INCLUDE_TABLE, greybox_options , 0, "PINS options",NULL},
