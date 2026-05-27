# SBX Kits DHI Labspace

This is the Labspace wrapper for the SBX kits and Docker Hardened Images demo.

The Labspace uses the host-backed `ttyd` provider from the Docker Labspace CLI plugin so `sbx` can create sandboxes with host access. The demo payload lives under `project/`.

## Current State

Read [HANDOFF.md](./HANDOFF.md) before resuming after a restart. It
records the current implementation state, how to relaunch the Labspace,
what has already been verified, and the remaining real DHI credential
check.

## Local Development

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

Run the Labspace from this repository root:

```bash
CONTENT_PATH=$PWD docker labspace author
```

For a one-off local launch without authoring watch mode:

```bash
CONTENT_PATH=$PWD docker labspace launch ./compose.yaml -y
```

Open:

```text
Lab page: http://localhost:3030
Terminal: http://localhost:8085
```

Inside the Labspace terminal, follow Step 0.

If the Labspace base content pull returns `401 Unauthorized`, log in to
Docker Hub on the host with a PAT, then run the command again:

```bash
docker login
```

## Contents

- `compose.yaml` adds the development sync service for host-backed project files.
- `compose.override.yaml` switches the workspace to the Labspace `ttyd` provider and disables `host-republisher`.
- `labspace/labspace.yaml` defines the lab metadata and sections.
- `project/` contains the SBX kits demo.
