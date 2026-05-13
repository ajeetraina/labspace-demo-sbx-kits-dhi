# Step 0: Prerequisites

This Labspace uses a host-backed terminal so `sbx` can create real sandboxes from your machine.

Confirm Docker and SBX are available:

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
cd ~/.labspace/project
sbx kit validate ./kits/container-best-practices
sbx kit validate ./kits/dhi-scout
```

Optional: pre-pull the Claude sandbox template so the first demo command starts faster:

```bash
sbx create --name prewarm claude /tmp && sbx rm -f prewarm
```
