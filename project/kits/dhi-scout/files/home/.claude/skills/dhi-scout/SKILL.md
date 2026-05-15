---
name: dhi-scout
description: Use Docker Hardened Images (DHI) as base images and validate every built image with Docker Scout (CVEs + organizational policy) before declaring containerization work done. Use this skill whenever the user asks to containerize, harden, or ship an application image.
---

# Docker Hardened Images + Scout Policy Gate

This skill turns "the Dockerfile builds" into "the image is shippable
under our security policy". It runs **after** you have produced a
working Dockerfile (see the `container-best-practices` skill if
present) and **before** you push to CI.

## 1. Confirm tooling and proxy-managed credentials

Before changing the Dockerfile, check the local tooling and credential
placeholders:

```
docker version
docker scout version
docker dhi --version || dhictl --version
test -f ~/.docker/config.json && sed -n '1,120p' ~/.docker/config.json
env | grep -E '^(DOCKER_HUB_CREDS|DHI_CREDS|DHI_API_TOKEN|DOCKER_SCOUT_)' | sort
docker scout environment
```

The Docker config should contain placeholder `auth` values for
`https://index.docker.io/v1/` and `https://dhi.io`. Those placeholders
are not real credentials; the SBX host proxy replaces them on outbound
registry requests. The sandbox must never receive the real Docker PAT.

If `DOCKER_HUB_CREDS`, `DHI_CREDS`, `DHI_API_TOKEN`, or the
`DOCKER_SCOUT_*` variables are missing, say that Step 0 secrets were
not configured for this sandbox and continue only as far as local,
unauthenticated commands allow.

Before choosing base images, prefer the DHI catalog:

```
docker dhi catalog list --json || dhictl catalog list --json
docker dhi catalog get node --json || dhictl catalog get node --json
```

## 2. Use DHI for every base image

Docker Hardened Images (DHI) are minimal, signed, low-CVE images
maintained by Docker. Docker Hardened Images are pulled from `dhi.io`
for Docker Hardened Images Community access, or from the organization's
configured Docker Hub mirror for Docker Hardened Images Select or
Enterprise access.

When picking a base image:

- Replace `node:20.11-alpine` with the equivalent DHI tag from the
  catalog, e.g. `dhi.io/node:20`, unless the organization uses a
  Docker Hub mirror.
- For runtimes without a direct DHI equivalent, use the closest DHI
  distro image (e.g. `dhi.io/static`, `dhi.io/debian`)
  and document why.
- Both `build` and `runtime` stages must use DHI bases.

For multi-stage builds, use the DHI development image for the build
stage when available (for example a `-dev` tag), then copy the runtime
artifact into the matching minimal runtime DHI image.

If a DHI image truly does not exist for the runtime in question,
state this explicitly in your final report - do not silently fall
back to an unhardened image.

If the DHI pull is denied, report that Docker registry authentication is
required for the sandbox and stop before weakening the base image.

## 3. Build, then validate with Scout every time

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

- **All policies pass**: image is shippable. Report the image digest.
- **One or more policies fail**: DO NOT mark the task complete.
  Iterate:
  - Bump the base image to a newer DHI tag.
  - Drop transitive deps that introduce critical CVEs.
  - If a CVE has no upstream fix, document it explicitly in the
    final report and ask the user how to proceed.

## 5. Final report shape

When the work is done, your report MUST include:

```
Image:        <repo>:<tag>  (sha256:...)
Base:         dhi.io/<image>:<tag> or <org>/<dhi-mirror>:<tag>
DHI catalog:  <docker dhi catalog source used>
Size:         <MB>
Scout policy: <PASS | FAIL - reasons>
CVEs:         critical=N high=M (vs. budget X/Y)
Next action:  push | block | escalate
```

If Scout policy fails, the next action is **never** "push". It is
"block" or "escalate". This is the whole point of running the skill
locally before CI: catching policy violations on your laptop, not in
a failing pipeline at 4pm on a Friday.

## 6. Suggested run order

1. Confirm Dockerfile follows container best practices.
2. Check Docker, Scout, and DHI CLI versions.
3. Check `~/.docker/config.json` for registry auth placeholders.
4. Check `env | grep -E '^(DOCKER_HUB_CREDS|DHI_CREDS|DHI_API_TOKEN|DOCKER_SCOUT_)' | sort`.
5. Check `docker scout environment`.
6. Query `docker dhi catalog list --json`.
7. Swap base images to `dhi.io/...` equivalents, or the organization's
   Docker Hub mirror if that is what the account uses.
8. `docker build -t app:dev .`
9. `docker scout quickview app:dev`
10. `docker scout cves --only-severity critical,high app:dev`
11. `docker scout policy app:dev`
12. Iterate until Scout passes.
13. Emit the final report (section 5) and stop.
