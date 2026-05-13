# Run Parallel Agents

The sample app was initialized as a Git repository in the prerequisites, so `sbx --branch` can create isolated worktrees.

Open two terminals and run one command in each:

```bash
cd demo/sample-app
sbx run --name p3-claude --branch feat/dockerize claude \
  --kit ../../kits/container-best-practices
```

```bash
cd demo/sample-app
sbx run --name p3-opencode --branch feat/tests opencode \
  --kit ../../kits/container-best-practices
```

Ask the first agent to containerize the service. Ask the second agent to add a `/healthz` integration test using `node:test` and `supertest`.

While they run, inspect the sandboxes and worktrees:

```bash
sbx ls
git -C demo/sample-app worktree list
```

The worktrees are created under `demo/sample-app/.sbx/<sandbox>-worktrees/`, with slashes in branch names replaced by hyphens.
