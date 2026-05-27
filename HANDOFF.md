# Restart Handoff

This file captures the current state of the SBX kits + DHI Labspace so
the work can be resumed after a machine restart.

## Repository

Run these commands from this repository root:

```bash
git status --short --branch
git pull --ff-only
```

Remote:

```text
git@github.com:shelajev/labspace-demo-sbx-kits-dhi.git
```

The Labspace payload is under `project/`. The rendered lab instructions
are under `labspace/`.

## What This Labspace Is

The lab demonstrates the same sample app through three increasingly
stronger SBX workflows:

1. Plain SBX sandbox: Claude containerizes the app with no extra policy.
2. SBX sandbox with `container-best-practices`: the kit installs
   hadolint and gives the agent Dockerfile guardrails.
3. SBX sandbox with `container-best-practices` plus `dhi`: the kit
   installs the Docker Hardened Images CLI, seeds Docker auth
   placeholders, and tells the agent to move the app to DHI base images.

For the final evidence view, use the already pushed baseline and DHI
image tags in Docker Hub / Docker Scout Dashboard. The demo does not
depend on running `docker scout` inside the sandbox.

## Restart Commands

After reboot, start Docker Desktop first.

Then start the Labspace from this repository root:

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

If the Labspace CLI plugin is missing, reinstall it:

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

If the Labspace base content pull returns `401 Unauthorized`, log in to
Docker Hub on the host with a PAT, then retry:

```bash
docker login
```

## Current Verification

Run these checks from this repository root after edits:

```bash
sbx kit validate ./project/kits/container-best-practices
sbx kit validate ./project/kits/dhi
git diff --check
```

When the host can pull the Labspace base content, also run:

```bash
CONTENT_PATH=$PWD docker compose config >/tmp/labspace-demo-compose-config.yaml
```

Optional smoke test:

```bash
sbx create --name kits-smoke claude ./project/demo/sample-app \
  --kit ./project/kits/container-best-practices \
  --kit ./project/kits/dhi

sbx exec kits-smoke bash -lc '
  test -f ~/.docker/config.json &&
  dhictl --version &&
  docker dhi --version &&
  hadolint --version &&
  ls ~/.claude/skills/ &&
  ls "$WORKSPACE_DIR"
'
```

Expected installed DHI tooling:

```text
dhictl version v0.0.3
dhi version v0.0.3
```

## DHI Secrets

Step 0 in the Labspace page registers Docker Hub and `dhi.io` auth
placeholders with `sbx secret set-custom`. Use a Docker Hub PAT as the
registry password. Do not paste the real PAT into the sandbox.

Global secrets are used for new sandboxes. If you change the secrets,
recreate the DHI sandbox:

```bash
cd ~/.labspace/project
sbx rm -f kits-smoke p4-dhi
```

Check real authenticated DHI access:

```bash
sbx exec kits-smoke bash -lc '
  docker dhi catalog list --json >/tmp/dhi-catalog.json &&
  docker pull dhi.io/node:24-debian13
'
```

If this returns `401 Unauthorized`, the install is still fine. It means
the PAT is missing, expired, does not have access to DHI, or the account
uses a Docker Hub organization mirror instead of direct `dhi.io` pulls.
Use the mirrored image reference shown by the DHI CLI or by the
organization setup.

## Demo Images

These tags are available for the Hub / Scout Dashboard comparison:

```text
docker.io/olegselajev241/todo-demo-application:sbx-dhi-baseline
docker.io/olegselajev241/todo-demo-application:sbx-dhi-dhi
```

Useful views:

```text
https://hub.docker.com/r/olegselajev241/todo-demo-application/tags?name=sbx-dhi
https://scout.docker.com/org/olegselajev241/images/docker.io/olegselajev241/todo-demo-application
```

Observed local Scout comparison from the pushed repo:

```text
baseline: node:24-trixie-slim, 104 MB, 323 packages, 0C 0H 3M 22L 3?, policy FAILED
DHI:      dhi.io/node:24-debian13, 43 MB, 96 packages, 0C 0H 0M 8L, policy SUCCESS
delta:    -61 MB, -227 packages, -20 vulnerabilities, default non-root improved
```

## Cleanup

Manual cleanup:

```bash
sbx rm -f prewarm kits-smoke p1-yolo p2-best-practices p4-dhi
```

The Labspace teardown script also removes those demo sandboxes:

```yaml
teardown_script: |
  sbx rm --force prewarm kits-smoke p1-yolo p2-best-practices p4-dhi || true
```

## Notes

- The Labspace uses `compose.override.yaml` to switch the workspace to
  the host-backed Labspace terminal provider.
- `compose.yaml` includes `sync-service`, which syncs `project/` into
  `~/.labspace/project` for development.
- The `dhi` kit intentionally does not store the real Docker PAT in the
  sandbox. It writes fake Docker auth placeholders and relies on
  host-side `sbx secret set-custom` replacements for registry requests.
