# Add the Best Practices Kit

Now run the same task with a generic container best-practices kit attached.

If the plain sandbox is still open, press `Ctrl+C` twice: once to stop
Claude, and once more to exit the SBX session.

Remove the first sandbox before creating the kit-guided one. The same
workspace cannot be owned by two named sandboxes at once:

```bash
sbx rm -f p1-yolo p2-best-practices
```

Inspect the kit:

```bash
cd ~/.labspace/project
```

Talking point: kits package sandbox capabilities in one `spec.yaml`:
tools to install, environment variables, credentials, network rules,
files, startup commands, and agent guidance. That makes an agent setup
repeatable and shareable.

```bash
sbx kit inspect ./kits/container-best-practices
```

Talking point: this shows what SBX applies and enforces at sandbox
runtime. Kits are declarative configuration applied with `--kit`; they
are not custom Docker images and not long setup prompts pasted into
Claude. Kits are currently an Early Access / experimental feature.

```bash
cat ./kits/container-best-practices/spec.yaml
```

Point attention to `commands.install`: the kit adds tools at sandbox
creation. Point at `network.allowedDomains`: the kit also defines what
this agent setup can reach. Later, the DHI kit uses proxy-managed
credentials, where the real secret stays on the host and the sandbox
only sees placeholders.

```bash
cat ./kits/container-best-practices/files/home/.claude/skills/container-best-practices/SKILL.md
```

Point attention to the skill rules: this is one of the files the kit
drops into the sandbox to guide agent behavior. For an individual
developer, the setup is saved once. For a team, every engineer gets the
same environment. For a platform team, tools, network, and credentials
are standardized in one reviewed artifact.

Start a fresh sandbox with the kit:

```bash
cd ~/.labspace/project/demo/sample-app
```

```bash
sbx run --name p2-best-practices claude --kit ../../kits/container-best-practices
```

When Claude opens, use the run button on this block to paste the same
prompt into that Claude session:

```bash
Containerize this app. Build the image and run it.
```

Talking point: call out the first lines of Claude output. You should
see `Skill(container-best-practices)` and `Successfully loaded skill`.
That is the visible handoff from the kit into the agent's behavior.

## Show the Kit in Action

You may not need extra commands here. The strongest proof is often in
Claude's own transcript:

- It loads `Skill(container-best-practices)`.
- It reads the shared skill that the kit installed.
- It changes its plan based on that shared guidance.
- It uses the tool the kit installed, for example `hadolint Dockerfile`.

If you want one quick live check after Claude finishes, use this:

```bash
! hadolint Dockerfile
```

Talking point: the important part is not the specific Dockerfile advice.
The important part is that the sandbox got the same capabilities from a
reusable kit. That setup can be shared locally, stored in Git, packaged
as an OCI artifact, or owned by a platform team.

The lesson: a kit is a reusable, versioned sandbox capability bundle. It
gives every agent the same baseline without rebuilding the agent image or
rewriting prompts by hand.
