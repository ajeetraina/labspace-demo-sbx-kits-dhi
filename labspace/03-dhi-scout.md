# Add the DHI and Scout Kit

The final step adds organization-specific policy. The `dhi-scout` kit tells the agent to use Docker Hardened Images and verify the image with Docker Scout before declaring it shippable.

This step expects the Docker credentials from Step 0. The `dhi-scout`
kit writes Docker auth placeholders into `~/.docker/config.json` for
Docker Hub and `dhi.io`. Step 0 registers host-side SBX custom secrets
that replace those placeholders for registry requests, DHI CLI requests,
and Docker Scout requests. If you added or changed those secrets after
creating `p4-policy`, remove and recreate that sandbox before continuing.

Inspect the kit:

```bash
cd ~/.labspace/project
sbx kit inspect ./kits/dhi-scout
sed -n '1,100p' ./kits/dhi-scout/files/home/.claude/skills/dhi-scout/SKILL.md
```

Run a fresh sandbox with both kits:

```bash
cd ~/.labspace/project/demo/sample-app
sbx run --name p4-policy claude \
  --kit ../../kits/container-best-practices \
  --kit ../../kits/dhi-scout
```

Ask Claude:

```text
Harden the image and confirm it's shippable under our Scout policy.
```

The expected workflow is:

```bash
docker dhi catalog list --json
docker dhi catalog get node --json
docker build -t app:dev .
docker scout environment
docker scout quickview app:dev
docker scout cves --only-severity critical,high app:dev
docker scout policy app:dev
```

The kit should block a “push” recommendation if policy fails. If policy passes, the agent should report the image, base image, size, Scout policy status, high/critical CVE count, and next action.

If the account uses DHI Community images, expect `dhi.io/...` image
references. If the account uses a DHI Select or Enterprise mirror, use
the Docker Hub organization namespace shown by the DHI CLI or your org
configuration. The Docker PAT from Step 0 is used as the Docker registry
password through SBX secrets; the real value is not present in the
sandbox.

You can verify that both kit tools were installed in a throwaway sandbox:

```bash
cd ~/.labspace/project
sbx create --name kits-smoke claude ./demo/sample-app \
  --kit ./kits/container-best-practices \
  --kit ./kits/dhi-scout

sbx exec kits-smoke bash -lc '
  test -f ~/.docker/config.json &&
  grep -q "c2J4X2RvY2tlcl9odWJfdXNlcjpzYnhfZG9ja2VyX2h1Yl9wYXQ=" ~/.docker/config.json &&
  grep -q "c2J4X2RoaV91c2VyOnNieF9kaGlfcGF0" ~/.docker/config.json &&
  (env | grep -E "^(DOCKER_HUB_CREDS|DHI_CREDS|DHI_API_TOKEN|DOCKER_SCOUT_)" | sort || true) &&
  hadolint --version &&
  dhictl --version &&
  docker dhi --version &&
  docker scout version | sed -n "/^version:/p" &&
  ls ~/.claude/skills/ &&
  ls "$WORKSPACE_DIR"
'
```

After Step 0 secrets are configured, you can also test real authenticated
DHI access with an image your account can pull:

```bash
sbx exec kits-smoke bash -lc '
  docker dhi catalog list --json >/tmp/dhi-catalog.json &&
  docker pull dhi.io/node:20
'
```

If that pull is denied, check whether your DHI access is through a
Docker Hub organization mirror instead of direct `dhi.io` access, then
pull the mirrored image reference shown by `docker dhi`.

Clean up when finished:

```bash
sbx rm -f prewarm kits-smoke p1-yolo p2-best-practices p4-policy
```

The Labspace teardown script also removes these demo sandboxes when the lab is stopped.
