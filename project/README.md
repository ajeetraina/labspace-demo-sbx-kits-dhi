# SBX Kits + DHI — a 10-minute LeadDev sandbox demo

Four phases. Each one earns its place by adding **one** capability the
previous one didn't have.

| # | Phase                              | What's new                                  | Time   |
|---|------------------------------------|---------------------------------------------|--------|
| 1 | Claude in sbx (yolo)               | Isolation                                   | 0–2:00 |
| 2 | + `container-best-practices` kit   | Generic guardrails (every Dockerfile, ever) | 2–4:30 |
| 3 | Parallel agents in worktrees       | Throughput                                  | 4:30–7 |
| 4 | + DHI kit + Hub Scout view         | Org-specific policy and evidence after push | 7–10   |

## Demo spine

The story is not "Claude writes a Dockerfile". The story is:

1. **Isolation:** give an agent a real shell, network, and Docker
   daemon, but keep the blast radius inside an sbx sandbox.
2. **Policy as code:** attach a kit and the agent inherits tools,
   files, skills, and network policy without a long prompt.
3. **Secrets stay host-managed:** registry credentials are configured
   through sbx, not pasted into the agent prompt.
4. **Parallelism:** run multiple agents in isolated worktrees and keep
   the useful branches.
5. **Shareable evidence:** when the discussion turns to DHI, show the
   pushed Hub tags and Scout comparison instead of spending stage time
   debugging auth.

## Layout

```
project/
├── README.md                                  ← you are here
├── scripts/
│   ├── preflight.sh                           ← validate + warm up before the demo
│   ├── smoke.sh                               ← one-command kit smoke test
│   ├── dhi-auth.sh                            ← optional DHI registry auth
│   └── dhi-compare.sh                         ← optional DOI vs DHI comparison
├── kits/
│   ├── container-best-practices/              ← mixin: generic Dockerfile rules + hadolint
│   │   ├── spec.yaml
│   │   └── files/home/.claude/skills/container-best-practices/SKILL.md
│   └── dhi/                                   ← mixin: DHI bases + auth placeholders
│       ├── spec.yaml
│       └── files/home/.claude/skills/dhi/SKILL.md
└── demo/
    └── sample-app/                            ← TypeScript Node app; preflight makes it a git repo
        ├── Dockerfile.baseline
        ├── Dockerfile.dhi
        ├── .dockerignore
        ├── package.json
        ├── package-lock.json
        ├── tsconfig.json
        ├── src/
        │   ├── app.ts
        │   ├── data.ts
        │   └── server.ts
        ├── public/
        │   ├── index.html
        │   ├── styles.css
        │   └── app.js
        └── .gitignore
```

The sample app is deliberately larger than a hello-world server: it has
runtime dependencies, dev/build dependencies, static assets, API routes,
health/readiness endpoints, and Prometheus-style metrics. That makes the
gap between a naive "copy everything into `node:<tag>`" image and a
multi-stage DHI runtime image much easier to see.

When the demo discussion turns toward DHI, use the same image family as
Docker's DHI Node lab so the Scout output is comparable:

- Baseline Docker Official Image: `node:24-trixie-slim`
- DHI build image: `dhi.io/node:24-debian13-dev`
- DHI runtime image: `dhi.io/node:24-debian13`

The DHI angle is optional; this lab is primarily about sandbox kits. If
the discussion goes there inside a sandbox, register PAT-backed SBX
secrets before creating the DHI sandbox so the sandbox can pull Docker
Hub and `dhi.io` images without storing the real pull secret inside the
sandbox:

```sh
./scripts/dhi-auth.sh <docker-username>
```

`dhi-auth.sh` prompts for a Docker password/PAT and registers host-side
SBX custom secrets. The `dhi` kit writes fake Docker auth
placeholders into the sandbox's `~/.docker/config.json`; SBX replaces
those placeholders at the proxy boundary for Docker Hub token requests
and `dhi.io` registry requests. The real credential is not written into
the sandbox.

Equivalent manual setup:

```sh
DOCKER_HUB_USER=<docker-username>
DOCKER_HUB_PASSWORD=<docker-password-or-pat>

sbx secret set-custom -g --host auth.docker.io --env DOCKER_HUB_CREDS \
  --placeholder "c2J4X2RvY2tlcl9odWJfdXNlcjpzYnhfZG9ja2VyX2h1Yl9wYXQK" \
  --value="$(printf '%s:%s' "${DOCKER_HUB_USER}" "${DOCKER_HUB_PASSWORD}" | base64 | tr -d '\n')"

sbx secret set-custom -g --host dhi.io --env DHI_CREDS \
  --placeholder "c2J4X2RoaV91c2VyOnNieF9kaGlfcGF0Cg==" \
  --value="$(printf '%s:%s' "${DOCKER_HUB_USER}" "${DOCKER_HUB_PASSWORD}" | base64 | tr -d '\n')"
```

