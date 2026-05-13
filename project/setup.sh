#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")"

if ! command -v sbx >/dev/null 2>&1; then
  echo "sbx is not installed or is not on PATH."
  echo "Install Docker Sandboxes before running this lab."
  exit 1
fi

sbx version
sbx kit validate ./kits/container-best-practices
sbx kit validate ./kits/dhi-scout

cd demo/sample-app

if [ ! -d .git ]; then
  git init -q -b main
fi

git add .

if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
  git -c user.email=demo@example.com -c user.name=demo commit -q -m "init: leaddev sample app"
elif ! git diff --cached --quiet; then
  git -c user.email=demo@example.com -c user.name=demo commit -q -m "chore: refresh lab sample app"
fi

echo "Sample app is ready for sbx --branch."
