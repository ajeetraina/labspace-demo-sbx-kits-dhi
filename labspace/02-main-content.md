# Add the Best Practices Kit

Now run the same task with a kit attached. A kit is the reusable unit of policy: it can install tools, copy files into the agent home, and teach the agent how to handle a class of work.

Inspect the generic container kit:

```bash
cd ~/.labspace/project
sbx kit inspect ./kits/container-best-practices
sed -n '1,40p' ./kits/container-best-practices/spec.yaml
sed -n '1,80p' ./kits/container-best-practices/files/home/.claude/skills/container-best-practices/SKILL.md
```

Start a fresh sandbox with that kit:

```bash
cd ~/.labspace/project/demo/sample-app
sbx run --name p2-best-practices claude --kit ../../kits/container-best-practices
```

Ask the same thing:

```text
Containerize this app. Build the image and run it.
```

Compare this result with the baseline sandbox. The kit should push the agent toward a pinned base image, multi-stage build, non-root runtime user, `.dockerignore`, and `hadolint Dockerfile` before it calls the task done.

The point is not that the agent suddenly knows Docker. The point is that the organization can ship repeatable Docker guidance as a versioned kit instead of rewriting prompts by hand.
