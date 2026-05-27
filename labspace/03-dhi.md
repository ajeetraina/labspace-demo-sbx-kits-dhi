# Add the DHI Kit

The final step adds organization-specific base image guidance. The
`dhi` kit tells the agent to use Docker Hardened Images for both build
and runtime stages, then collect image evidence that can be shown in
Docker Hub / Docker Scout Dashboard after push.

This step expects the Docker credentials from Step 0. The `dhi` kit
writes Docker auth placeholders into `~/.docker/config.json` for Docker
Hub and `dhi.io`. Step 0 registers host-side SBX custom secrets that
replace those placeholders for registry requests. If you added or
changed those secrets after creating `p4-dhi`, remove and recreate that
sandbox before continuing.

If the best-practices sandbox is still open, press `Ctrl+C` twice: once
to stop Claude, and once more to exit the SBX session.

Remove the previous sandboxes before creating the DHI one. The same
workspace cannot be owned by multiple named sandboxes at once:

```bash
sbx rm -f p2-best-practices p4-dhi kits-smoke
```

Inspect the kit:

```bash
cd ~/.labspace/project
```

Talking point: this kit is a second mixin layered onto the same agent.
The best-practices kit handles generic container quality; the DHI kit
adds organization-specific base image policy and registry access.

```bash
sbx kit inspect ./kits/dhi
```

Point attention to the kit name, display name, and install/startup
steps. This is what SBX applies when `--kit ../../kits/dhi` is added to
the sandbox command.

```bash
cat ./kits/dhi/spec.yaml
```

Point attention to the DHI CLI install, `network.allowedDomains`, and
`configure-dhi-auth`. The important demo message is that the sandbox
gets DHI tooling and placeholder auth config at startup, while the real
Docker credential stays host-managed.

```bash
cat ./kits/dhi/files/home/.claude/skills/dhi/SKILL.md
```

Point attention to the skill rules: use DHI for every build/runtime base
image, use `dhi.io/node:24-debian13-dev` and
`dhi.io/node:24-debian13` for this Node demo, and collect evidence for
Hub / Scout Dashboard review after push.

Talking point: this is intentionally the same user task as before. The
difference is the kit stack. The DHI skill says that, when this kit is
installed, it has base-image precedence for containerization tasks, so
the agent should know about DHI without the user having to spell it out
in the prompt.

Run a fresh sandbox with both kits:

```bash
cd ~/.labspace/project/demo/sample-app
sbx run --name p4-dhi claude \
  --kit ../../kits/container-best-practices \
  --kit ../../kits/dhi
```

When Claude opens, use the run button on this block to paste the same
prompt as before into that Claude session:

```text
Containerize this app. Build the image and run it.
```

Talking point: call out the first lines of Claude output. You should
see `Skill(dhi)` and `Successfully loaded skill`. This is the proof that
the same user prompt is now interpreted through the DHI kit.

In the transcript, point out that the agent uses the DHI bases:

```text
dhi.io/node:24-debian13-dev
dhi.io/node:24-debian13
```

The local sandbox proves the agent can use the DHI policy. For the
shareable proof, switch to Docker Hub and Docker Scout. Open the Hub
tags page and point at the baseline and DHI tags:

```text
https://hub.docker.com/repository/docker/olegselajev241/todo-demo-application/tags
```

Use these two tags for comparison:

```text
docker.io/olegselajev241/todo-demo-application:sbx-dhi-baseline
docker.io/olegselajev241/todo-demo-application:sbx-dhi-dhi
```

On Hub, show the tag size difference. Then open the Docker Scout image
view:

```text
https://scout.docker.com/reports/org/olegselajev241/images/host/hub.docker.com/repo/olegselajev241%2Ftodo-demo-application
```

In Scout, select `sbx-dhi-baseline` and `sbx-dhi-dhi`, then click
Compare. Use the comparison to show the vulnerability and package-count
change. If you need a direct comparison link for this prepared demo,
open:

```text
https://scout.docker.com/reports/org/olegselajev241/images/compare/host/hub.docker.com/repo/olegselajev241%2Ftodo-demo-application/tag/sbx-dhi-baseline/digest/sha256%3A126733d8537c6b0a13ce66f20ac7010f801235e96d44cc59dfce5da70debbe5b/to/host/hub.docker.com/repo/olegselajev241%2Ftodo-demo-application/tag/sbx-dhi-dhi/digest/sha256%3A39af4388477e340ccaab07a5795d868b6e7db048dc38e30fb5629a90d87c1b3e/vulnerabilities
```

Talking point: do not make this section about in-sandbox Scout CLI
auth. The demo value is that the same prompt plus a different kit stack
produces a DHI-based image, and the pushed tags give a shareable Hub /
Scout view for size, packages, and vulnerabilities.

If Scout policy cards show `No data` for some base-image checks on the
DHI tag, do not dwell on that as the core proof. Those cards depend on
the policy metadata Scout has for that tag. The comparison view is the
stable demo artifact: baseline versus DHI image, size, package count,
and vulnerability count.

Clean up when finished:

```bash
sbx rm -f prewarm kits-smoke p1-yolo p2-best-practices p4-dhi
```

The Labspace teardown script also removes these demo sandboxes when the
lab is stopped.
