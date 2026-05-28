# SBX Kits + DHI Demo Project

This directory is the workspace copied into the Labspace terminal. The
rendered lab instructions live in `../labspace/` in the repository and
are the source of truth for the demo flow.

## Contents

```text
project/
├── demo/sample-app/                 # TypeScript Node sample app
│   ├── Dockerfile.baseline          # Deterministic Docker Official Image baseline
│   └── Dockerfile.dhi               # Deterministic Docker Hardened Images version
├── kits/container-best-practices/   # hadolint + container guidance skill
├── kits/dhi/                        # DHI CLI + auth placeholders + DHI skill
└── scripts/                         # optional local helper scripts
```

The live demo should follow the Labspace sections:

1. Start with a plain SBX sandbox.
2. Add the `container-best-practices` kit.
3. Add the `dhi` kit.
4. Push the baseline and DHI comparison tags under the presenter’s Docker
   Hub namespace.
5. Compare the pushed tags in Docker Hub / Docker Scout Dashboard.

## Image Tags

The Labspace asks the presenter for a Docker username and publishes:

```text
docker.io/<docker-username>/todo-demo-application:sbx-dhi-baseline
docker.io/<docker-username>/todo-demo-application:sbx-dhi-dhi
```

The push commands use:

```text
--sbom=true --provenance=mode=max
```

That gives Docker Scout the attestations it needs for the best available
Hub / Scout evidence. Some generic Scout base-image policy cards may
still show `No data`; the demo signal is the DHI-specific evidence plus
the size, package-count, and vulnerability comparison.

## Secrets

Do not paste Docker credentials into a sandbox VM. Step 0 of the
Labspace registers SBX custom secrets on the host. The kits write
placeholder Docker auth config inside the sandbox, and SBX replaces those
placeholders through the host-side proxy for registry requests.

## Validate

From this `project/` directory:

```sh
sbx kit validate ./kits/container-best-practices
sbx kit validate ./kits/dhi
```

Optional helper scripts:

```sh
./scripts/dhi-auth.sh <docker-username>
./scripts/dhi-compare.sh
./scripts/smoke.sh
```
