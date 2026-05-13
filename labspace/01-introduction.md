# Prerequisites

This lab uses a host-backed terminal so `sbx` can create real sandboxes from inside the Labspace.

Confirm the required tools are available:

```bash
docker version
sbx version
```

Validate both kits before creating sandboxes:

```bash
sbx kit validate ./kits/container-best-practices
sbx kit validate ./kits/dhi-scout
```

Check whether SBX is signed in:

```bash
sbx diagnose
```

If the authentication check fails, sign in:

```bash
sbx login
```

Initialize the sample app as a Git repository. Phase 3 uses `sbx --branch`, which creates Git worktrees and therefore requires the workspace to be a Git repo.

```bash
cd demo/sample-app
git init -q -b main
git add .
git -c user.email=demo@example.com -c user.name=demo commit -q -m "init: leaddev sample app"
cd ../..
```

Pre-pull the Claude sandbox template so the live demo starts quickly:

```bash
sbx create --name prewarm claude /tmp && sbx rm -f prewarm
```

The demo project is in `demo/sample-app`, and the reusable SBX kits are in `kits/`.
