#!/usr/bin/env sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sandbox_name=${SBX_SMOKE_NAME:-kits-smoke}

cleanup() {
  sbx rm -f "$sandbox_name" >/dev/null 2>&1 || true
}

cd "$repo_root"

if ! command -v sbx >/dev/null 2>&1; then
  echo "ERROR: sbx is not on PATH." >&2
  exit 1
fi

trap cleanup EXIT INT TERM
cleanup

sbx create --name "$sandbox_name" claude ./demo/sample-app \
  --kit ./kits/container-best-practices \
  --kit ./kits/dhi

sbx exec "$sandbox_name" bash -lc '
  test -f ~/.docker/config.json &&
  python3 - <<PY &&
import json
from pathlib import Path
auths = json.loads(Path.home().joinpath(".docker/config.json").read_text())["auths"]
assert "https://index.docker.io/v1/" in auths
assert auths["https://dhi.io"]["auth"] == "c2J4X2RoaV91c2VyOnNieF9kaGlfcGF0Cg=="
PY
  dhictl --version &&
  docker dhi --version &&
  hadolint --version &&
  ls ~/.claude/skills/ &&
  for path in package.json package-lock.json tsconfig.json src/app.ts src/server.ts public/index.html; do
    test -f "$WORKSPACE_DIR/$path" && echo "$path"
  done
'
