#!/usr/bin/env sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sample_dir="$repo_root/demo/sample-app"

# Remove the demo sandboxes. Each sandbox is keyed on its workspace directory
# plus agent, so only one can own demo/sample-app at a time; clearing them frees
# the workspace for the next run.
if command -v sbx >/dev/null 2>&1; then
  sbx rm -f prewarm p1-yolo p2-best-practices p2-vscode p4-dhi >/dev/null 2>&1 || true
fi

# Remove only the artifacts the agent generates during the demo, so the next
# pass starts from the same clean state. The app ships no Dockerfile of its
# own; the agent writes one as its task, and that Dockerfile is the single file
# it adds to the workspace (the image itself lives in the sandbox's Docker
# daemon and is removed with the sandbox above). The app sources (src/, public/,
# package*.json, tsconfig.json, .dockerignore, ...) are left intact.
rm -f "$sample_dir/Dockerfile"

# Older versions of this script seeded a nested git repo here to snapshot the
# "initial state". That snapshot went stale as the sample app changed and could
# delete current sources on reset, so it is no longer used. Remove any leftover
# nested repo if present.
rm -rf "$sample_dir/.git"

echo "Reset complete: removed demo sandboxes and the agent-generated Dockerfile."
echo "Sample app sources are untouched."