For a host-only comparison outside SBX, authenticate the host Docker CLI
instead:

```sh
docker login dhi.io
./scripts/dhi-compare.sh
```

`dhi-compare.sh` builds the same app with `node:24-trixie-slim` and with
the DHI dev/runtime pair, then prints local image size evidence. Use the
pushed Hub tags for the shareable Scout Dashboard comparison.

Verified DHI registry checks from a fresh `dhi-kit-test` sandbox:

```sh
docker pull node:24-trixie-slim
docker pull dhi.io/node:24-debian13
docker pull dhi.io/node:24-debian13-dev
```

Those pulls work with the two registry placeholder secrets above.

For the polished DHI evidence view, use Docker Hub / Scout Dashboard
instead of making in-sandbox Scout auth part of the live demo. The
known-good pushed tags are:

```text
docker.io/olegselajev241/todo-demo-application:sbx-dhi-baseline
docker.io/olegselajev241/todo-demo-application:sbx-dhi-dhi
```

Open:

```text
https://hub.docker.com/r/olegselajev241/todo-demo-application/tags?name=sbx-dhi
https://scout.docker.com/org/olegselajev241/images/docker.io/olegselajev241/todo-demo-application
```

Observed Scout comparison:

```text
baseline: node:24-trixie-slim, 104 MB, 323 packages, 0C 0H 3M 22L 3?, policy FAILED
DHI:      dhi.io/node:24-debian13, 43 MB, 96 packages, 0C 0H 0M 8L, policy SUCCESS
delta:    -61 MB, -227 packages, -20 vulnerabilities, default non-root policy improved
```

The two kits are validated locally:

```
sbx kit validate ./kits/container-best-practices
sbx kit validate ./kits/dhi
```

## Requirements / tested with

- Docker Desktop running locally.
- `sbx` installed, on `PATH`, and authenticated with `sbx login`.
- For the optional DHI path, Docker Hub credentials registered with
  `./scripts/dhi-auth.sh <docker-username>`, or the equivalent two
  `sbx secret set-custom` commands above. Use credentials that can pull
  DHI images.
- For the preferred DHI evidence path, access to Docker Hub / Scout
  Dashboard for `olegselajev241/todo-demo-application`.
- Tested with:
  ```
  Client Version:  v0.30.0-rc1-105-gb04f9f24 b04f9f2495e666863223677a8e5c521e98fd0d21
  Server Version:  v0.30.0-rc1-105-gb04f9f24 b04f9f2495e666863223677a8e5c521e98fd0d21
  ```
- Network access to GitHub is needed to install `hadolint` and the DHI
  CLI inside the sandbox.
- For the live demo, prefer the already pushed Hub tags above so the
  dashboard is the stable evidence view.
- Verified on Apple Silicon; the kit install scripts also handle
  `x86_64` Linux sandboxes.

## Pre-flight (do before going on stage)

```sh
# 1. Make sure sbx is logged in.
sbx login

# 2. Validate kits, pre-pull the claude template, and ensure the sample
#    app is a clean git repo for phase 3's --branch worktrees.
./scripts/preflight.sh
```

Optional but recommended: open three terminal panes side-by-side. Pane A
for the host shell, panes B and C for the parallel agents in phase 3.

---

## Phase 1 — Claude in sbx, yolo (0:00 – 2:00)

**Talk track:** "We give Claude a real shell, real network, real Docker
daemon — but inside a microVM. We can let it run with full autonomy
because the blast radius is the sandbox, not my laptop."

```sh
# In demo/sample-app
sbx run --name p1-yolo claude
```

If you want to prove the sandbox boundary before prompting Claude, run
from another pane:

```sh
sbx ls
sbx exec p1-yolo bash -lc 'hostname; pwd; docker version --format "docker={{.Server.Version}}"'
```

Keep this short. The point is that the agent gets real tools, but the
process tree, filesystem, and Docker daemon are sandbox-scoped.

Inside Claude, prompt:

> Containerize this app. Build the image and run it.

Watch what happens. Likely outcomes (this is the point):

