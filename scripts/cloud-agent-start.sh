#!/usr/bin/env bash
# Per-boot runtime for the Bonuses Cloud Agent environment.
# Starts a secret service so Linux secure storage can persist demo passwords.
# The Flutter desktop app is launched by the agent when it is needed.
set -euo pipefail

export PATH="/opt/flutter/bin:${PATH}"

if ! command -v gnome-keyring-daemon >/dev/null 2>&1; then
  echo "gnome-keyring-daemon is not installed; skipping secret service."
  exit 0
fi

if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
  if [[ -n "${XDG_RUNTIME_DIR:-}" && -S "${XDG_RUNTIME_DIR}/bus" ]]; then
    export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"
  else
    eval "$(dbus-launch --sh-syntax)"
  fi
fi

if pgrep -u "$(id -u)" -f "gnome-keyring-daemon" >/dev/null 2>&1; then
  echo "gnome-keyring-daemon is already running."
  exit 0
fi

mkdir -p "${HOME}/.local/share/keyrings"
printf '\n' | gnome-keyring-daemon --unlock --components=secrets >/tmp/gnome-keyring.env 2>/dev/null || true
gnome-keyring-daemon --start --components=secrets >>/tmp/gnome-keyring.log 2>&1 || true
echo "Secret service start attempted."
