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
"$repo_root/scripts/reset-demo.sh"

echo "Sample app repo is ready for sbx --branch worktrees."
echo
echo "Pre-flight complete."