- Picks `node:latest`, `node:24`, or similar.
- Single-stage build that keeps TypeScript, build tools, and source
  assets in the runtime image. If you steer the discussion toward DHI,
  use `node:24-trixie-slim` as the baseline.
- Runs as root.
- No `.dockerignore`.
- `docker build` works, but the image is much larger than it needs to be.

**Land the message:** great — autonomy and isolation. But the *quality
bar* is whatever Claude felt like today. No guardrails.

Ctrl-C out of Claude. Leave the sandbox; we'll move on.

---

## Phase 2 — Add `container-best-practices` kit (2:00 – 4:30)

**Talk track:** "A kit is a declarative bundle: install commands, files
to drop into the agent's home, network policy. We'll mix in one that
gives every Claude in our org the same Dockerfile guardrails."

Show the kit briefly:

```sh
sbx kit inspect ./kits/container-best-practices
sed -n '1,40p' ./kits/container-best-practices/spec.yaml
sed -n '1,30p' ./kits/container-best-practices/files/home/.claude/skills/container-best-practices/SKILL.md
```

Call out the primitives:

```text
install commands  -> tools such as hadolint
files             -> Claude skill dropped into ~/.claude/skills
network policy    -> allowed domains declared by the kit
```

The skill loads automatically: Claude Code auto-discovers anything
under `~/.claude/skills/<name>/SKILL.md` and uses the frontmatter
`description` to decide when to apply it.

Spin up a fresh sandbox **with the kit attached** (kits only apply on
create, not on existing sandboxes — except via `sbx kit add`):

```sh
sbx run --name p2-best-practices claude --kit ../../kits/container-best-practices
```

Same prompt:

> Containerize this app. Build the image and run it.

Now you should see:

- Pinned base image. For this demo app, prefer `node:24-trixie-slim`
  so an optional DHI comparison lines up with Docker's DHI Node lab.
- Multi-stage build.
- Non-root `USER`.
- A `.dockerignore`.
- A run of `hadolint Dockerfile` and any warnings fixed.
- A smaller final image that contains production dependencies and built
  output, not the whole development workspace.

**Land the message:** generic, but consistent. Every Claude in the
org now produces the same shape of Dockerfile, without anyone hand-
crafting prompts.

---

## Phase 3 — Parallel agents in git worktrees (4:30 – 7:00)

**Talk track:** "One sandbox is good. Two cost nothing extra. The
`--branch` flag spawns each agent in its own git worktree — isolated
branch, isolated working tree, isolated container."

Open two new panes. In each, from `demo/sample-app`:

```sh
# Pane B: Claude tackles a Dockerfile
sbx run --name p3-claude --branch feat/dockerize claude \
  --kit ../../kits/container-best-practices
```

```sh
# Pane C: opencode tackles tests at the same time
sbx run --name p3-opencode --branch feat/tests opencode \
  --kit ../../kits/container-best-practices
```

In pane B prompt:

> Containerize this service end-to-end.

In pane C prompt:

> Add a /healthz integration test using node:test and supertest.

Both run simultaneously, in different worktrees, on different
branches, with the same kit.

While they run, in pane A:

```sh
sbx ls
git worktree list      # the host sees both branches
```

When both finish, in pane A:

```sh
git -C .sbx/p3-claude-worktrees/feat-dockerize log --oneline
git -C .sbx/p3-opencode-worktrees/feat-tests log --oneline
```

> Note: exact worktree path is shown in the `sbx run` output; the
> command above matches the observed `.sbx/<sandbox>-worktrees/<branch>`
> layout, where slashes in branch names are replaced with hyphens.

**Land the message:** throughput goes up linearly with agents, and
because each one is on a branch, you merge what you want and discard
the rest. No "but it worked on my machine" — it didn't even run on
your machine.

---

## Phase 4 — Add DHI kit and show Hub evidence (7:00 – 10:00)

**Talk track:** "Generic best practices are nice. But every org has
its *own* policy: which base images are allowed, which CVE budget is
acceptable, which licenses are forbidden. A kit is where that policy
becomes executable instructions for the agent. The dashboard is where
we show the evidence."

Show the second kit:

```sh
sbx kit inspect ./kits/dhi
sed -n '1,60p' ./kits/dhi/files/home/.claude/skills/dhi/SKILL.md
```

What this kit adds:

1. **DHI CLI** installed as both `dhictl` and `docker dhi`.
2. **Network policy** for GitHub, Docker Hub, and `dhi.io`.
3. **DHI registry auth placeholders** written to `~/.docker/config.json`;
   `scripts/dhi-auth.sh` maps those placeholders to host-side SBX custom
   secrets backed by Docker Hub credentials.
