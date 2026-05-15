# sbx-kits-demo — a 10-minute LeadDev sandbox demo

Three phases. Each one earns its place by adding **one** capability the
previous one didn't have.

| # | Phase                              | What's new                                  | Time    |
|---|------------------------------------|---------------------------------------------|---------|
| 1 | Claude in sbx (yolo)               | Isolation                                   | 0-2:00  |
| 2 | + `container-best-practices` kit   | Generic guardrails (every Dockerfile, ever) | 2-5:00  |
| 3 | + `dhi-scout` kit                  | DHI catalog, DHI bases, Scout policy gate   | 5-10:00 |

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
#    so every sandbox starts from a clean project snapshot.
cd demo/sample-app
git init -q -b main
git add .
git -c user.email=demo@example.com -c user.name=demo commit -q -m "init: leaddev sample app"
```

Optional but recommended: keep one host terminal open for `sbx` commands
and one lab browser pane open for the instructions.

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

## Phase 3 — Add `dhi-scout` kit: DHI catalog and policy before CI (5:00 – 10:00)

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

Four things in this kit:

1. **`docker scout` CLI** installed system-wide in the sandbox.
2. **DHI CLI** installed as both `dhictl` and `docker dhi`.
3. **Docker registry auth placeholders** written to `~/.docker/config.json`;
   Step 0 maps those placeholders to host-side SBX secrets.
4. **Skill** instructing Claude to (a) query the DHI catalog, (b) swap
   any base image to a DHI image, and (c) run
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

1. Claude checks `docker dhi catalog list --json`.
2. Claude rewrites the Dockerfile's `FROM` lines to `dhi.io/node:...`,
   or to your organization's Docker Hub DHI mirror.
3. `docker build -t app:dev .`
4. `docker scout quickview app:dev`
5. `docker scout cves --only-severity critical,high app:dev`
6. `docker scout policy app:dev`
7. Reports the structured block from the skill:
   ```
   Image:        app:dev (sha256:...)
   Base:         dhi.io/node:20
   DHI catalog:  docker dhi catalog get node
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
sbx rm -f p1-yolo p2-best-practices p4-policy kits-smoke
```

## What to take home

- **Sandbox** = isolation + a real Docker daemon. Yolo mode is safe.
- **Kit** = *declarative*, *composable* policy. One file in git, one
  flag at create time, every agent picks it up.
- **Mix-and-match**: generic kits (best practices, lint, formatting)
  next to org-specific kits (DHI, Scout policy, internal registries).
- **Shift policy left**: the same checks CI runs, the agent runs
  first - locally, in the sandbox, before push.

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
  test -f ~/.docker/config.json &&
  dhictl --version &&
  docker dhi --version &&
  hadolint --version &&
  docker scout version | sed -n "/^version:/p" &&
  ls ~/.claude/skills/ &&
  ls "$WORKSPACE_DIR"
'

sbx rm -f kits-smoke
```

Expected: DHI CLI version, hadolint version, scout banner,
`container-best-practices` and `dhi-scout` directories, the sample-app
files in the workspace.
