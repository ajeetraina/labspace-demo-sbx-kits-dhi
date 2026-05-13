# Add the Best Practices Kit

Now run the same task with a generic container best-practices kit attached.

Inspect the kit:

```bash
cd ~/.labspace/project
sbx kit inspect ./kits/container-best-practices
sed -n '1,40p' ./kits/container-best-practices/spec.yaml
sed -n '1,80p' ./kits/container-best-practices/files/home/.claude/skills/container-best-practices/SKILL.md
```

Start a fresh sandbox with the kit:

```bash
cd ~/.labspace/project/demo/sample-app
sbx run --name p2-best-practices claude --kit ../../kits/container-best-practices
```

Ask the same thing:

```text
Containerize this app. Build the image and run it.
```

Compare the result with the plain sandbox. The kit should push the agent toward:

- A pinned base image instead of `latest`
- A multi-stage Dockerfile
- A non-root runtime user
- A `.dockerignore`
- `hadolint Dockerfile` before completion

The lesson: a kit is reusable, versioned guidance. It gives every agent the same baseline without rewriting prompts by hand.
