---
name: dhi-scout
description: Use Docker Hardened Images (DHI) as base images and validate every built image with Docker Scout (CVEs + organizational policy) before declaring containerization work done. Use this skill whenever the user asks to containerize, harden, or ship an application image.
---

# Docker Hardened Images + Scout policy gate

This skill turns "the Dockerfile builds" into "the image is shippable
under our security policy". It runs **after** you have produced a
working Dockerfile (see the `container-best-practices` skill if
present) and **before** you push to CI.

## 1. Confirm Docker Scout credentials

Before changing the Dockerfile, check whether Scout credentials are
available:

```
test "${DOCKERHUB_AUTH_B64:-}" = proxy-managed && echo "DHI registry auth is proxy-managed"
env | grep '^DOCKER_SCOUT_' | sort
docker scout environment
```

If `DOCKERHUB_AUTH_B64` is not `proxy-managed`, DHI registry auth was
not configured for this sandbox. If `DOCKER_SCOUT_HUB_USER`,
`DOCKER_SCOUT_HUB_PASSWORD`,
`DOCKER_SCOUT_REGISTRY_USER`, or `DOCKER_SCOUT_REGISTRY_PASSWORD` are
missing, say so and continue only as far as the local build allows. Do
not ask the user to paste a Docker PAT into the sandbox. These values
should be provided by host-side SBX secrets.

## 2. Use DHI for every base image

Docker Hardened Images (DHI) are minimal, signed, low-CVE images
maintained by Docker. Docker Hardened Images are pulled from `dhi.io`
for Docker Hardened Images Community access, or from the organization's
configured Docker Hub mirror for Docker Hardened Images Select or
Enterprise access.

When picking a base image:

- Replace `node:20.11-alpine` with the equivalent DHI tag, e.g.
  `dhi.io/node:20`, unless the organization uses a Docker Hub mirror.
- For runtimes without a direct DHI equivalent, use the closest DHI
  distro image (e.g. `dhi.io/static`, `dhi.io/debian`)
  and document why.
- Both `build` and `runtime` stages must use DHI bases.

If a DHI image truly does not exist for the runtime in question,
state this explicitly in your final report — do not silently fall
back to an unhardened image.

If the DHI pull is denied, report that Docker registry authentication is
required for the sandbox and stop before weakening the base image.

## 3. Build, then validate with Scout — every time

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

## 4. Interpreting policy results

`docker scout policy` returns the org-defined policy set
(supply-chain attestations, allowed base images, CVE budgets, etc.).

- **All policies pass** → image is shippable. Report the image digest.
- **One or more policies fail** → DO NOT mark the task complete.
  Iterate:
  - Bump the base image to a newer DHI tag.
  - Drop transitive deps that introduce critical CVEs.
  - If a CVE has no upstream fix, document it explicitly in the
    final report and ask the user how to proceed.

## 5. Final report shape

When the work is done, your report MUST include:

```
Image:        <repo>:<tag>  (sha256:...)
Base:         dhi.io/<image>:<tag>
Size:         <MB>
Scout policy: <PASS | FAIL — reasons>
CVEs:         critical=N high=M (vs. budget X/Y)
Next action:  push | block | escalate
```

If Scout policy fails, the next action is **never** "push". It is
"block" or "escalate". This is the whole point of running the skill
locally before CI: catching policy violations on your laptop, not in
a failing pipeline at 4pm on a Friday.

## 6. Suggested run order

1. Confirm Dockerfile follows container best practices.
2. Check `env | grep '^DOCKER_SCOUT_' | sort`.
3. Check `docker scout environment`.
4. Swap base images to `dhi.io/...` equivalents, or the organization's
   Docker Hub mirror if that is what the account uses.
5. `docker build -t app:dev .`
6. `docker scout quickview app:dev`
7. `docker scout cves --only-severity critical,high app:dev`
8. `docker scout policy app:dev`
9. Iterate until 8 passes.
10. Emit the final report (section 5) and stop.
