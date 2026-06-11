# Labspace - SBX Kits and Docker Hardened Images

This Labspace shows how to run AI coding agents inside isolated Docker Sandboxes (sbx) and progressively harden what the agent produces using sbx kits and Docker Hardened Images (DHI).

You'll containerize the same Node.js service three times, first in a plain sandbox, then with a generic container best-practices kit, then with a DHI kit and compare the results in Docker Hub / Docker Scout. Each sandbox runs the agent in its own microVM with its own Docker daemon, filesystem, and network, so nothing touches your host. 

## Learning objectives
 
By the end of this Labspace, you will have learned the following:
 
- How to run an AI coding agent (Claude) in an isolated Docker Sandbox microVM with its own daemon, filesystem, and network
- How sandbox network policy allows approved development endpoints while denying everything else
- What an sbx **kit** is: declarative, repeatable, shareable agent configuration (tools, credentials, network rules, files, startup commands, and guidance) defined in a single `spec.yaml`
- How attaching a container best-practices kit changes the agent's output compared to a plain sandbox
- How a DHI kit directs the agent to use Docker Hardened Images for both build and runtime stages
- How to keep registry credentials on the host using sbx custom secrets, so the real Docker PAT never enters the sandbox VM
- How to push baseline vs. DHI image tags and compare size, package count, vulnerabilities, and attestations (SBOM + provenance) in Docker Hub / Docker Scout

## Launch the Labspace
 
> [!NOTE]
> The Labspace uses the host-backed `ttyd` provider from the Docker Labspace CLI plugin so `sbx` can create sandboxes with host access. Before launching, make sure you have Docker Desktop running, the `sbx` CLI installed and authenticated (`sbx login`), and a Docker Personal Access Token that can pull Docker Hardened Images. Step 0 of the lab walks through these prerequisites.
 
To launch the Labspace, run the following command:
 
```
docker compose -f oci://dockersamples/labspace-demo-sbx-kits-dhi up -d
```
 
And then open your browser to <http://localhost:3030>.


## Current State

Read [HANDOFF.md](./HANDOFF.md) before resuming after a restart. It
records the current implementation state, how to relaunch the Labspace,
what has already been verified, and the remaining real DHI credential
check.

## Local Development

Install or update the Docker Labspace CLI plugin:

```bash
gh release download v0.6.0 \
  --repo docker/docker-labspace-cli \
  --pattern docker-labspace-darwin-arm64 \
  --pattern checksums.sha256
shasum -a 256 -c checksums.sha256 --ignore-missing
mkdir -p ~/.docker/cli-plugins ~/.local/bin
install -m 0755 docker-labspace-darwin-arm64 ~/.docker/cli-plugins/docker-labspace
ln -sf ~/.docker/cli-plugins/docker-labspace ~/.local/bin/labspace
docker labspace version
```

Run the Labspace from this repository root:

```bash
CONTENT_PATH=$PWD docker labspace author
```

For a one-off local launch without authoring watch mode:

```bash
CONTENT_PATH=$PWD docker labspace launch ./compose.yaml -y
```

Open:

```text
Lab page: http://localhost:3030
Terminal: http://localhost:8085
```

Inside the Labspace terminal, follow Step 0.

If the Labspace base content pull returns `401 Unauthorized`, log in to
Docker Hub on the host with a PAT, then run the command again:

```bash
docker login
```

## Contents

- `compose.yaml` adds the development sync service for host-backed project files.
- `compose.override.yaml` switches the workspace to the Labspace `ttyd` provider and disables `host-republisher`.
- `labspace/labspace.yaml` defines the lab metadata and sections.
- `project/` contains the SBX kits demo.

## Contributing
 
If you find something wrong or something that needs to be updated, feel free to submit a PR. If you want to make a larger change, feel free to fork the repo into your own repository.
 
**Important note:** If you fork it, you will need to update the GHA workflow to point to your own Hub repo.
 
1. Clone this repo
2. Start the Labspace in content development mode:
```
   # On Mac/Linux
   CONTENT_PATH=$PWD docker compose up --watch
 
   # On Windows with PowerShell
   $Env:CONTENT_PATH = (Get-Location).Path; docker compose up --watch
```
 
3. Open the Labspace at <http://localhost:3030>.
4. Make the necessary changes and validate they appear as you expect in the Labspace
   Be sure to check out the [docs](https://github.com/dockersamples/labspace-infra/tree/main/docs) for additional information and guidelines.
 
