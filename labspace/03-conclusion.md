# Run Agents in Worktrees

One sandbox gives isolation. Multiple sandboxes give throughput. With `--branch`, each agent gets a separate Git worktree and branch.

Open two Labspace terminals. In the first terminal, run:

```bash
cd ~/.labspace/project/demo/sample-app
sbx run --name p3-claude --branch feat/dockerize claude \
  --kit ../../kits/container-best-practices
```

Ask Claude:

```text
Containerize this service end-to-end.
```

In the second terminal, run:

```bash
cd ~/.labspace/project/demo/sample-app
sbx run --name p3-opencode --branch feat/tests opencode \
  --kit ../../kits/container-best-practices
```

Ask opencode:

```text
Add a /healthz integration test using node:test and supertest.
```

While they run, inspect the host-visible state from another terminal:

```bash
sbx ls
git -C ~/.labspace/project/demo/sample-app worktree list
```

The worktrees are created under `demo/sample-app/.sbx/<sandbox>-worktrees/`, with slashes in branch names replaced by hyphens. That means each agent can modify files independently without fighting over one working tree.
