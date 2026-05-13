# sbx-kits-demo — a 10-minute LeadDev sandbox demo

Four phases. Each one earns its place by adding **one** capability the
previous one didn't have.

| # | Phase                              | What's new                                  | Time   |
|---|------------------------------------|---------------------------------------------|--------|
| 1 | Claude in sbx (yolo)               | Isolation                                   | 0–2:00 |
| 2 | + `container-best-practices` kit   | Generic guardrails (every Dockerfile, ever) | 2–4:30 |
| 3 | Parallel agents in worktrees       | Throughput                                  | 4:30–7 |
| 4 | + `dhi-scout` kit                  | Custom policy gate, locally, before CI      | 7–10   |

## Layout

```
sbx-kits-demo/
├── README.md                                  ← you are here
├── kits/
│   ├── container-best-practices/              ← mixin: generic Dockerfile rules + hadolint
│   │   ├── spec.yaml
│   │   └── files/home/.claude/skills/container-best-practices/SKILL.md
│   └── dhi-scout/                             ← mixin: DHI bases + docker scout policy gate
│       ├── spec.yaml
│       └── files/home/.claude/skills/dhi-scout/SKILL.md
└── demo/
    └── sample-app/                            ← tiny Node service, git-initialised
        ├── package.json
        ├── index.js
        └── .gitignore
```

The two kits are validated locally:

```
sbx kit validate ./kits/container-best-practices
sbx kit validate ./kits/dhi-scout
```

## Pre-flight (do before going on stage)

```sh
# 1. Make sure sbx is logged in.
sbx login

# 2. Pre-pull the claude template so on-stage create is fast.
sbx create --name prewarm claude /tmp && sbx rm -f prewarm

# 3. Validate kits.
sbx kit validate ./kits/container-best-practices
sbx kit validate ./kits/dhi-scout

# 4. cd into the sample app and initialise it as a git repo
#    (phase 3's --branch flag creates worktrees, so the sample app
#    must be a git repo).
cd demo/sample-app
git init -q -b main
git add .
git -c user.email=demo@example.com -c user.name=demo commit -q -m "init: leaddev sample app"
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

Inside Claude, prompt:

> Containerize this app. Build the image and run it.

Watch what happens. Likely outcomes (this is the point):

- Picks `node:latest` or `node:20`.
- Single-stage build.
- Runs as root.
- No `.dockerignore`.
- `docker build` works, image is 200–400 MB.

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

- Pinned base image (`node:20.11-alpine` or DHI-equivalent).
- Multi-stage build.
- Non-root `USER`.
- A `.dockerignore`.
- A run of `hadolint Dockerfile` and any warnings fixed.
- Final image around 50–80 MB.

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

## Phase 4 — Add `dhi-scout` kit: custom policy, before CI (7:00 – 10:00)

**Talk track:** "Generic best practices are nice. But every org has
its *own* policy: which base images are allowed, which CVE budget is
acceptable, which licenses are forbidden. CI enforces this — but
catching it in CI means the loop is minutes long. With a kit, we
push that policy onto the agent's laptop."

Show the second kit:

```sh
sbx kit inspect ./kits/dhi-scout
sed -n '1,60p' ./kits/dhi-scout/files/home/.claude/skills/dhi-scout/SKILL.md
```

Two things in this kit:

1. **`docker scout` CLI** installed system-wide in the sandbox.
2. **Skill** instructing Claude to (a) swap any base image to a
   `docker.io/dhi/...` Docker Hardened Image and (b) run
   `docker scout cves` + `docker scout policy` after every build,
   blocking "done" if policy fails.

Stack both kits on a fresh sandbox:

```sh
sbx run --name p4-policy claude \
  --kit ../../kits/container-best-practices \
  --kit ../../kits/dhi-scout
```

Prompt:

> Harden the image and confirm it's shippable under our Scout policy.

Expected behaviour:

1. Claude rewrites the Dockerfile's `FROM` lines to `docker.io/dhi/node:...`.
2. `docker build -t app:dev .`
3. `docker scout quickview app:dev`
4. `docker scout cves --only-severity critical,high app:dev`
5. `docker scout policy app:dev`
6. Reports the structured block from the skill:
   ```
   Image:        app:dev (sha256:...)
   Base:         docker.io/dhi/node:20
   Size:         34 MB
   Scout policy: PASS
   CVEs:         critical=0 high=0
   Next action:  push
   ```

If policy fails, Claude iterates — bumps the base, drops a transitive
dep, and re-runs scout. The skill explicitly forbids "Next action:
push" when policy is red.

**Land the message:** the kit is the *unit of policy*. Authors of
the policy don't have to teach it to every developer — they ship a
kit, devs `--kit` it, and the agent does the right thing on every
laptop, before any code reaches CI.

---

## Cleanup

```sh
sbx ls
sbx rm -f p1-yolo p2-best-practices p3-claude p3-opencode p4-policy
# worktrees can stick around; remove with: git worktree remove <path>
```

## What to take home

- **Sandbox** = isolation + a real Docker daemon. Yolo mode is safe.
- **Kit** = *declarative*, *composable* policy. One file in git, one
  flag at create time, every agent picks it up.
- **Mix-and-match**: generic kits (best practices, lint, formatting)
  next to org-specific kits (DHI, Scout policy, internal registries).
- **Parallel** = `--branch`. Cost is `O(agents)`; conflict cost is
  zero because every agent gets its own worktree.
- **Shift policy left**: the same checks CI runs, the agent runs
  first — locally, in the sandbox, before push.

## Files to read on stage if you have time

- `kits/container-best-practices/spec.yaml` — minimal mixin: one
  `install` command, one file drop.
- `kits/dhi-scout/files/home/.claude/skills/dhi-scout/SKILL.md` — the
  policy expressed as plain English; this is the lever.

## Smoke test (verifies the kits actually work)

```sh
# Build a throwaway sandbox with both kits, exec in, check the tools.
sbx create --name kits-smoke claude ./demo/sample-app \
  --kit ./kits/container-best-practices \
  --kit ./kits/dhi-scout

sbx exec kits-smoke bash -lc '
  hadolint --version &&
  docker scout version | sed -n "/^version:/p" &&
  ls ~/.claude/skills/ &&
  ls "$WORKSPACE_DIR"
'

sbx rm -f kits-smoke
```

Expected: hadolint version, scout banner, `container-best-practices`
and `dhi-scout` directories, the sample-app files in the workspace.
