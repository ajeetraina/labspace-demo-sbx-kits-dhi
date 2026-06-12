# Start with a Plain Sandbox

First, let the agent containerize a small Node service in an isolated
microVM sandbox with no kit attached.

## Learning objectives
 
In this section, you will complete the following objectives:
 
- Run an AI coding agent inside an isolated Docker Sandbox microVM with no kit attached
- Observe the sandbox's network policy allowing approved endpoints while denying others
- Inspect the agent's unguided Dockerfile and image to see the quality bar it chose on its own
- Publish the baseline image tag for later comparison

## Run the baseline sandbox

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
agent starts from a clean app with no Dockerfile at all (only the app
sources remain). A sandbox is keyed to its workspace directory and agent,
not to its `--name`, so only one can own this directory at a time — the
reset clears them all:

```bash
cd ~/.labspace/project && ./scripts/reset-demo.sh
```

## Authenticate the agent (Anthropic)

The `claude` agent runs inside the sandbox microVM and authenticates to the
Anthropic API through the SBX proxy using the `anthropic` **service secret**.
This is separate from the Docker registry secrets you set in Step 0. If it is
not set, the agent starts but fails the first prompt with
`Invalid API key · Fix external API key`.

Register your Anthropic API key once on the host (global, so every sandbox in
this lab can use it). The real key stays on the host; the proxy injects auth on
outbound requests and it never enters the VM:

```bash
sbx secret set -g anthropic
```

> [!NOTE]
> Prefer not to type the key interactively? Use the non-interactive form
> instead: `echo "$ANTHROPIC_API_KEY" | sbx secret set -g anthropic`.

Confirm the secret is now populated (the `anthropic` row should no longer be
empty):

```bash
sbx secret ls
```

> [!IMPORTANT]
> A sandbox only picks up secrets that exist when it is created. If you already
> created `p1-yolo` before setting this, remove it and let the next step
> recreate it: `sbx rm -f p1-yolo`.

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

## Show network policy

With the Claude sandbox session still open, use the run button to send
short shell escapes into that same sandbox. Development endpoints needed
by the sandbox can work, while unapproved destinations are denied:

```bash
! curl -fsS --max-time 8 https://api.github.com/rate_limit >/dev/null && echo "github api: allowed"
```

```bash
! curl -fsS --max-time 8 https://example.com
```

> [!NOTE]
> The `example.com` request should fail.


Open another terminal tab with
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

**Talking point:** Docker Sandboxes are isolated microVM sandboxes, not just
containers. Each sandbox has a network policy boundary you can inspect
and audit. We will use credentials later in the DHI step; this first
section is only about isolation and network control.

# Inspect the unguided output

This first pass is intentionally unconstrained. Use these checks to see
the quality bar the model chose by itself.

Inspect the Dockerfile:

```bash
! grep -nE "^[[:space:]]*FROM[[:space:]]" Dockerfile
```

**Talking point:** every `FROM` line is a build stage. One line means a
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

**Talking point:** a default sandbox template ships a base environment, not
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

**The lesson:** Docker Sandboxes give the agent a real shell and its own
Docker daemon inside an isolated microVM. The safety boundary is strong,
but the output quality is still whatever the model decides without
guidance.


## Publish the Baseline Tag

Use this only after the agent has finished the baseline pass. It pushes
the image the agent just built (from the `Dockerfile` it wrote) as the
baseline comparison tag, under the Docker namespace from Step 0:

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
  -f Dockerfile \
  -t "${IMAGE}:sbx-dhi-baseline" .
SCRIPT
```

> [!TIP]
> This tag stays on Docker Hub. If you are re-running the demo for a new
> audience, you do not have to push it again every time — you can skip
> ahead and open a comparison you pushed earlier.
 
> [!IMPORTANT]
> This still does not put the real PAT in the sandbox VM. The Docker
> config contains the fake auth placeholder from Step 0; SBX replaces it
> through the host-side proxy when the registry request leaves the sandbox.
