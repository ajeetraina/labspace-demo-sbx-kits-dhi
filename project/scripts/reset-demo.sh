#!/usr/bin/env sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sample_dir="$repo_root/demo/sample-app"
sample_root=$(cd "$sample_dir" && pwd -P)

if command -v sbx >/dev/null 2>&1; then
  sbx rm -f prewarm p1-yolo p2-best-practices p2-vscode p4-dhi >/dev/null 2>&1 || true
fi

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
else
  git -C "$sample_dir" reset --hard HEAD >/dev/null
  git -C "$sample_dir" clean -fd >/dev/null
fi

echo "Reset demo sandboxes and restored demo/sample-app to its initial git state."
