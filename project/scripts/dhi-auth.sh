#!/usr/bin/env sh
set -eu

docker_username=${1:-${DOCKER_HUB_USER:-${DOCKERHUB_USERNAME:-}}}
docker_password=${DOCKER_HUB_PASSWORD:-}

if [ -z "$docker_username" ]; then
  echo "Usage: $0 <docker-username>" >&2
  echo "Or set DOCKER_HUB_USER." >&2
  exit 1
fi

if ! command -v sbx >/dev/null 2>&1; then
  echo "ERROR: sbx is not on PATH." >&2
  exit 1
fi

docker_hub_auth_placeholder_b64="c2J4X2RvY2tlcl9odWJfdXNlcjpzYnhfZG9ja2VyX2h1Yl9wYXQK"
dhi_auth_placeholder_b64="c2J4X2RoaV91c2VyOnNieF9kaGlfcGF0Cg=="

if [ -z "$docker_password" ]; then
  printf 'Paste Docker password/PAT for %s: ' "$docker_username" > /dev/tty
  IFS= read -r -s docker_password < /dev/tty
  printf '\n' > /dev/tty
fi

if [ -z "$docker_password" ]; then
  echo "No password/PAT entered; nothing was changed." >&2
  exit 1
fi

registry_auth_b64=$(printf '%s:%s' "$docker_username" "$docker_password" | base64 | tr -d '\n')

sbx secret set-custom -g \
  --host auth.docker.io \
  --env DOCKER_HUB_CREDS \
  --placeholder "$docker_hub_auth_placeholder_b64" \
  --value "$registry_auth_b64"

sbx secret set-custom -g \
  --host dhi.io \
  --env DHI_CREDS \
  --placeholder "$dhi_auth_placeholder_b64" \
  --value "$registry_auth_b64"

unset docker_password registry_auth_b64

echo "Registered SBX custom secrets for Docker Hub and dhi.io."
echo "Recreate any existing DHI sandboxes so they pick up the global secrets."
