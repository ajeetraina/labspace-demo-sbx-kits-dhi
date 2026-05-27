#!/usr/bin/env sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sample_dir="$repo_root/demo/sample-app"
sample_root=$(cd "$sample_dir" && pwd -P)

cd "$repo_root"

if ! command -v sbx >/dev/null 2>&1; then
  echo "ERROR: sbx is not on PATH." >&2
  exit 1
fi

echo "sbx version:"
sbx version

echo
echo "Validating kits..."
sbx kit validate ./kits/container-best-practices
sbx kit validate ./kits/dhi

echo
echo "Pre-pulling claude template..."
sbx rm -f prewarm >/dev/null 2>&1 || true
sbx create --name prewarm claude /tmp >/dev/null
sbx rm -f prewarm >/dev/null

echo
echo "Preparing sample app git repo..."

git_root=
if git -C "$sample_dir" rev-parse --show-toplevel >/dev/null 2>&1; then
  git_root=$(git -C "$sample_dir" rev-parse --show-toplevel)
fi

if [ "$git_root" != "$sample_root" ]; then
  git -C "$sample_dir" init -q -b main
fi

if ! git -C "$sample_dir" rev-parse --verify HEAD >/dev/null 2>&1; then
  git -C "$sample_dir" add .
  git -C "$sample_dir" \
    -c user.email=demo@example.com \
    -c user.name=demo \
    commit -q -m "init: leaddev sample app"
fi

if ! git -C "$sample_dir" diff --quiet ||
  ! git -C "$sample_dir" diff --cached --quiet; then
  echo "ERROR: demo/sample-app has uncommitted changes." >&2
  echo "Commit, stash, or reset them before running the worktree demo." >&2
  exit 1
fi

echo "Sample app repo is ready for sbx --branch worktrees."
echo
echo "Pre-flight complete."
