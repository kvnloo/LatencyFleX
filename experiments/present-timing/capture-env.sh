#!/usr/bin/env bash
set -u

out="${1:-lfx-present-timing-env-$(date +%Y%m%d-%H%M%S).txt}"

run() {
  printf '\n$ %s\n' "$*"
  "$@" 2>&1 || true
}

{
  printf 'captured_at='
  date --iso-8601=seconds
  run git rev-parse HEAD
  run uname -a
  run cat /etc/os-release
  run nvidia-smi
  run vulkaninfo --summary
  printf '\n$ vulkaninfo extension checks\n'
  vulkaninfo 2>/dev/null | grep -E 'VK_EXT_present_timing|VK_KHR_present_wait2?|VK_KHR_present_id2?|VK_NV_low_latency2?' || true
  run hyprctl version
  run hyprctl monitors -j
  run loginctl show-session "${XDG_SESSION_ID:-}" -p Type -p Desktop -p Remote
} > "$out"

printf 'wrote %s\n' "$out"
