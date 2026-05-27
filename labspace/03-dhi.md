# Add the DHI Kit

The final step adds organization-specific base image guidance. The
`dhi` kit tells the agent to use Docker Hardened Images for both build
and runtime stages, then collect image evidence that can be shown in
Docker Hub / Docker Scout Dashboard after push.

This step expects the Docker credentials from Step 0. The `dhi` kit
writes Docker auth placeholders into `~/.docker/config.json` for Docker
Hub and `dhi.io`. Step 0 registers host-side SBX custom secrets that
replace those placeholders for registry requests. If you added or
changed those secrets after creating `p4-dhi`, remove and recreate that
sandbox before continuing.

If the best-practices sandbox is still open, press `Ctrl+C` twice: once
to stop Claude, and once more to exit the SBX session.

Remove the previous sandboxes before creating the DHI one. The same
workspace cannot be owned by multiple named sandboxes at once:

```bash
sbx rm -f p2-best-practices p4-dhi kits-smoke
```

Inspect the kit:

```bash
cd ~/.labspace/project
```

Talking point: this kit is a second mixin layered onto the same agent.
The best-practices kit handles generic container quality; the DHI kit
adds organization-specific base image policy and registry access.

```bash
sbx kit inspect ./kits/dhi
```

Point attention to the kit name, display name, and install/startup
steps. This is what SBX applies when `--kit ../../kits/dhi` is added to
the sandbox command.

```bash
cat ./kits/dhi/spec.yaml
```

Point attention to the DHI CLI install, `network.allowedDomains`, and
`configure-dhi-auth`. The important demo message is that the sandbox
gets DHI tooling and placeholder auth config at startup, while the real
Docker credential stays host-managed.

```bash
cat ./kits/dhi/files/home/.claude/skills/dhi/SKILL.md
```

Point attention to the skill rules: use DHI for every build/runtime base
image, use `dhi.io/node:24-debian13-dev` and
`dhi.io/node:24-debian13` for this Node demo, and collect evidence for
Hub / Scout Dashboard review after push.

Talking point: this is intentionally the same user task as before. The
difference is the kit stack. The DHI skill says that, when this kit is
installed, it has base-image precedence for containerization tasks, so
the agent should know about DHI without the user having to spell it out
in the prompt.

Run a fresh sandbox with both kits:

```bash
cd ~/.labspace/project/demo/sample-app
sbx run --name p4-dhi claude \
  --kit ../../kits/container-best-practices \
  --kit ../../kits/dhi
```

When Claude opens, use the run button on this block to paste the same
prompt as before into that Claude session:

```text
Containerize this app. Build the image and run it.
```

The expected workflow is:

```bash
docker dhi catalog list --json
docker dhi catalog get node --json
docker build -t app:baseline -f Dockerfile.baseline .
docker build -t app:dhi -f Dockerfile.dhi .
docker image inspect app:baseline app:dhi --format '{{join .RepoTags ","}} {{.Size}} bytes {{.Config.User}}'
```

The kit should use `dhi.io/node:24-debian13-dev` for build stages and
`dhi.io/node:24-debian13` for the final runtime stage in this Node demo.
If the account uses a DHI Select or Enterprise mirror, use the Docker
Hub organization namespace shown by the DHI CLI or your org
configuration.

You can verify that both kit tools were installed in a throwaway sandbox:

```bash
cd ~/.labspace/project
sbx create --name kits-smoke claude ./demo/sample-app \
  --kit ./kits/container-best-practices \
  --kit ./kits/dhi

sbx exec kits-smoke bash -lc '
  test -f ~/.docker/config.json &&
  grep -q "c2J4X2RvY2tlcl9odWJfdXNlcjpzYnhfZG9ja2VyX2h1Yl9wYXQK" ~/.docker/config.json &&
  grep -q "c2J4X2RoaV91c2VyOnNieF9kaGlfcGF0Cg==" ~/.docker/config.json &&
  hadolint --version &&
  dhictl --version &&
  docker dhi --version &&
  ls ~/.claude/skills/ &&
  ls "$WORKSPACE_DIR"
'
```

After Step 0 secrets are configured, you can also test real
authenticated DHI access with an image your account can pull:

```bash
sbx exec kits-smoke bash -lc '
  docker dhi catalog list --json >/tmp/dhi-catalog.json &&
  docker pull dhi.io/node:24-debian13
'
```

If that pull is denied, check whether your DHI access is through a
Docker Hub organization mirror instead of direct `dhi.io` access, then
pull the mirrored image reference shown by `docker dhi`.

For the shareable evidence view, open these after the image tags are
pushed:

```text
https://hub.docker.com/r/olegselajev241/todo-demo-application/tags?name=sbx-dhi
https://scout.docker.com/org/olegselajev241/images/docker.io/olegselajev241/todo-demo-application
```

Known demo tags:

```text
docker.io/olegselajev241/todo-demo-application:sbx-dhi-baseline
docker.io/olegselajev241/todo-demo-application:sbx-dhi-dhi
```

Clean up when finished:

```bash
sbx rm -f prewarm kits-smoke p1-yolo p2-best-practices p4-dhi
```

The Labspace teardown script also removes these demo sandboxes when the
lab is stopped.
