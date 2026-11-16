#!/usr/bin/env ruby
# frozen_string_literal: true

# Rewrite the version and the per-arch sha256 of a two-arch cask in place:
#
#   set-cask-version.rb Casks/<name>.rb <old-version> <new-version> <arm-sha256> <intel-sha256>
#
# Used by the release tracker for casks whose root-level `sha256 arm:/intel:`
# map brew bump-cask-pr cannot refresh (it only hashes the current
# architecture). Each line must match exactly once, so a cask whose layout
# drifts from the expected shape fails loudly instead of being half-edited.

path, old, latest, arm, intel = ARGV
abort "usage: #{$PROGRAM_NAME} <cask.rb> <old> <new> <arm-sha256> <intel-sha256>" if intel.nil?
[arm, intel].each { |sum| abort "not a sha256: #{sum}" unless sum.match?(/\A\h{64}\z/) }

contents = File.read(path)
{
  /^  version "#{Regexp.escape(old)}"$/ => "  version \"#{latest}\"",
  /^  sha256 arm:\s+"\h{64}",$/         => "  sha256 arm:   \"#{arm}\",",
  /^         intel:\s+"\h{64}"$/        => "         intel: \"#{intel}\"",
}.each do |pattern, replacement|
  raise "Expected exactly one #{pattern} in #{path}" if contents.scan(pattern).length != 1

  contents.sub!(pattern, replacement)
end
File.write(path, contents)
