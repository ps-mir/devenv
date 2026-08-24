#!/usr/bin/env bash
# Runs `make precommit` (or any command passed as args) for the git repo
# in the current directory, inside a container with its own network
# namespace, so tests that bind fixed loopback ports (e.g. the OTLP
# default 4317) never collide with services running on the host.
#
# Go module/build caches are bind-mounted from the host so nothing
# is re-downloaded or rebuilt on every run. The container image is
# built lazily, tagged to the host's installed Go version, and only
# rebuilt when that version changes.
set -euo pipefail

DOCKERFILE_DIR="$HOME/.local/share/precommit-sandbox"
REPO_ROOT="$(git rev-parse --show-toplevel)"
GOMODCACHE="$(go env GOMODCACHE)"
GOCACHE="$(go env GOCACHE)"

GO_VERSION="$(go version | awk '{print $3}' | sed 's/^go//')"
IMAGE="precommit-sandbox:go${GO_VERSION}"

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "==> $IMAGE not found locally, building (one-time per Go version)..." >&2
  docker build --build-arg "GO_VERSION=$GO_VERSION" -t "$IMAGE" "$DOCKERFILE_DIR"
fi

if [ "$#" -eq 0 ]; then
  CMD=(make precommit)
else
  CMD=("$@")
fi

TTY_FLAGS=()
if [ -t 1 ]; then
  TTY_FLAGS=(-it)
fi

docker run --rm "${TTY_FLAGS[@]}" \
  --user "$(id -u):$(id -g)" \
  -e HOME=/tmp/home \
  -e GOMODCACHE=/go/pkg/mod \
  -e GOCACHE=/go-build-cache \
  -v "$REPO_ROOT":/workspace \
  -v "$GOMODCACHE":/go/pkg/mod \
  -v "$GOCACHE":/go-build-cache \
  -v /etc/passwd:/etc/passwd:ro \
  -v /etc/group:/etc/group:ro \
  -w /workspace \
  "$IMAGE" \
  bash -c 'mkdir -p "$HOME" && exec "$@"' bash "${CMD[@]}"
