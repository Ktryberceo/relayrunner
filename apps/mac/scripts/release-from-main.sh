#!/usr/bin/env bash
# Releases RelayRunner for Mac from the latest main, in a separate worktree, so the checkout you work in
# stays as it is. Run it from any checkout of the repo:
#
#   pnpm release:mac:dry-run   build and notarize only
#   pnpm release:mac           and publish
#
# It fetches main, puts the release worktree (../relayrunner-release next to this checkout, or
# $RELAYRUNNER_RELEASE_WORKTREE) on origin/main, installs dependencies there and runs release.sh in it
# with the same arguments.
set -euo pipefail

root="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
worktree="${RELAYRUNNER_RELEASE_WORKTREE:-$(dirname "$root")/relayrunner-release}"
fail() { echo "error: $*" >&2; exit 1; }

git -C "$root" fetch --quiet origin main
if [[ -d "$worktree" ]]; then
  git -C "$worktree" rev-parse --is-inside-work-tree >/dev/null 2>&1 ||
    fail "$worktree exists but isn't a git worktree. Move it or set RELAYRUNNER_RELEASE_WORKTREE."
  [[ -z "$(git -C "$worktree" status --porcelain)" ]] ||
    fail "$worktree has uncommitted changes. Clean it up first."
  git -C "$worktree" checkout --quiet --detach origin/main
else
  git -C "$root" worktree add --quiet --detach "$worktree" origin/main
fi
echo "Releasing from $(git -C "$worktree" log -1 --format='%h %s') in $worktree"

(cd "$worktree" && pnpm install --frozen-lockfile)
exec "$worktree/apps/mac/scripts/release.sh" "$@"
