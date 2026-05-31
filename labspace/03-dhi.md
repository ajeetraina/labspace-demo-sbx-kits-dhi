# Add the DHI Kit

The final step adds organization-specific base image guidance. Docker
Hardened Images provide minimal, secure, production-ready images
maintained by Docker. The `dhi` kit tells the agent to use DHI for both
build and runtime stages, then collect image evidence that can be shown
in Docker Hub / Docker Scout Dashboard after push.

This step expects the Docker credentials from Step 0. The `dhi` kit
writes Docker auth placeholders into `~/.docker/config.json` for Docker
Hub and `dhi.io`. Step 0 registers host-side SBX custom secrets, and the
proxy rewrites outbound registry auth so the real credential does not
enter the sandbox VM. If you added or changed those secrets after
creating `p4-dhi`, remove and recreate that sandbox before continuing.

If the best-practices sandbox is still open, press `Ctrl+C` twice: once
to stop Claude, and once more to exit the SBX session.

Remove whatever sandbox currently holds this workspace before creating
the DHI one. A sandbox is keyed to its directory and agent, not its
`--name`, so the directory can only own one at a time (this clears every
demo sandbox name, so it works regardless of which step you ran last):

```bash
sbx rm -f p1-yolo p2-best-practices p2-vscode p4-dhi || true
```

Inspect the kit:

```bash
cd ~/.labspace/project
```

Talking point: this kit is a second mixin layered onto the same agent.
The best-practices kit handles generic container quality; the DHI kit
adds organization-specific base image policy, DHI tooling, network
rules, and registry access.

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
Docker credential stays host-managed and is applied by the proxy.

```bash
cat ./kits/dhi/files/home/.claude/skills/dhi/SKILL.md
```

Point attention to the skill rules: use DHI for every build/runtime base
image, use `dhi.io/node:24-debian13-dev` and
`dhi.io/node:24-debian13` for this Node demo, and collect evidence for
Hub / Scout Dashboard review after push. DHI is the base-image policy;
the kit makes that policy executable for the agent.

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

```bash
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

## Publish the DHI Tag

Use this after Claude has shown that the DHI kit is active. It pushes a
deterministic DHI image from the checked-in `Dockerfile.dhi` under the
same Docker namespace as the baseline tag:

```bash
! bash <<'SCRIPT'
set -euo pipefail

IMAGE="docker.io/$$dockerUsername$$/todo-demo-application"
if printf '%s' "$IMAGE" | grep -q 'dockerUsername'; then
  echo "Set the Docker username in Step 0 first." >&2
  exit 1
fi

case "$(uname -m)" in
  x86_64) PLATFORM=linux/amd64 ;;
  aarch64|arm64) PLATFORM=linux/arm64 ;;
  *) echo "unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

docker buildx build --push --platform "$PLATFORM" \
  --sbom=true --provenance=mode=max \
  -f Dockerfile.dhi \
  -t "${IMAGE}:sbx-dhi-dhi" .
SCRIPT
```

Talking point: this sandbox has the DHI kit, so Docker Hub and `dhi.io`
auth are both placeholder-managed. The image push creates shareable Hub /
Scout evidence without exposing the real PAT inside the VM.

The local sandbox proves the agent can use the DHI policy. The pushed
tags make the result shareable. Open the Hub tags page and point at the
baseline and DHI tags:

```text
https://hub.docker.com/repository/docker/$$dockerUsername$$/todo-demo-application/tags
```

Use these two tags for comparison:

```text
docker.io/$$dockerUsername$$/todo-demo-application:sbx-dhi-baseline
docker.io/$$dockerUsername$$/todo-demo-application:sbx-dhi-dhi
```

On Hub, show the tag size difference. Then open the Docker Scout image
view:

```text
https://scout.docker.com/reports/org/$$dockerUsername$$/images/host/hub.docker.com/repo/$$dockerUsername$$%2Ftodo-demo-application
```

In Scout, select `sbx-dhi-baseline` and `sbx-dhi-dhi`, then click
Compare. Use the comparison to show how a minimal DHI runtime changes
image size, package count, and vulnerability findings.

Talking point: do not make this section about in-sandbox Scout CLI
auth. The demo value is that the same prompt plus a different kit stack
produces a DHI-based image, and the pushed tags give a shareable Hub /
Scout view for size, packages, and vulnerabilities.

The `No outdated base images` and `No unapproved base images` cards are
generic base-image policies. If they show `No data` for the DHI tag, do
not present that as a DHI failure. For DHI child images, the important
build flags are `--sbom=true` and `--provenance=mode=max`; Scout uses
max-mode provenance to trace DHI base-image lineage and apply DHI VEX
statements. Then use the DHI-specific evidence, package count, size, and
vulnerability comparison as the demo evidence.

Clean up when finished:

```bash
sbx rm -f p1-yolo p2-best-practices p2-vscode p4-dhi
cd ~/.labspace/project
./scripts/reset-demo.sh
```

The reset script removes generated files such as the agent-created
`Dockerfile` by restoring `demo/sample-app` to its initial nested Git
commit. The checked-in `Dockerfile.baseline` and `Dockerfile.dhi` stay
available for the deterministic Hub / Scout evidence pushes. The
Labspace teardown script also runs this cleanup when the lab is stopped.

## Where This Leads: AI Governance

Use this as the closing turn if the audience asks, "What happens when a
team actually adopts agents?"

```text
https://www.docker.com/products/ai-governance/
```

Talking point: Docker Sandboxes give the infrastructure isolation: the
agent gets a real shell, Docker daemon, filesystem, and network, but
inside a disposable sandbox. Kits make that setup repeatable and
shareable. The next layer is organization governance: centralized
policies for what agents can reach, which filesystem mounts they get,
which MCP servers and tools are approved, and what audit trail exists
for security teams.

The handoff line: "Today we showed the developer workflow. The same
boundary needs to become an organization control plane: access rules,
monitoring, audit, and MCP governance. That is the direction Docker is
building toward with Docker AI Governance."
