#!/usr/bin/env sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
app_dir="$repo_root/demo/sample-app"
baseline_tag=${BASELINE_TAG:-dhi-demo-node-doi:v1}
dhi_tag=${DHI_TAG:-dhi-demo-node-dhi:v2}
tmp_dir=$(mktemp -d)

cleanup() {
  rm -rf "$tmp_dir"
}

trap cleanup EXIT INT TERM

cat > "$tmp_dir/Dockerfile.doi" <<'DOCKERFILE'
FROM node:24-trixie-slim

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY tsconfig.json ./
COPY src ./src
COPY public ./public

RUN npm run build \
  && npm cache clean --force

ENV NODE_ENV=production
EXPOSE 3000
CMD ["node", "dist/server.js"]
DOCKERFILE

cat > "$tmp_dir/Dockerfile.dhi" <<'DOCKERFILE'
FROM dhi.io/node:24-debian13-dev AS build

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm ci

COPY tsconfig.json ./
COPY src ./src
RUN npm run build \
  && npm prune --omit=dev \
  && npm cache clean --force

FROM dhi.io/node:24-debian13 AS production

ENV NODE_ENV=production
WORKDIR /usr/src/app

COPY --from=build /usr/src/app/node_modules ./node_modules
COPY --from=build /usr/src/app/dist ./dist
COPY public ./public
COPY package*.json ./

EXPOSE 3000
CMD ["node", "dist/server.js"]
DOCKERFILE

echo "Building baseline Docker Official Image: $baseline_tag"
docker build --provenance=mode=max --sbom=true \
  -f "$tmp_dir/Dockerfile.doi" \
  -t "$baseline_tag" \
  "$app_dir"

echo
echo "Building DHI image: $dhi_tag"
docker build --provenance=mode=max --sbom=true \
  -f "$tmp_dir/Dockerfile.dhi" \
  -t "$dhi_tag" \
  "$app_dir"

echo
docker image inspect "$baseline_tag" "$dhi_tag" \
  --format '{{join .RepoTags ","}} {{.Size}} bytes'

echo
echo "Push both tags and use Docker Hub / Docker Scout Dashboard for the shareable comparison."
