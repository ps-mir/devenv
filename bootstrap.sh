#!/usr/bin/env bash
set -euo pipefail

# ── args ──────────────────────────────────────────────────────────────────────
TAGS=""
EMAIL=""
EXTRA_VARS=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --tags)       TAGS="$2";       shift 2 ;;
    --email)      EMAIL="$2";      shift 2 ;;
    --extra-vars) EXTRA_VARS="$2"; shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

# ── print coder params ────────────────────────────────────────────────────────
echo "============================================"
echo " Coder Parameters"
echo "============================================"
echo "  tags:       ${TAGS:-<none>}"
echo "  email:      ${EMAIL:-<none>}"
echo "  extra-vars: ${EXTRA_VARS:-<none>}"
echo "============================================"

# ── detect os ────────────────────────────────────────────────────────────────
if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS=$ID
else
  echo "ERROR: Cannot detect OS" && exit 1
fi

echo "Detected OS: $OS"

# ── build-essential tools ─────────────────────────────────────────────────────
case $OS in
  ubuntu|debian)
    sudo apt-get update -qq
    sudo apt-get install -y --no-install-recommends \
      git \
      curl \
      wget \
      unzip \
      build-essential \
      ca-certificates
    ;;
  fedora|rhel|centos)
    sudo dnf install -y \
      git \
      curl \
      wget \
      unzip \
      gcc \
      gcc-c++ \
      make \
      ca-certificates
    ;;
  *)
    echo "ERROR: Unsupported OS: $OS" && exit 1
    ;;
esac

echo "Build-essential tools installed."

# ── uv ───────────────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"

if ! command -v uv &>/dev/null; then
  echo "Installing uv..."
  curl -fsSL https://astral.sh/uv/install.sh | sh
  echo "uv installed: $(uv --version)"
else
  echo "uv already installed: $(uv --version)"
fi

echo "Bootstrap complete."
