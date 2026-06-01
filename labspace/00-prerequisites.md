# Step 0: Prerequisites

This Labspace uses a host-backed terminal so `sbx` can create Docker
Sandboxes from your machine. A Docker Sandbox runs the agent in an
isolated microVM with its own Docker daemon, filesystem, and network.

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

Prepare Docker credentials for the DHI step:

1. Create a Docker Personal Access Token (PAT) from Docker Home:
   **Account settings** -> **Personal access tokens** -> **Generate token**.
2. Use a Docker account or organization that can pull Docker Hardened
   Images.
3. Give the token permission to push to your Docker Hub namespace. The
   lab publishes two comparison tags there.
4. Copy the token once. Docker will not show it again.

Use the PAT as the Docker registry password. Do not use the Docker
account password for this lab.

Set the Docker username for the rest of this lab:

::variableDefinition[dockerUsername]{prompt="Docker username"}

The lab uses this image repository for shareable Hub / Scout evidence:

```text
docker.io/$$dockerUsername$$/todo-demo-application
```

If Docker Hub rejects the first push with `denied`, create that
repository in Docker Hub under the same namespace and rerun the push
block.

Register the Docker Hub and `dhi.io` auth placeholders. This block reads
the PAT interactively, which the run button cannot drive (it would feed
the script's own lines into the hidden prompt), so the block below has no
run button. **Use its Copy button and paste it into the terminal
yourself.** When prompted, paste the PAT and press Enter. Input is hidden.

This does not put the PAT in the sandbox VM. The `dhi` kit writes a
Docker config with fake auth placeholders; host-side SBX custom secrets
replace those placeholders only when outbound registry requests pass
through the SBX proxy.

```bash no-run-button
DOCKERHUB_USERNAME="$$dockerUsername$$" bash <<'SCRIPT'
set -euo pipefail

DOCKER_HUB_AUTH_PLACEHOLDER_B64="c2J4X2RvY2tlcl9odWJfdXNlcjpzYnhfZG9ja2VyX2h1Yl9wYXQK"
DHI_AUTH_PLACEHOLDER_B64="c2J4X2RoaV91c2VyOnNieF9kaGlfcGF0Cg=="

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

unset DOCKERHUB_PAT REGISTRY_AUTH_B64
SCRIPT
```

Global secrets are used for new sandboxes. If you already created
`p4-dhi`, remove and recreate it after setting or changing secrets:

```bash
sbx rm -f p4-dhi
```

Do not paste the Docker PAT into the sandbox. The sandbox should only
receive proxy-managed placeholders; the real token stays on the host and
the proxy rewrites the outbound registry auth request.

Validate the two kits packaged with the lab:

```bash
cd ~/.labspace/project
sbx kit validate ./kits/container-best-practices
sbx kit validate ./kits/dhi
```

Reset the sample app before each demo pass. This creates the app's
nested Git repo if needed, removes old demo sandboxes, and restores the
sample app to the initial state so the agent can create `Dockerfile`
again:

```bash
cd ~/.labspace/project && ./scripts/reset-demo.sh
```

Optional: pre-pull the Claude sandbox template so the first demo command
starts faster:

```bash
sbx create --name prewarm claude /tmp && sbx rm -f prewarm
```
