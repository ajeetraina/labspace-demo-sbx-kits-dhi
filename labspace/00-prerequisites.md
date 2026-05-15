# Step 0: Prerequisites

This Labspace uses a host-backed terminal so `sbx` can create real sandboxes from your machine.

Confirm Docker and SBX are available:

```bash
docker version
sbx version
```

Check SBX authentication:

```bash
sbx diagnose
```

If authentication fails, sign in:

```bash
sbx login
```

Prepare Docker credentials for the DHI and Scout step:

1. Create a Docker Personal Access Token (PAT) from Docker Home:
   **Account settings** -> **Personal access tokens** -> **Generate token**.
2. Give it access to the Docker account or organization that can pull
   Docker Hardened Images and run Docker Scout policy checks.
3. Copy the token once. Docker will not show it again.

Use the PAT as the Docker registry password. Do not use the Docker
account password for this lab.

Set the Docker username for the rest of this lab:

::variableDefinition[dockerUsername]{prompt="Docker username"}

:variableSetButton[Use olegselajev241]{variables="dockerUsername=olegselajev241"}

Expert path: set the Docker username variable and register the Docker
PAT-backed secrets in one terminal command. When prompted, paste the PAT
and press Enter. Input is hidden.

This does not put the PAT in the sandbox. The `dhi-scout` kit writes a
Docker config with fake auth placeholders; these host-side SBX custom
secrets replace those placeholders only when outbound Docker Hub, DHI,
DHI CLI, or Scout requests pass through the SBX proxy.

```bash
DOCKERHUB_USERNAME="$$dockerUsername$$" bash <<'SCRIPT'
set -euo pipefail

DOCKER_HUB_AUTH_PLACEHOLDER_B64="c2J4X2RvY2tlcl9odWJfdXNlcjpzYnhfZG9ja2VyX2h1Yl9wYXQ="
DHI_AUTH_PLACEHOLDER_B64="c2J4X2RoaV91c2VyOnNieF9kaGlfcGF0"
DHI_API_TOKEN_PLACEHOLDER="labspace-dhi-api-token"
SCOUT_USER_PLACEHOLDER="labspace-dockerhub-user"
SCOUT_PAT_PLACEHOLDER="labspace-dockerhub-pat"

if [ -z "${DOCKERHUB_USERNAME:-}" ] || [ "$DOCKERHUB_USERNAME" = "dockerUsername" ]; then
  echo "Set the Docker username field in the lab instructions first." >&2
  exit 1
fi

printf 'Paste Docker PAT for %s: ' "$DOCKERHUB_USERNAME" > /dev/tty
IFS= read -r -s DOCKERHUB_PAT < /dev/tty
printf '\n' > /dev/tty

if [ -z "$DOCKERHUB_PAT" ]; then
  echo "No PAT entered; nothing was changed." >&2
  exit 1
fi

REGISTRY_AUTH_B64="$(printf '%s:%s' "$DOCKERHUB_USERNAME" "$DOCKERHUB_PAT" | base64 | tr -d '\n')"

sbx secret set-custom -g \
  --host auth.docker.io \
  --env DOCKER_HUB_CREDS \
  --placeholder "$DOCKER_HUB_AUTH_PLACEHOLDER_B64" \
  --value "$REGISTRY_AUTH_B64"

sbx secret set-custom -g \
  --host dhi.io \
  --env DHI_CREDS \
  --placeholder "$DHI_AUTH_PLACEHOLDER_B64" \
  --value "$REGISTRY_AUTH_B64"

for host in dhi.io api.docker.com hub.docker.com; do
  sbx secret set-custom -g \
    --host "$host" \
    --env DHI_API_TOKEN \
    --placeholder "$DHI_API_TOKEN_PLACEHOLDER" \
    --value "$DOCKERHUB_PAT"
done

for host in api.scout.docker.com registry.scout.docker.com hub.docker.com; do
  sbx secret set-custom -g \
    --host "$host" \
    --env DOCKER_SCOUT_HUB_USER \
    --placeholder "$SCOUT_USER_PLACEHOLDER" \
    --value "$DOCKERHUB_USERNAME"

  sbx secret set-custom -g \
    --host "$host" \
    --env DOCKER_SCOUT_HUB_PASSWORD \
    --placeholder "$SCOUT_PAT_PLACEHOLDER" \
    --value "$DOCKERHUB_PAT"

  sbx secret set-custom -g \
    --host "$host" \
    --env DOCKER_SCOUT_REGISTRY_USER \
    --placeholder "$SCOUT_USER_PLACEHOLDER" \
    --value "$DOCKERHUB_USERNAME"

  sbx secret set-custom -g \
    --host "$host" \
    --env DOCKER_SCOUT_REGISTRY_PASSWORD \
    --placeholder "$SCOUT_PAT_PLACEHOLDER" \
    --value "$DOCKERHUB_PAT"
done

unset DOCKERHUB_PAT REGISTRY_AUTH_B64
SCRIPT
```

Global secrets are used for new sandboxes. If you already created
`p4-policy`, remove and recreate it after setting or changing them:

```bash
sbx rm -f p4-policy
```

Do not paste the Docker PAT into the sandbox. The sandbox should only
receive proxy-managed placeholders; the real token stays on the host.

Validate the two kits packaged with the lab:

```bash
cd ~/.labspace/project
sbx kit validate ./kits/container-best-practices
sbx kit validate ./kits/dhi-scout
```

Optional: pre-pull the Claude sandbox template so the first demo command starts faster:

```bash
sbx create --name prewarm claude /tmp && sbx rm -f prewarm
```
