# Gate with DHI and Scout

The final step adds organization-specific policy. The `dhi-scout` kit tells the agent to use Docker Hardened Images and to verify the resulting image with Docker Scout before declaring it shippable.

Inspect the DHI/Scout kit:

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
docker scout quickview app:dev
docker scout cves --only-severity critical,high app:dev
docker scout policy app:dev
```

The kit should block a “push” recommendation if policy fails. If policy passes, the agent should report the image, base image, size, Scout policy status, high/critical CVE count, and next action.

You can smoke-test the installed kit tools directly in a throwaway sandbox:

```bash
cd ~/.labspace/project
sbx create --name kits-smoke claude ./demo/sample-app \
  --kit ./kits/container-best-practices \
  --kit ./kits/dhi-scout

sbx exec kits-smoke bash -lc '
  hadolint --version &&
  docker scout version | sed -n "/^version:/p" &&
  ls ~/.claude/skills/ &&
  ls "$WORKSPACE_DIR"
'
```

When finished, clean up the demo artifacts:

```bash
sbx rm -f prewarm kits-smoke p1-yolo p2-best-practices p3-claude p3-opencode p4-policy
rm -rf ~/.labspace/project/demo/sample-app/.sbx
git -C ~/.labspace/project/demo/sample-app worktree prune
```

The Labspace teardown script also runs this cleanup when the lab is stopped.
