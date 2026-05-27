# Start with a Plain Sandbox

First, let the agent containerize a small Node service in an isolated sandbox with no kit attached.

Open the sample app:

```bash
cd ~/.labspace/project/demo/sample-app
sed -n '1,120p' package.json
sed -n '1,120p' src/server.ts
sed -n '1,160p' src/app.ts
```

Run the baseline sandbox:

```bash
sbx run --name p1-yolo claude
```

When Claude opens, ask:

```text
Containerize this app. Build the image and run it.
```

The sandbox is isolated, but it still has the real tools it needs to do
the job. The agent can build, run, and test containers without touching
your host Docker context directly.

## Show Network Policy

With the Claude sandbox session still open, use the run button to send
short shell escapes into that same sandbox. Development endpoints needed
by the sandbox can work, while unapproved destinations are denied:

```text
! curl -fsS --max-time 8 https://api.github.com/rate_limit >/dev/null && echo "github api: allowed"
```

```text
! curl -fsS --max-time 8 https://example.com
```

The `example.com` request should fail. In a second terminal tab, or
after exiting Claude, show the audit trail:

```bash
sbx policy log p1-yolo --limit 20
```

Talking point: SBX is not just "a container". The sandbox has an
auditable network policy boundary. We will use secrets later in the DHI
step; this first section is only about isolation and network control.

## Talking Points

This first pass is intentionally unconstrained. Use these checks to see
the quality bar the model chose by itself.

Inspect the Dockerfile:

```text
! grep -nE "^[[:space:]]*FROM[[:space:]]" Dockerfile
```

```text
! grep -cE "^[[:space:]]*FROM[[:space:]]" Dockerfile
```

```text
! grep -nE "^[[:space:]]*USER[[:space:]]" Dockerfile || echo "no USER directive"
```

```text
! test -f .dockerignore && sed -n "1,120p" .dockerignore || echo "missing .dockerignore"
```

Inspect the image the agent built. If Claude used a different tag,
change `IMAGE` first:

```text
! docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}" | sed -n "1,10p"
```

```text
! docker image inspect sample-app:latest --format "User={{.Config.User}} Size={{.Size}} Cmd={{json .Config.Cmd}}"
```

Optional lint check:

```text
! command -v hadolint >/dev/null && hadolint Dockerfile || echo "hadolint is not installed in the plain sandbox"
```

Use those outputs to answer:

- Does it use `latest` or a pinned base image?
- Does it use one stage or multiple stages?
- Does the container run as root?
- Does it create `.dockerignore`?
- Does it lint or verify the Dockerfile?

The lesson: SBX gives the agent a real shell and Docker daemon inside an isolated sandbox. The isolation is strong, but the output quality is still whatever the model decides without guidance.
