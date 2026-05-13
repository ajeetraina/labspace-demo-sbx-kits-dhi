# Setup the SBX Demo

This lab uses a host-backed terminal so `sbx` can create real sandboxes from inside the Labspace.

First confirm the required tools are available:

```bash
docker version
sbx version
```

Initialize the sample app repository and validate both kits:

```bash
./setup.sh
```

Sign in to SBX if needed:

```bash
sbx login
```

Pre-pull the Claude sandbox template so the live demo starts quickly:

```bash
sbx create --name prewarm claude /tmp && sbx rm -f prewarm
```

The demo project is in `demo/sample-app`, and the reusable SBX kits are in `kits/`.
