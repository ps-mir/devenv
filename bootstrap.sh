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

# ── logging ───────────────────────────────────────────────────────────────────
LOG_DIR="$HOME/.devenv/logs"
LOG_FILE="$LOG_DIR/bootstrap-$(date +%Y%m%d-%H%M%S).log"
MAX_LOGS=10

mkdir -p "$LOG_DIR"
ls -t "$LOG_DIR"/bootstrap-*.log 2>/dev/null | tail -n +$((MAX_LOGS + 1)) | xargs rm -f || true
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Logging to: $LOG_FILE"

# ── print coder params ────────────────────────────────────────────────────────
echo "============================================"
echo " Coder Parameters"
echo "============================================"
echo "  tags:         ${TAGS:-<none>}"
echo "  email:        ${EMAIL:-<none>}"
echo "  extra-vars:   ${EXTRA_VARS:-<none>}"
echo "  ansible-roles: ${ANSIBLE_ROLES:-<none>}"
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

# ── ansible ───────────────────────────────────────────────────────────────────
if ! command -v ansible-playbook &>/dev/null; then
  echo "Installing ansible..."
  uv tool install ansible-core
  echo "ansible installed: $(ansible-playbook --version | head -1)"
else
  echo "ansible already installed: $(ansible-playbook --version | head -1)"
fi

# ── clone devenv repo ─────────────────────────────────────────────────────────
DEVENV_DIR="$HOME/.devenv/repo"
DEVENV_REPO="https://github.com/ps-mir/devenv.git"

if [ -d "$DEVENV_DIR/.git" ]; then
  echo "Updating devenv repo..."
  git -C "$DEVENV_DIR" pull
else
  echo "Cloning devenv repo..."
  git clone "$DEVENV_REPO" "$DEVENV_DIR"
fi

# ── run base playbook ─────────────────────────────────────────────────────────
BASE_PLAYBOOK="$DEVENV_DIR/playbooks/base.yaml"

echo "Running base playbook: $BASE_PLAYBOOK"

ANSIBLE_ARGS=()
[[ -n "$TAGS" ]]       && ANSIBLE_ARGS+=("--tags" "$TAGS")
[[ -n "$EXTRA_VARS" ]] && ANSIBLE_ARGS+=("--extra-vars" "$EXTRA_VARS")

ansible-playbook "${ANSIBLE_ARGS[@]}" "$BASE_PLAYBOOK"

# ── run role playbooks ─────────────────────────────────────────────────────────
if [[ -n "${ANSIBLE_ROLES:-}" ]]; then
  for role in $ANSIBLE_ROLES; do
    ROLE_PLAYBOOK="$DEVENV_DIR/playbooks/${role}.yaml"
    if [[ -f "$ROLE_PLAYBOOK" ]]; then
      echo "Running role playbook: $ROLE_PLAYBOOK"
      ansible-playbook "${ANSIBLE_ARGS[@]}" "$ROLE_PLAYBOOK"
    else
      echo "WARNING: No playbook found for role '$role' (expected: $ROLE_PLAYBOOK)"
    fi
  done
fi

echo "Bootstrap complete."
