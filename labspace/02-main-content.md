# Add Container Guardrails

Start by inspecting the generic container best practices kit:

```bash
sbx kit inspect ./kits/container-best-practices
sed -n '1,40p' ./kits/container-best-practices/spec.yaml
sed -n '1,60p' ./kits/container-best-practices/files/home/.claude/skills/container-best-practices/SKILL.md
```

Create a sandbox with the kit attached:

```bash
cd demo/sample-app
sbx run --name p2-best-practices claude --kit ../../kits/container-best-practices
```

When Claude opens, ask it to containerize the service and build the image.

Expected behavior:

- A pinned base image rather than `latest`
- A multi-stage Dockerfile
- A non-root runtime user
- A `.dockerignore`
- `hadolint Dockerfile` run before completion
