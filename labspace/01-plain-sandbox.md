# Start with a Plain Sandbox

First, let the agent containerize a small Node service in an isolated sandbox with no kit attached.

Open the sample app:

```bash
cd ~/.labspace/project/demo/sample-app
sed -n '1,120p' package.json
sed -n '1,160p' index.js
```

Run the baseline sandbox:

```bash
sbx run --name p1-yolo claude
```

When Claude opens, ask:

```text
Containerize this app. Build the image and run it.
```

This first pass is intentionally unconstrained. Look for the quality bar the model chooses by itself:

- Does it use `latest` or a pinned base image?
- Does it use one stage or multiple stages?
- Does the container run as root?
- Does it create `.dockerignore`?
- Does it lint or verify the Dockerfile?

The lesson: SBX gives the agent a real shell and Docker daemon inside an isolated sandbox. The isolation is strong, but the output quality is still whatever the model decides without guidance.
