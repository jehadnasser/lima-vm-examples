#!/bin/bash

# SPDX-FileCopyrightText: 2025 Jehad Nasser
# SPDX-License-Identifier: MIT

set -euxo pipefail

# --- Constants ---
KUBECONFIG_PATH="/lima-data-vm/kubeconfig.yaml"
BASHRC_PATH="${HOME}/.bashrc"

# --- Helper Functions ---
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

safe_add_to_file() {
  local content="$1"
  local file="$2"
  
  if ! grep -qF "$content" "$file" 2>/dev/null; then
    echo "$content" | tee -a "$file" >/dev/null
    log "Added to ${file}: ${content}"
  else
    log "Already exists in ${file}, skipping: ${content}"
  fi
}

# --- Main Execution ---
main() {
  # 1. Set kubeconfig ownership
  local username
  username=$(id -un 501 2>/dev/null || whoami) || {
    log "ERROR: Failed to determine username"
    exit 1
  }

  if [[ -f "$KUBECONFIG_PATH" ]]; then
    sudo chown "${username}" "$KUBECONFIG_PATH" || {
      log "ERROR: Failed to change ownership of ${KUBECONFIG_PATH}"
      exit 1
    }
    log "Set ownership of ${KUBECONFIG_PATH} to ${username}"
  else
    log "WARNING: Kubeconfig not found at ${KUBECONFIG_PATH}"
  fi

  # 2. Configure shell environment (idempotent)
  safe_add_to_file "export KUBECONFIG=\"${KUBECONFIG_PATH}\"" "$BASHRC_PATH"
  safe_add_to_file "alias k='kubectl'" "$BASHRC_PATH"

  # 3. Apply changes to current shell
  if [[ $- == *i* ]]; then
    # This code ONLY runs in interactive shells
    source "$BASHRC_PATH"
  fi
}

main "$@"