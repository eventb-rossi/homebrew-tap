#!/usr/bin/env bash
# Commit a version bump on its own branch, push it and open a PR against main:
#
#   open-bump-pr.sh [--auto-merge] [--closes ISSUE-TITLE] BRANCH TITLE BODY PATH...
#
# The shared tail of the release tracker's bump jobs. The caller has already
# checked that no PR exists for BRANCH (gh pr list --head BRANCH --state all)
# and rewritten PATH...; TITLE is both the commit subject and the PR title.
#
#   --auto-merge          enable squash auto-merge. Non-fatal: if "Allow
#                         auto-merge"/required checks aren't configured the PR
#                         is still opened for manual merge.
#   --closes ISSUE-TITLE  append "Closes #N" for the open `livecheck` issue with
#                         that exact title (filed by track-casks), looked up with
#                         $ISSUE_TOKEN, the job's own GITHUB_TOKEN.
#
# Needs HOMEBREW_GIT_NAME/HOMEBREW_GIT_EMAIL for the commit and GH_TOKEN, a PAT
# (VERSION_BUMP_TOKEN) so that the PR triggers CI, which GITHUB_TOKEN can't.
set -euo pipefail

auto_merge=false
closes=
while [[ $# -gt 0 ]]; do
  case "$1" in
    --auto-merge) auto_merge=true; shift ;;
    --closes) closes="$2"; shift 2 ;;
    *) break ;;
  esac
done
if [[ $# -lt 4 ]]; then
  echo "usage: $0 [--auto-merge] [--closes ISSUE-TITLE] BRANCH TITLE BODY PATH..." >&2
  exit 2
fi
branch="$1" title="$2" body="$3"
shift 3

if [[ -n "$closes" ]]; then
  issue="$(GH_TOKEN="$ISSUE_TOKEN" gh issue list --label livecheck --state open --limit 200 \
             --json number,title |
           jq -r --arg title "$closes" '[.[] | select(.title == $title) | .number] | first // empty')"
  if [[ -n "$issue" ]]; then
    body+=$'\n\n'"Closes #$issue"
  fi
fi

git config user.name  "$HOMEBREW_GIT_NAME"
git config user.email "$HOMEBREW_GIT_EMAIL"
git switch -c "$branch"
git add -- "$@"
git commit -m "$title"
# Force-push is safe: no PR references this branch (the caller checked), so an
# existing remote branch is an orphan from a run that failed before its PR.
git push -u --force origin "$branch"
url="$(gh pr create --base main --head "$branch" --title "$title" --body "$body")"
echo "Opened $url"
if $auto_merge; then
  gh pr merge --auto --squash "$url" \
    || echo "::warning::Could not enable auto-merge; merge $url manually."
fi
