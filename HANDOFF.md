# Restart Handoff

This file captures the current state of the SBX kits + DHI Labspace so
the work can be resumed after a machine restart.

## Repository

Labspace wrapper repo:

```bash
cd ~/ai-contrib/docker/labspace-demo-sbx-kits-dhi
git status --short --branch
git pull --ff-only
```

Remote:

```text
git@github.com:shelajev/labspace-demo-sbx-kits-dhi.git
```

Last pushed implementation commit:

```text
a95584c docs: wire DHI CLI and SBX auth placeholders
```

The older standalone demo repo is adjacent:

```bash
cd ~/ai-contrib/docker/sbx-kits-demo
```

That repo is not the Labspace. The Labspace content is under
`~/ai-contrib/docker/labspace-demo-sbx-kits-dhi/project`.

## What This Labspace Is

The lab demonstrates the same sample app through three increasingly
stronger SBX workflows:

1. Plain SBX sandbox: Claude containerizes the app with no extra policy.
2. SBX sandbox with `container-best-practices`: the kit installs
   hadolint and gives the agent Dockerfile guardrails.
3. SBX sandbox with `container-best-practices` plus `dhi-scout`: the kit
   installs Docker Scout, installs the DHI CLI, seeds Docker auth
   placeholders, and tells the agent to use DHI images and run Scout
   policy before calling the image shippable.

Worktrees and parallel agents are no longer part of this Labspace flow.

## Restart Commands

After reboot, start Docker Desktop first.

Then start the Labspace from the wrapper repo:

```bash
cd ~/ai-contrib/docker/labspace-demo-sbx-kits-dhi
SHELL=$PWD/bin/labspace-shell CONTENT_PATH=$PWD docker compose up --watch
```

Open:

```text
Lab page: http://localhost:3030
Terminal: http://localhost:8085
```

If the Labspace CLI plugin is missing, reinstall it:

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

## Current Verification Status

Already verified locally:

```bash
sbx kit validate ./project/kits/container-best-practices
sbx kit validate ./project/kits/dhi-scout
CONTENT_PATH=$PWD docker compose config >/tmp/labspace-demo-compose-config.yaml
git diff --check
```

Also verified with a throwaway sandbox:

```bash
sbx create --name kits-smoke claude ./project/demo/sample-app \
  --kit ./project/kits/container-best-practices \
  --kit ./project/kits/dhi-scout

sbx exec kits-smoke bash -lc '
  test -f ~/.docker/config.json &&
  dhictl --version &&
  docker dhi --version &&
  hadolint --version &&
  docker scout version | sed -n "/^version:/p" &&
  ls ~/.claude/skills/ &&
  ls "$WORKSPACE_DIR"
'
```

The observed versions were:

```text
dhictl version v0.0.3
dhi version v0.0.3
Haskell Dockerfile Linter 2.12.0
docker scout version v1.20.4
```

The kit also created Docker auth placeholder configs for both the
default `agent` user and `root`.

## What Is Left

The code and Labspace docs are implemented and pushed. The remaining
check is real authenticated DHI and Scout access using a Docker PAT from
an account that has DHI/Scout entitlement.

Run Step 0 in the Labspace page after restart. It asks for the Docker
username and then prompts for a Docker PAT. Use the PAT as the registry
password; do not paste the real PAT into the sandbox.

Then recreate the DHI sandbox because global SBX secrets are used when
new sandboxes are created:

```bash
cd ~/.labspace/project
sbx rm -f kits-smoke p4-policy

sbx create --name kits-smoke claude ./demo/sample-app \
  --kit ./kits/container-best-practices \
  --kit ./kits/dhi-scout
```

Check real authenticated DHI access:

```bash
sbx exec kits-smoke bash -lc '
  docker dhi catalog list --json >/tmp/dhi-catalog.json &&
  docker pull dhi.io/node:20
'
```

If this returns `401 Unauthorized`, the install is still fine. It means
the PAT is missing, expired, does not have access to DHI, or the account
uses a Docker Hub organization mirror instead of direct `dhi.io` pulls.
In that case, query the DHI CLI/catalog and use the mirrored image
reference for the organization.

After the real-auth smoke test passes, run the actual final demo sandbox:

```bash
cd ~/.labspace/project/demo/sample-app
sbx run --name p4-policy claude \
  --kit ../../kits/container-best-practices \
  --kit ../../kits/dhi-scout
```

Prompt:

```text
Harden the image and confirm it's shippable under our Scout policy.
```

Expected agent workflow:

```bash
docker dhi catalog list --json
docker dhi catalog get node --json
docker build -t app:dev .
docker scout environment
docker scout quickview app:dev
docker scout cves --only-severity critical,high app:dev
docker scout policy app:dev
```

## Cleanup

Manual cleanup:

```bash
sbx rm -f prewarm kits-smoke p1-yolo p2-best-practices p4-policy
```

The Labspace teardown script also removes those demo sandboxes:

```yaml
teardown_script: |
  sbx rm --force prewarm kits-smoke p1-yolo p2-best-practices p4-policy || true
```

## Notes

- The Labspace uses `compose.override.yaml` to switch the workspace to
  the host-backed Labspace terminal provider.
- `compose.yaml` includes `sync-service`, which syncs `project/` into
  `~/.labspace/project` for development.
- The `dhi-scout` kit intentionally does not store the real Docker PAT
  in the sandbox. It writes fake Docker auth placeholders and relies on
  host-side `sbx secret set-custom` replacements.
- The direct unauthenticated `docker dhi catalog list --json` check was
  tried once and returned `401 Unauthorized`, which is expected without
  the Step 0 PAT-backed secrets.
