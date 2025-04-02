#!/bin/bash

# SPDX-FileCopyrightText: 2025 Jehad Nasser
# SPDX-License-Identifier: MIT

set -euxo pipefail

# Constants
SHARED_DIR="/lima-data-vm"
YQ_URL="https://github.com/mikefarah/yq/releases/latest/download/yq_linux_arm64"
K3S_INSTALL_SCRIPT="https://get.k3s.io"
KUBECTL_BASE_URL="https://dl.k8s.io/release"
KUBECONFIG_SRC="/etc/rancher/k3s/k3s.yaml"
KUBECONFIG_DEST="/lima-data-vm/kubeconfig.yaml"

# Logging helper
log() {
  echo "📦 [$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# --- Step 1: Install yq ---
install_yq() {
  if ! command -v yq &>/dev/null; then
    log "Installing yq..."
    curl -fsSL "$YQ_URL" -o /usr/local/bin/yq || {
      log "Failed to download yq"; exit 1
    }
    chmod +x /usr/local/bin/yq
  else
    log "yq already installed. Skipping."
  fi
}

# --- Step 2: Install K3s ---
install_k3s() {
  if ! command -v k3s &>/dev/null; then
    log "Installing K3s..."
    curl -fsSL "$K3S_INSTALL_SCRIPT" | sh - || {
      log "K3s installation failed"; exit 1
    }
  else
    log "K3s already installed. Skipping."
  fi
}

# --- Step 3: Wait for Kubeconfig ---
wait_for_kubeconfig() {
  log "Waiting for K3s kubeconfig..."
  local max_attempts=30
  local attempt=0

  until [[ -f "$KUBECONFIG_SRC" ]] || (( attempt++ >= max_attempts )); do
    sleep 2
  done

  if [[ ! -f "$KUBECONFIG_SRC" ]]; then
    log "Timeout: kubeconfig not found"; exit 1
  fi
}

# --- Step 4: Modify Kubeconfig ---
modify_kubeconfig() {
  log "Updating kubeconfig metadata..."
  yq -i '
    .clusters[0].name = "lima-k3s-cluster" |
    .users[0].name = "lima-k3s" |
    .contexts[0].name = "lima-k3s-cluster" |
    .contexts[0].context.cluster = "lima-k3s-cluster" |
    .contexts[0].context.user = "lima-k3s" |
    .current-context = "lima-k3s-cluster"
  ' "$KUBECONFIG_SRC" || { log "Failed to modify kubeconfig"; exit 1; }
}

# --- Step 5: Install kubectl ---
install_kubectl() {
  if ! command -v kubectl &>/dev/null; then
    log "Installing kubectl..."
    case "$(uname -m)" in
      x86_64)  KARCH="amd64" ;;
      aarch64) KARCH="arm64" ;;
      *)       log "Unsupported architecture: $(uname -m)"; exit 1 ;;
    esac

    KUBECTL_VERSION=$(curl -fsSL "$KUBECTL_BASE_URL/stable.txt") || {
      log "Failed to fetch kubectl version"; exit 1
    }
    curl -fsSL "$KUBECTL_BASE_URL/$KUBECTL_VERSION/bin/linux/$KARCH/kubectl" \
      -o /usr/local/bin/kubectl || { log "Failed to download kubectl"; exit 1; }
    chmod +x /usr/local/bin/kubectl
  else
    log "kubectl already installed. Skipping."
  fi
}

# --- Step 6: Copy Kubeconfig ---
copy_kubeconfig() {
  log "Copying kubeconfig to shared location..."
  mkdir -p "$(dirname "$KUBECONFIG_DEST")"
  cp "$KUBECONFIG_SRC" "$KUBECONFIG_DEST" || {
    log "Failed to copy kubeconfig"; exit 1
  }
}

# --- Main Execution ---
main() {
  apt-get update -qq
  install_yq
  install_k3s
  wait_for_kubeconfig
  modify_kubeconfig
  install_kubectl
  copy_kubeconfig
  log "✅ Provisioning completed successfully!"
}

main