4. **Skill** instructing Claude to swap the base images to the DHI
   Node build/runtime pair and report the resulting image details.

Show the secret boundary, without printing any secret:

```sh
sbx secret ls -g | sed -n '/CUSTOM SECRETS/,$p'
```

The important line is that real values are masked on the host, while
the sandbox only needs enough placeholder/config state to pull the
images.

Stack both kits on a fresh sandbox:

```sh
sbx run --name p4-dhi claude \
  --kit ../../kits/container-best-practices \
  --kit ../../kits/dhi
```

Prompt:

> Harden this app image with Docker Hardened Images. Use the DHI Node
> build and runtime bases, build the image, and report the image size
> and runtime user.

Expected behaviour:

1. Claude inspects the existing Dockerfile or creates one.
2. Claude rewrites the Dockerfile's `FROM` lines to DHI Node images,
   using `dhi.io/node:24-debian13-dev` for the build stage and
   `dhi.io/node:24-debian13` for the runtime stage.
3. `docker build -t app:dev .`
4. `docker image inspect app:dev --format '{{.Size}} {{.Config.User}}'`
5. Reports the structured block from the skill:
   ```
   Image:        app:dev (sha256:...)
   Base:         dhi.io/node:24-debian13
   Size:         <smaller than node:24-trixie-slim baseline>
   Runtime user: 1000
   Next action:  push for Hub/Scout evidence
   ```

Then switch to the already pushed Hub tags. This avoids spending demo
time on auth or repository setup and gives a stable visual result:

```text
https://hub.docker.com/r/olegselajev241/todo-demo-application/tags?name=sbx-dhi
https://scout.docker.com/org/olegselajev241/images/docker.io/olegselajev241/todo-demo-application
```

Talk through the before/after:

```text
baseline: node:24-trixie-slim, 104 MB, 323 packages, 0C 0H 3M 22L 3?, policy FAILED
DHI:      dhi.io/node:24-debian13, 43 MB, 96 packages, 0C 0H 0M 8L, policy SUCCESS
```

If you want to refresh the Hub evidence before the demo, build and push
the two explicit Dockerfiles from inside a sandbox that has DHI pull
auth and Docker Hub push auth:

```sh
IMAGE=olegselajev241/todo-demo-application

docker buildx build --push --platform linux/arm64 \
  --sbom=true --provenance=true \
  -f Dockerfile.baseline \
  -t "$IMAGE:sbx-dhi-baseline" .

docker buildx build --push --platform linux/arm64 \
  --sbom=true --provenance=true \
  -f Dockerfile.dhi \
  -t "$IMAGE:sbx-dhi-dhi" .
```

**Land the message:** the kit is the *unit of policy*. Authors of
the policy don't have to teach it to every developer — they ship a
kit, devs `--kit` it, and the agent does the right thing on every
laptop. Hub/Scout is the shared evidence layer the team can inspect
after the image is pushed.

---

## Cleanup

```sh
sbx ls
sbx rm -f p1-yolo p2-best-practices p3-claude p3-opencode p4-dhi
# worktrees can stick around; remove with: git worktree remove <path>
```

## What to take home

- **Sandbox** = isolation + a real Docker daemon. Yolo mode is safe.
- **Kit** = *declarative*, *composable* policy. One file in git, one
  flag at create time, every agent picks it up.
- **Mix-and-match**: generic kits (best practices, lint, formatting)
  next to org-specific kits (DHI, internal registries, org policy).
- **Parallel** = `--branch`. Cost is `O(agents)`; conflict cost is
  zero because every agent gets its own worktree.
- **Evidence is shareable**: build in an isolated sandbox, push signed
  images with SBOM/provenance, and use Hub/Scout for the visual
  comparison.

## Files to read on stage if you have time

- `kits/container-best-practices/spec.yaml` — minimal mixin: one
  `install` command, one file drop.
- `kits/dhi/files/home/.claude/skills/dhi/SKILL.md` — the
  policy expressed as plain English; this is the lever.

## Smoke test (verifies the kits actually work)

```sh
./scripts/smoke.sh
```

Known-good output shape:

```text
dhictl version v0.0.3
docker dhi version v0.0.3
Haskell Dockerfile Linter 2.12.0
container-best-practices
dhi
package.json
package-lock.json
tsconfig.json
src/app.ts
src/server.ts
public/index.html
```

The script creates a throwaway `kits-smoke` sandbox, checks the tools
and injected Claude skills, prints the mounted sample app files, then
removes the sandbox.
