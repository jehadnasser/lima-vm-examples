#!/bin/bash

# SPDX-FileCopyrightText: 2025 Jehad Nasser
# SPDX-License-Identifier: MIT

set -euxo pipefail

# --- Constants ---
NGINX_ROOT="/var/www/html"
NGINX_INDEX="$NGINX_ROOT/index.html"

# --- Logging Helper ---
log() {
  echo "📦 [$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# --- Step 1: Install systemd (if missing) ---
ensure_systemd() {
  if ! command -v systemctl >/dev/null; then
    log "Installing systemd..."
    apt-get install -y systemd
    log "Enabling systemd..."
    systemctl unmask systemd
  fi
}

# --- Step 2: Install Nginx ---
install_nginx() {
  if ! command -v nginx >/dev/null; then
    log "Installing Nginx..."
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx
  else
    log "Nginx already installed. Restarting..."
    systemctl restart nginx
  fi
}

# --- Step 3: Configure Nginx ---
configure_nginx() {
  log "Overwrite the default index file..."
  echo "<h1> Hello from nginx on Ubuntu + Lima!</h1>" > "$NGINX_INDEX"
  chown -R www-data:www-data "$NGINX_ROOT"
}

# --- Main Execution ---
main() {
  log "Starting provisioning..."
  apt-get update -qq
  ensure_systemd
  install_nginx
  configure_nginx
  log "✅ Provisioning completed successfully!"
}

main