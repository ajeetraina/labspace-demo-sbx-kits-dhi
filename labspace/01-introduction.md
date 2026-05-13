# Start with a Plain Sandbox

This lab follows the SBX kits demo end to end. You will first let an agent containerize a small Node service in an isolated sandbox with no kit, then repeat the task with stronger kit-provided guidance.

Confirm the host-backed terminal has the tools this lab needs:

```bash
docker version
sbx version
```

Check SBX authentication:

```bash
sbx diagnose
```

If authentication fails, sign in:

```bash
sbx login
```

Validate the two kits packaged with the lab:

```bash
sbx kit validate ./kits/container-best-practices
sbx kit validate ./kits/dhi-scout
```

Prepare the sample app as a Git repository. The worktree section later depends on this:

```bash
cd ~/.labspace/project/demo/sample-app
git init -q -b main
git add .
git -c user.email=demo@example.com -c user.name=demo commit -q -m "init: leaddev sample app"
```

Run the baseline sandbox without any kit:

```bash
sbx run --name p1-yolo claude
```

When Claude opens, ask:

```text
Containerize this app. Build the image and run it.
```

This first pass is intentionally unconstrained. Look for the quality bar the model chooses by itself: base image choice, whether it runs as root, whether it creates `.dockerignore`, and whether it lint-checks the Dockerfile.
