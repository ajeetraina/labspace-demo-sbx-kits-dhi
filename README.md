# SBX Kits DHI Labspace

This is the Labspace wrapper for the SBX kits and Docker Hardened Images demo.

The Labspace uses the host-backed `ttyd` provider from the Docker Labspace CLI plugin so `sbx` can create sandboxes with host access. The demo payload lives under `project/`.

## Local Development

Install the Docker Labspace CLI plugin, then run:

```bash
gh release download v0.4.0 \
  --repo docker/docker-labspace-cli \
  --pattern docker-labspace-darwin-arm64 \
  --pattern checksums.sha256
shasum -a 256 -c checksums.sha256 --ignore-missing
mkdir -p ~/.docker/cli-plugins ~/.local/bin
install -m 0755 docker-labspace-darwin-arm64 ~/.docker/cli-plugins/docker-labspace
ln -sf ~/.docker/cli-plugins/docker-labspace ~/.local/bin/labspace
docker labspace version
```

```bash
SHELL=$PWD/bin/labspace-shell CONTENT_PATH=$PWD docker compose up --watch
```

Inside the Labspace terminal, follow the Prerequisites section.

## Contents

- `compose.yaml` adds the development sync service for host-backed project files.
- `compose.override.yaml` switches the workspace to the Labspace `ttyd` provider and disables `host-republisher`.
- `labspace/labspace.yaml` defines the lab metadata and sections.
- `project/` contains the SBX kits demo.
