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

Talking point: kits make sandboxes repeatable and shareable. One
`spec.yaml` gives an agent the tools, credentials, network rules, files,
startup commands, and guidance it needs to do real work the same way
every time.

```bash
sbx kit inspect ./kits/container-best-practices
```

Talking point: this shows what SBX attaches to the sandbox. The kit is
declarative configuration applied with `--kit`; it is not a custom
Docker image and it is not a long setup prompt pasted into Claude. Kits
are currently an Early Access / experimental feature.

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

Point attention to the skill rules: this is the repeatable agent
behavior the kit ships to every sandbox. For an individual developer,
that means saving setup once. For a team, it means every engineer gets
the same agent environment. For a platform team, it means one reviewed
boundary for tools, network, and credentials.

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
The important part is that the sandbox got the same tool and the same
agent guidance from a reusable kit. That setup can be shared locally,
stored in Git, packaged as an OCI artifact, or owned by a platform team.

The lesson: a kit is reusable, versioned guidance. It gives every agent
the same baseline without rebuilding the agent image or rewriting prompts
by hand.

## Optional: Show VS Code in the Sandbox

If you want a more visual kit moment, stack the contributed
`code-server` kit with the best-practices kit. This starts web VS Code
inside the sandbox, opened on the same workspace Claude is using.

Use this as an optional branch of the demo, not the main path. The first
run downloads code-server and the Claude Code VS Code extension, so
pre-warm it before a live audience if you want to show it.

First stop the previous Claude session with `Ctrl+C` twice, then remove
the sandbox name if it already exists:

```bash
sbx rm -f p2-vscode
```

Create the sandbox with both kits:

```bash
cd ~/.labspace/project/demo/sample-app
```

```bash
sbx run --name p2-vscode claude \
  --kit ../../kits/container-best-practices \
  --kit "git+https://github.com/docker/sbx-kits-contrib.git#dir=code-server"
```

In another terminal tab, publish the editor port:

```bash
sbx ports p2-vscode --publish 18081:8080/tcp
```

Open the browser. Use the IPv4 loopback address explicitly:

```bash
open http://127.0.0.1:18081/
```

If the page does not load, check the sandbox-side service log:

```bash
sbx exec p2-vscode -- cat /tmp/code-server.log
```

Talking point: this is still the same sandbox boundary. VS Code runs
inside the sandbox and is exposed only through an explicit localhost
port publish. The kit added a background service, startup command, and
editor configuration without rebuilding the underlying Claude sandbox
template.

## Where the Kit Ecosystem Goes

Use this if people ask whether kits are only a local demo artifact.
They are not. The docs show kits loading from local directories, Git
repositories, and OCI registries, and the Docker-maintained contrib repo
is the place to explore and contribute reusable kits:

```text
https://docs.docker.com/ai/sandboxes/customize/kits/
https://github.com/docker/sbx-kits-contrib
```

Talking point: this is the shareability story. A team can keep its kit
in Git, pin it by branch, tag, or commit, and use it the same way across
agents. The `code-server` kit we just used came from that ecosystem:

```bash
sbx run claude --kit "git+https://github.com/docker/sbx-kits-contrib.git#dir=code-server"
```

What to say: individual developers save their setup once; teams share a
known-good setup; platform teams publish the approved tools, network
rules, startup services, and credential patterns. Vendors can package
their own agent or integration as a kit instead of writing long install
instructions.
