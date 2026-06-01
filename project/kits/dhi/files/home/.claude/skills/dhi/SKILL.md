---
name: dhi
description: Use Docker Hardened Images (DHI) as build and runtime base images, then collect local image evidence for Docker Hub review. When this skill is installed, use it for containerization, Dockerfile, image hardening, or application image preparation tasks; it takes base-image precedence over generic container best-practices guidance.
---

# Docker Hardened Images

This skill turns "the Dockerfile builds" into "the image uses hardened
base images and has useful evidence". When this skill is installed, use
it during initial Dockerfile authoring for normal containerization
requests, not only when the user explicitly says "DHI".

If another skill also applies, such as `container-best-practices`, keep
its generic Dockerfile guidance but let this DHI skill decide the build
and runtime base images. Do not choose Docker Official Images when a DHI
equivalent exists.

## 1. Use DHI for every base image

Docker Hardened Images (DHI) are minimal, signed, low-CVE images
maintained by Docker. Community images live under `dhi.io/`.

When picking a base image:

- For this repository's Node demo app, replace `node:24-trixie-slim`
  with the same DHI bases used in Docker's DHI Node lab:
  `dhi.io/node:24-debian13-dev` for stages that need `npm`, a shell,
  or other build tooling, and `dhi.io/node:24-debian13` for the final
  runtime stage.
- If the user is using a paid DHI mirror, use the mirrored equivalent
  such as `<org>/dhi-node:24-debian13-dev` and
  `<org>/dhi-node:24-debian13`.
- For other runtimes, check the available tags in the Docker Hardened
  Images catalog before choosing.
- For runtimes without a direct DHI equivalent, use the closest DHI
  distro image, such as `dhi.io/static` or `dhi.io/debian`, and
  document why.
- Both `build` and `runtime` stages must use DHI bases.
- Authenticate with `docker login dhi.io` only if the image pull
  requires it and the user provides credentials through the approved
  lab flow.

If a DHI image truly does not exist for the runtime in question,
state this explicitly in your final report. Do not silently fall back to
an unhardened image.

## 2. Build and collect evidence

After `docker build -t <name>:<tag> .`, collect at least:

```bash
docker image inspect <name>:<tag> --format '{{.Id}} {{.Size}} {{.Config.User}}'
```

The app does not ship a reference Dockerfile; you write it. The
baseline-vs-DHI comparison comes from the pushed Docker Hub tags — the
earlier plain pass pushes the baseline image it built, and this DHI pass
pushes the DHI image you build — not from any local reference Dockerfile.

The preferred visual proof is the Docker Hub / Docker Scout Dashboard
comparison after the baseline and DHI tags are pushed. If pushing a
comparison image for Scout, build with `--sbom=true` and
`--provenance=mode=max`; Scout needs max-mode provenance to trace DHI
base-image lineage and apply DHI/VEX evidence correctly. Do not block
the DHI work on local Scout authentication.

`dhictl` and `docker dhi` are preinstalled in this sandbox.

## 3. Final report shape

When the work is done, your report MUST include:

```text
Image:       <repo>:<tag>  (sha256:...)
Base:        dhi.io/<image>:<tag>
Size:        <MB>
User:        <runtime user from image config>
Evidence:    image inspect complete; use Hub/Scout Dashboard after push
Next action: push for Hub review | block | escalate
```

## 4. Suggested run order

1. Confirm Dockerfile follows container best practices.
2. Check DHI availability with `docker dhi catalog list --json` or
   `dhictl catalog list --json`.
3. Swap base images to `dhi.io/...` equivalents.
4. Build the image.
5. Inspect size, digest, and configured runtime user.
6. Emit the final report and stop.
