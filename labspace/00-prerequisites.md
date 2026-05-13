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

Register the Docker username and PAT with SBX from the host-backed
Labspace terminal. The first secret is declared by the `dhi-scout` kit
and is used by the SBX proxy when the sandbox talks to Docker registry
auth endpoints:

```bash
export DOCKERHUB_USERNAME="<your-docker-username>"
read -rs DOCKERHUB_PAT
printf '\n'

printf '%s:%s' "$DOCKERHUB_USERNAME" "$DOCKERHUB_PAT" \
  | base64 \
  | tr -d '\n' \
  | sbx secret set -g docker-hub-basic-auth
```

Docker Scout's CLI also supports Docker Hub username/password
environment variables. Register those as custom secrets so the sandbox
only sees placeholders:

```bash
for host in api.scout.docker.com registry.scout.docker.com hub.docker.com; do
  sbx secret set-custom -g \
    --host "$host" \
    --env DOCKER_SCOUT_HUB_USER \
    --placeholder labspace-dockerhub-user \
    --value "$DOCKERHUB_USERNAME"

  sbx secret set-custom -g \
    --host "$host" \
    --env DOCKER_SCOUT_HUB_PASSWORD \
    --placeholder labspace-dockerhub-pat \
    --value "$DOCKERHUB_PAT"

  sbx secret set-custom -g \
    --host "$host" \
    --env DOCKER_SCOUT_REGISTRY_USER \
    --placeholder labspace-dockerhub-user \
    --value "$DOCKERHUB_USERNAME"

  sbx secret set-custom -g \
    --host "$host" \
    --env DOCKER_SCOUT_REGISTRY_PASSWORD \
    --placeholder labspace-dockerhub-pat \
    --value "$DOCKERHUB_PAT"
done

unset DOCKERHUB_PAT
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
