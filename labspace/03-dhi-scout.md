# Add the DHI and Scout Kit

The final step adds organization-specific policy. The `dhi-scout` kit tells the agent to use Docker Hardened Images and verify the image with Docker Scout before declaring it shippable.

This step expects the Docker credentials from Step 0. The `dhi-scout`
kit declares the `docker-hub-basic-auth` secret and uses the SBX proxy
for Docker registry auth. It also expects the Docker Scout custom
secrets from Step 0 for Scout's CLI environment variables. If you added
or changed those secrets after creating `p4-policy`, remove and recreate
that sandbox before continuing.

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
docker build -t app:dev .
docker scout environment
docker scout quickview app:dev
docker scout cves --only-severity critical,high app:dev
docker scout policy app:dev
```

The kit should block a “push” recommendation if policy fails. If policy passes, the agent should report the image, base image, size, Scout policy status, high/critical CVE count, and next action.

You can verify that both kit tools were installed in a throwaway sandbox:

```bash
cd ~/.labspace/project
sbx create --name kits-smoke claude ./demo/sample-app \
  --kit ./kits/container-best-practices \
  --kit ./kits/dhi-scout

sbx exec kits-smoke bash -lc '
  env | grep "^DOCKER_SCOUT_" | sort &&
  hadolint --version &&
  docker scout version | sed -n "/^version:/p" &&
  ls ~/.claude/skills/ &&
  ls "$WORKSPACE_DIR"
'
```

Clean up when finished:

```bash
sbx rm -f prewarm kits-smoke p1-yolo p2-best-practices p4-policy
```

The Labspace teardown script also removes these demo sandboxes when the lab is stopped.
