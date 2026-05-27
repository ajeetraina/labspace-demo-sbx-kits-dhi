# Add the Best Practices Kit

Now run the same task with a generic container best-practices kit attached.

If the plain sandbox is still open, press `Ctrl+C` twice: once to stop
Claude, and once more to exit the SBX session.

Inspect the kit:

```bash
cd ~/.labspace/project
```

Talking point: kits are just files in the project. They can be reviewed,
versioned, and shared like any other repo artifact.

```bash
sbx kit inspect ./kits/container-best-practices
```

Talking point: this shows the kit metadata and what SBX will attach to
the sandbox. It is not a prompt pasted into Claude; it is a declarative
bundle applied at sandbox creation.

```bash
cat ./kits/container-best-practices/spec.yaml
```

Point attention to `commands.install`: the kit installs `hadolint`
inside the sandbox. Also point at `network.allowedDomains`: the kit only
opens the network locations needed to fetch that tool.

```bash
cat ./kits/container-best-practices/files/home/.claude/skills/container-best-practices/SKILL.md
```

Point attention to the skill rules: pinned base images, multi-stage
builds, non-root runtime users, `.dockerignore`, and `hadolint` before
declaring the work done.

Start a fresh sandbox with the kit:

```bash
cd ~/.labspace/project/demo/sample-app
```

```bash
sbx run --name p2-best-practices claude --kit ../../kits/container-best-practices
```

When Claude opens, use the run button on this block to paste the same
prompt into that Claude session:

```text
Containerize this app. Build the image and run it.
```

Compare the result with the plain sandbox. The kit should push the agent toward:

- A pinned base image instead of `latest`
- A multi-stage Dockerfile
- A non-root runtime user
- A `.dockerignore`
- `hadolint Dockerfile` before completion

## Show the Kit in Action

Use the run button in the Claude session after it finishes. These are
the same checks as the plain sandbox, so the difference is easy to see.

```text
! grep -nE "^[[:space:]]*FROM[[:space:]]" Dockerfile
```

Talking point: every `FROM` line is a build stage. The skill tells the
agent to use separate build and runtime stages, and to avoid `latest`.

```text
! grep -nE "^[[:space:]]*USER[[:space:]]" Dockerfile || echo "no USER directive"
```

Talking point: this is the visible non-root check. A good kit-guided
result should switch away from root before `CMD`.

```text
! test -f .dockerignore && cat .dockerignore || echo "missing .dockerignore"
```

Talking point: `.dockerignore` is both performance and safety: smaller
build context, fewer accidental secrets or local artifacts copied into
the image.

```text
! hadolint Dockerfile
```

Talking point: this is the clearest proof the kit changed the sandbox.
The plain sandbox did not have `hadolint`; this one does, and the skill
tells the agent to run it before completion.

```text
! docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}" | sed -n "1,10p"
```

```text
! docker image inspect sample-app:latest --format "User={{.Config.User}} Size={{.Size}} Cmd={{json .Config.Cmd}}"
```

Talking point: compare size, configured user, and command with the
plain sandbox. The win is not that the agent can build an image; it is
that the default quality bar moved without changing the natural-language
task.

The lesson: a kit is reusable, versioned guidance. It gives every agent the same baseline without rewriting prompts by hand.
