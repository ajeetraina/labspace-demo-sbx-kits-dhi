# Start with a Plain Sandbox

First, let the agent containerize a small Node service in an isolated sandbox with no kit attached.

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

Run the baseline sandbox:

```bash
sbx run --name p1-yolo claude
```

When Claude opens, use the run button on this block to paste the prompt
into that Claude session:

```bash
Containerize this app. Build the image and run it.
```

The sandbox is isolated, but it still has the real tools it needs to do
the job. The agent can build, run, and test containers without touching
your host Docker context directly.

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

Talking point: SBX is not just "a container". The sandbox has an
auditable network policy boundary. We will use secrets later in the DHI
step; this first section is only about isolation and network control.

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

Inspect the image the agent built. If Claude used a different tag,
change `IMAGE` first:

```bash
! docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}" | sed -n "1,10p"
```

```bash
! docker image inspect sample-app:latest --format "User={{.Config.User}} Size={{.Size}} Cmd={{json .Config.Cmd}}"
```

Optional lint check:

```bash
! command -v hadolint >/dev/null && hadolint Dockerfile || echo "hadolint is not installed in the plain sandbox"
```

Use those outputs to answer:

- Does it use `latest` or a pinned base image?
- Does it use one stage or multiple stages?
- Does the container run as root?
- Does it create `.dockerignore`?
- Does it lint or verify the Dockerfile?

The lesson: SBX gives the agent a real shell and Docker daemon inside an isolated sandbox. The isolation is strong, but the output quality is still whatever the model decides without guidance.
