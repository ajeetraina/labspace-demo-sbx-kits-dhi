---
name: dhi-scout
description: Use Docker Hardened Images (DHI) as base images and validate every built image with Docker Scout (CVEs + organizational policy) before declaring containerization work done. Use this skill whenever the user asks to containerize, harden, or ship an application image.
---

# Docker Hardened Images + Scout policy gate

This skill turns "the Dockerfile builds" into "the image is shippable
under our security policy". It runs **after** you have produced a
working Dockerfile (see the `container-best-practices` skill if
present) and **before** you push to CI.

## 1. Use DHI for every base image

Docker Hardened Images (DHI) are minimal, signed, low-CVE images
maintained by Docker. They live under `docker.io/dhi/`.

When picking a base image:

- Replace `node:20.11-alpine` with the equivalent DHI tag, e.g.
  `docker.io/dhi/node:20`. Check the available tags at
  https://hub.docker.com/u/dhi.
- For runtimes without a direct DHI equivalent, use the closest DHI
  distro image (e.g. `docker.io/dhi/static`, `docker.io/dhi/debian`)
  and document why.
- Both `build` and `runtime` stages must use DHI bases.

If a DHI image truly does not exist for the runtime in question,
state this explicitly in your final report — do not silently fall
back to an unhardened image.

## 2. Build, then validate with Scout — every time

After `docker build -t <name>:<tag> .`, run **all three** Scout
commands. Treat any non-zero exit code as a failure that blocks
"done".

```
# 2a. Quick CVE summary
docker scout quickview <name>:<tag>

# 2b. Full CVE listing for high/critical
docker scout cves --only-severity critical,high <name>:<tag>

# 2c. Policy evaluation against the org's Scout policies
docker scout policy <name>:<tag>
```

`docker scout` is preinstalled in this sandbox.

## 3. Interpreting policy results

`docker scout policy` returns the org-defined policy set
(supply-chain attestations, allowed base images, CVE budgets, etc.).

- **All policies pass** → image is shippable. Report the image digest.
- **One or more policies fail** → DO NOT mark the task complete.
  Iterate:
  - Bump the base image to a newer DHI tag.
  - Drop transitive deps that introduce critical CVEs.
  - If a CVE has no upstream fix, document it explicitly in the
    final report and ask the user how to proceed.

## 4. Final report shape

When the work is done, your report MUST include:

```
Image:        <repo>:<tag>  (sha256:...)
Base:         docker.io/dhi/<image>:<tag>
Size:         <MB>
Scout policy: <PASS | FAIL — reasons>
CVEs:         critical=N high=M (vs. budget X/Y)
Next action:  push | block | escalate
```

If Scout policy fails, the next action is **never** "push". It is
"block" or "escalate". This is the whole point of running the skill
locally before CI: catching policy violations on your laptop, not in
a failing pipeline at 4pm on a Friday.

## 5. Suggested run order

1. Confirm Dockerfile follows container best practices.
2. Swap base images to `docker.io/dhi/...` equivalents.
3. `docker build -t app:dev .`
4. `docker scout quickview app:dev`
5. `docker scout cves --only-severity critical,high app:dev`
6. `docker scout policy app:dev`
7. Iterate until 6 passes.
8. Emit the final report (section 4) and stop.
