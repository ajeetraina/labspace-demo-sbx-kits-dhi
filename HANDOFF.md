# Demo Handoff

This repo contains the SBX Kits + Docker Hardened Images Labspace demo.
The demo is driven from the rendered Labspace instructions and their
talking points.

## Clone

```bash
git clone git@github.com:shelajev/labspace-demo-sbx-kits-dhi.git
cd labspace-demo-sbx-kits-dhi
```

If the repo already exists:

```bash
git pull --ff-only
```

## Install Labspace

Install or update the Docker Labspace CLI plugin:

```bash
gh release download v0.6.0 \
  --repo docker/docker-labspace-cli \
  --pattern docker-labspace-darwin-arm64 \
  --pattern checksums.sha256
shasum -a 256 -c checksums.sha256 --ignore-missing
mkdir -p ~/.docker/cli-plugins ~/.local/bin
install -m 0755 docker-labspace-darwin-arm64 ~/.docker/cli-plugins/docker-labspace
ln -sf ~/.docker/cli-plugins/docker-labspace ~/.local/bin/labspace
docker labspace version
```

Start Docker Desktop before launching the lab.

## Run

From the repository root:

```bash
CONTENT_PATH=$PWD docker labspace author
```

Open:

```text
Lab page: http://localhost:3030
Terminal: http://localhost:8085
```

For a non-authoring launch:

```bash
CONTENT_PATH=$PWD docker labspace launch ./compose.yaml -y
```

If the Labspace content pull returns `401 Unauthorized`, log in to Docker
Hub on the host and rerun the launch command:

```bash
docker login
```

## Present

Follow the Labspace sections in order:

1. **Step 0: Prerequisites**
   Set the Docker username variable and register the SBX custom secrets.
   Use a Docker Hub PAT that can pull DHI images and push to the demo
   namespace. If Docker Hub rejects the first push, create
   `<docker-username>/todo-demo-application` in Hub and rerun the push
   block.

2. **Start with a Plain Sandbox**
   Show that an agent can use a real shell and its own Docker daemon,
   filesystem, and network inside an isolated microVM sandbox. Use the
   network-policy checks and Dockerfile inspection commands as talking
   points. Push the baseline tag under the presenter's Docker namespace
   if you want fresh Hub / Scout evidence.

3. **Add the Best Practices Kit**
   Show that kits make sandboxes repeatable and shareable. One
   `spec.yaml` gives the agent the tools, credentials, network rules,
   files, startup commands, and guidance it needs to do real work the
   same way every time.

4. **Add the DHI Kit**
   Run the same prompt again with both kits. Point at `Skill(dhi)` in the
   Claude transcript, the DHI base images, the local size reduction, and
   then push the DHI tag under the same Docker namespace. Describe DHI as
   minimal, secure, production-ready images maintained by Docker.

5. **Hub / Scout Evidence**
   Open the repository created by the presenter:

   ```text
   https://hub.docker.com/repository/docker/<docker-username>/todo-demo-application/tags
   https://scout.docker.com/reports/org/<docker-username>/images/host/hub.docker.com/repo/<docker-username>%2Ftodo-demo-application
   ```

   Compare `sbx-dhi-baseline` with `sbx-dhi-dhi`. Focus on size,
   package count, vulnerability count, and the DHI-specific evidence.
   Some generic base-image policy cards may show `No data`; that is not
   the core demo signal.

## Validate

Before presenting or after edits:

```bash
sbx kit validate ./project/kits/container-best-practices
sbx kit validate ./project/kits/dhi
git diff --check
```

The Labspace teardown script removes the named demo sandboxes. Manual
cleanup is:

```bash
sbx rm -f prewarm p1-yolo p2-best-practices p4-dhi
```
