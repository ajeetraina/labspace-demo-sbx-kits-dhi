# Add the Best Practices Kit

Now run the same task with a generic container best-practices kit attached.

If the plain sandbox is still open, press `Ctrl+C` twice: once to stop
Claude, and once more to exit the SBX session.

Inspect the kit:

```bash
cd ~/.labspace/project
```

Talking point: kits make sandboxes repeatable and shareable. One YAML
file gives an agent the tools, credentials, network rules, and config it
needs to do real work the same way every time.

```bash
sbx kit inspect ./kits/container-best-practices
```

Talking point: this shows what SBX will attach to the sandbox. The kit
is declarative startup configuration, applied with `--kit`; it is not a
custom Docker image and it is not a long setup prompt pasted into
Claude.

```bash
cat ./kits/container-best-practices/spec.yaml
```

Point attention to `commands.install`: the kit adds tools without
rebuilding the agent image. Point at `network.allowedDomains`: the kit
also defines what this agent setup can reach. Later, the DHI kit uses
the same mechanism for credentials, where the real secret stays on the
host and the sandbox only sees placeholders.

```bash
cat ./kits/container-best-practices/files/home/.claude/skills/container-best-practices/SKILL.md
```

Point attention to the skill rules: this is the repeatable agent
behavior the kit ships to every sandbox. For an individual developer,
that means saving setup once. For a team, it means every engineer gets
the same agent environment. For a platform team, it means one boundary
for tools, network, and credentials. For a vendor or tool builder, it is
the packaging format for an agent or capability.

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
