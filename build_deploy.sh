#!/bin/bash
set -euo pipefail

REGISTRY="quay.io/mylastres0rt05"

VERSIONS=(
  "v1.44.0-jammy v1.44.0 v1.44 124"
  "v1.43.0-jammy v1.43.0 v1.43 123"
  "v1.42.0-jammy v1.42.0 v1.42 122"
  "v1.41.0-jammy v1.41.0 v1.41 121"
  "v1.40.0-jammy v1.40.0 v1.40 120"
)

echo "==> Building tor-proxy"
docker build -t "${REGISTRY}/tor-proxy:latest" tor-proxy/
docker push "${REGISTRY}/tor-proxy:latest"

for entry in "${VERSIONS[@]}"; do
  read -r tag ver label chrome <<< "$entry"
  echo "==> Building thor-session:${label} (Chrome ${chrome})"
  docker build \
    --build-arg PLAYWRIGHT_TAG="${tag}" \
    --build-arg PLAYWRIGHT_VERSION="${ver}" \
    --build-arg CHROME_VERSION="${chrome}" \
    -t "${REGISTRY}/thor-session:${label}" .
  docker push "${REGISTRY}/thor-session:${label}"
done

echo "==> Done"
