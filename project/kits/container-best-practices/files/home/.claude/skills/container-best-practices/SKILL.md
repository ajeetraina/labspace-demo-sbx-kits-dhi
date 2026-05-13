---
name: container-best-practices
description: Authoring Dockerfiles and container builds that follow widely accepted best practices. Use this skill whenever the user asks for a Dockerfile, a container build, or to containerize an application.
---

# Container Best Practices

When you write or modify a `Dockerfile`, follow these rules. They are
non-negotiable defaults; deviate only if the user explicitly asks.

## 1. Pin everything
- Pin the base image by **major.minor** at minimum, ideally by digest:
  `FROM node:20.11-alpine` or `FROM node@sha256:...`. Never `:latest`.
- Pin OS packages (`apt-get install -y --no-install-recommends pkg=1.2.3`)
  when reproducibility matters.

## 2. Use multi-stage builds
- Separate `build` and `runtime` stages. The final image must contain
  only what is needed at runtime — no compilers, no dev dependencies,
  no source maps unless required.
- Name your stages: `FROM node:20.11-alpine AS build`.

## 3. Pick a minimal base
Prefer in this order: distroless → alpine → -slim → full. Justify a
larger base in a comment if you choose one.

## 4. Run as non-root
- Create a dedicated user/group and `USER` to it before `CMD`.
- Make sure the workdir and any writable paths are owned by that user.

## 5. Order layers for cache
- Copy dependency manifests first, install, **then** copy source:
  ```
  COPY package*.json ./
  RUN npm ci --omit=dev
  COPY . .
  ```
- Combine related `RUN` steps with `&&` and `\` to keep layers small.
- Always clean package caches in the same `RUN` (`rm -rf /var/lib/apt/lists/*`).

## 6. Always ship a `.dockerignore`
At minimum: `.git`, `node_modules`, `**/*.log`, `.env*`, `dist`, `coverage`.
Without it, build context bloats and secrets leak.

## 7. Prefer `COPY` over `ADD`
Only use `ADD` for tarball extraction or remote URLs (and even then,
prefer `curl | tar`).

## 8. Healthcheck and signals
- Add a `HEALTHCHECK` that exercises the real readiness path.
- Use `CMD ["exec", "form"]` (JSON array) so signals are forwarded.
- Set `STOPSIGNAL` if the runtime needs something other than SIGTERM.

## 9. No secrets in layers
- Never `COPY .env` or bake API keys into the image.
- Use build secrets (`RUN --mount=type=secret,id=...`) or runtime env.

## 10. Lint before declaring done
After writing a Dockerfile run:

```
hadolint Dockerfile
```

Fix every warning that you cannot suppress with a justified reason.
`hadolint` is preinstalled in this sandbox.

## Workflow checklist

When asked to containerize an app:

1. Read the project to understand language, build system, and entrypoint.
2. Write a `.dockerignore`.
3. Write a multi-stage `Dockerfile` following rules 1–9.
4. Run `hadolint Dockerfile` and fix issues.
5. If a Docker daemon is available, build and smoke-test:
   `docker build -t app:dev . && docker run --rm app:dev`.
6. Report image size (`docker image ls app:dev`) and any remaining
   trade-offs.
