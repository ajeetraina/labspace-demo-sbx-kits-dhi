# Start with a Plain Sandbox

First, let the agent containerize a small Node service in an isolated
microVM sandbox with no kit attached.

Open the sample app:

```bash
cd ~/.labspace/project/demo/sample-app
```

```bash
cat package.json
```

```bash
cat src/server.ts
```

```bash
cat src/app.ts
```

Reset the workspace before starting. This removes any leftover demo
sandboxes and the agent-generated `Dockerfile` from a previous run, so the
agent starts from a clean app every time (the sample sources and the
checked-in `Dockerfile.baseline` / `Dockerfile.dhi` are left intact). A
sandbox is keyed to its workspace directory and agent, not to its
`--name`, so only one can own this directory at a time — the reset clears
them all:

```bash
cd ~/.labspace/project && ./scripts/reset-demo.sh
```

Run the baseline sandbox:

```bash
sbx run --name p1-yolo claude
```

When Claude opens, use the run button on this block to paste the prompt
into that Claude session:

```bash
Containerize this app. Build the image and run it.
```

The sandbox gives the agent real tools, but inside its own Docker daemon,
filesystem, and network. The agent can build, run, and test containers
without touching your host system.

## Show Network Policy

With the Claude sandbox session still open, use the run button to send
short shell escapes into that same sandbox. Development endpoints needed
by the sandbox can work, while unapproved destinations are denied:

```bash
! curl -fsS --max-time 8 https://api.github.com/rate_limit >/dev/null && echo "github api: allowed"
```

```bash
! curl -fsS --max-time 8 https://example.com
```

The `example.com` request should fail. Open another terminal tab with
the `+` button and use it to show the SBX control surface:

```bash
sbx
```

Then show the network audit trail for this sandbox:

```bash
sbx policy log p1-yolo --limit 20
```

You can also show the active sandbox list from that tab:

```bash
sbx ls
```

Talking point: Docker Sandboxes are isolated microVM sandboxes, not just
containers. Each sandbox has a network policy boundary you can inspect
and audit. We will use credentials later in the DHI step; this first
section is only about isolation and network control.

## Talking Points

This first pass is intentionally unconstrained. Use these checks to see
the quality bar the model chose by itself.

Inspect the Dockerfile:

```bash
! grep -nE "^[[:space:]]*FROM[[:space:]]" Dockerfile
```

Talking point: every `FROM` line is a build stage. One line means a
single-stage image; two or more lines means the agent chose a
multi-stage build. Also call out whether the base is pinned, `latest`,
slim, alpine, or something else.

```bash
! grep -nE "^[[:space:]]*USER[[:space:]]" Dockerfile || echo "no USER directive"
```

```bash
! test -f .dockerignore && sed -n "1,120p" .dockerignore || echo "missing .dockerignore"
```

Inspect the image the agent built. The agent picks its own tag (often
derived from the `package.json` name), so the next block auto-detects the
most recently built image instead of assuming a fixed name:

```bash
! docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}" | sed -n "1,10p"
```

```bash
! IMAGE=$(docker images --filter "dangling=false" --format "{{.Repository}}:{{.Tag}}" | grep -v '<none>' | grep -v 'todo-demo-application' | head -1); echo "Inspecting ${IMAGE:-<none>}"; docker image inspect "$IMAGE" --format "User={{.Config.User}} Size={{.Size}} Cmd={{json .Config.Cmd}}"
```

Now try a Dockerfile linter:

```bash
! command -v hadolint >/dev/null && hadolint Dockerfile || echo "hadolint is not installed in this sandbox"
```

Talking point: a default sandbox template ships a base environment, not
your team's custom tooling. A linter like `hadolint` simply is not there.
The agent could go install it on its own, but then you are letting an
agent pull arbitrary, unpinned tools off the internet on every run, which
is neither reproducible nor something you want to trust by default. This
is exactly the gap kits close: instead of ad-hoc installs, the
best-practices kit in the next step provisions a curated, version-pinned
toolset (`hadolint` and more) into the sandbox, so the same check runs
the same way every time.

Use those outputs to answer:

- Does it use `latest` or a pinned base image?
- Does it use one stage or multiple stages?
- Does the container run as root?
- Does it create `.dockerignore`?
- Does it lint or verify the Dockerfile?

The lesson: Docker Sandboxes give the agent a real shell and its own
Docker daemon inside an isolated microVM. The safety boundary is strong,
but the output quality is still whatever the model decides without
guidance.

## Publish the Baseline Tag

Use this only after the agent has finished the baseline pass. It pushes a
deterministic baseline image from the checked-in `Dockerfile.baseline`
under the Docker namespace from Step 0:

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

mkdir -p "$HOME/.docker"
cat > "$HOME/.docker/config.json" <<'JSON'
{
  "auths": {
    "https://index.docker.io/v1/": {
      "auth": "c2J4X2RvY2tlcl9odWJfdXNlcjpzYnhfZG9ja2VyX2h1Yl9wYXQK"
    }
  }
}
JSON

docker buildx build --push --platform "$PLATFORM" \
  --sbom=true --provenance=mode=max \
  -f Dockerfile.baseline \
  -t "${IMAGE}:sbx-dhi-baseline" .
SCRIPT
```

Talking point: this still does not put the real PAT in the sandbox VM.
The Docker config contains the fake auth placeholder from Step 0; SBX
replaces it through the host-side proxy when the registry request leaves
the sandbox.
