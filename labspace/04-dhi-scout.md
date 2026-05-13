# Gate with DHI and Scout

The DHI Scout kit adds a local policy gate after the Dockerfile builds.

Inspect the kit:

```bash
sbx kit inspect ./kits/dhi-scout
sed -n '1,80p' ./kits/dhi-scout/files/home/.claude/skills/dhi-scout/SKILL.md
```

Run a sandbox with both kits:

```bash
cd demo/sample-app
sbx run --name p4-policy claude \
  --kit ../../kits/container-best-practices \
  --kit ../../kits/dhi-scout
```

Ask Claude to harden the image and confirm it is shippable under Scout policy.

The agent should build the image, run Docker Scout CVE checks, run the policy evaluation, and report whether the image can be pushed.

When the Labspace is torn down, it runs a teardown script that removes the demo sandboxes and prunes the local SBX worktree directory.

You can run the same cleanup manually when finished:

```bash
sbx rm -f prewarm kits-smoke p1-yolo p2-best-practices p3-claude p3-opencode p4-policy
rm -rf demo/sample-app/.sbx
git -C demo/sample-app worktree prune
```
