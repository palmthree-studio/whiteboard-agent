#!/usr/bin/env bash
# install.sh — Whiteboard Agent installer (Wendy mascot + auth + binary)
# Usage: curl -fsSL https://raw.githubusercontent.com/palmthree-studio/whiteboard-agent/master/install.sh | bash

set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# ANSI colors (fallback if terminal does not support them)
# ─────────────────────────────────────────────────────────────────────────────

if [[ -n "${NO_COLOR:-}" ]] || [[ "${TERM:-dumb}" == "dumb" ]] || [[ ! -t 1 ]]; then
  C_RESET=""
  C_VIOLET=""
  C_BLUE=""
  C_RED=""
  C_GREEN=""
  C_YELLOW=""
  C_BOLD=""
  C_DIM=""
else
  C_RESET=$'\033[0m'
  C_VIOLET=$'\033[1;35m'
  C_BLUE=$'\033[1;36m'
  C_RED=$'\033[1;31m'
  C_GREEN=$'\033[1;32m'
  C_YELLOW=$'\033[1;33m'
  C_BOLD=$'\033[1m'
  C_DIM=$'\033[2m'
fi

# ─────────────────────────────────────────────────────────────────────────────
# Wendy animation — 4 frames
# ─────────────────────────────────────────────────────────────────────────────

clear_lines() {
  local n="$1"
  for ((i = 0; i < n; i++)); do
    printf '\033[1A\033[2K'
  done
}

# Frame 1 — face-on stack: yellow ticket in the foreground, edges of others peeking behind
frame_1() {
  printf '\n'
  printf '             %s┌─%s%s┐%s%s┐%s%s┐%s%s┐%s\n' \
    "$C_VIOLET" "$C_RESET" "$C_BLUE" "$C_RESET" "$C_RED" "$C_RESET" "$C_GREEN" "$C_RESET" "$C_YELLOW" "$C_RESET"
  printf '             %s│ %s│%s│%s│%s│%s│%s│%s          %s│%s\n' \
    "$C_VIOLET" "$C_BLUE" "$C_RED" "$C_GREEN" "$C_RESET" "$C_YELLOW" "$C_RESET" "$C_RESET" "$C_YELLOW" "$C_RESET"
  printf '             %s│ %s│%s│%s│%s│%s│%s│%s          %s│%s\n' \
    "$C_VIOLET" "$C_BLUE" "$C_RED" "$C_GREEN" "$C_RESET" "$C_YELLOW" "$C_RESET" "$C_RESET" "$C_YELLOW" "$C_RESET"
  printf '             %s│ %s│%s│%s│%s│%s│%s│%s          %s│%s\n' \
    "$C_VIOLET" "$C_BLUE" "$C_RED" "$C_GREEN" "$C_RESET" "$C_YELLOW" "$C_RESET" "$C_RESET" "$C_YELLOW" "$C_RESET"
  printf '             %s└─%s└─%s└─%s└──────────┘%s\n' \
    "$C_VIOLET" "$C_BLUE" "$C_RED" "$C_GREEN$C_YELLOW" "$C_RESET"
  printf '\n'
}

# Frame 2 — face drawing itself on the yellow ticket
frame_2() {
  printf '\n'
  printf '             %s┌─%s%s┐%s%s┐%s%s┐%s%s┐%s\n' \
    "$C_VIOLET" "$C_RESET" "$C_BLUE" "$C_RESET" "$C_RED" "$C_RESET" "$C_GREEN" "$C_RESET" "$C_YELLOW" "$C_RESET"
  printf '             %s│ %s│%s│%s│%s│%s│%s│%s  %s◉%s    %s◉%s   %s│%s\n' \
    "$C_VIOLET" "$C_BLUE" "$C_RED" "$C_GREEN" "$C_RESET" "$C_YELLOW" "$C_RESET" "$C_BOLD" "$C_RESET" "$C_BOLD" "$C_RESET" "$C_YELLOW" "$C_RESET"
  printf '             %s│ %s│%s│%s│%s│%s│%s│%s          %s│%s\n' \
    "$C_VIOLET" "$C_BLUE" "$C_RED" "$C_GREEN" "$C_RESET" "$C_YELLOW" "$C_RESET" "$C_RESET" "$C_YELLOW" "$C_RESET"
  printf '             %s│ %s│%s│%s│%s│%s│%s│%s   ──────  %s│%s\n' \
    "$C_VIOLET" "$C_BLUE" "$C_RED" "$C_GREEN" "$C_RESET" "$C_YELLOW" "$C_RESET" "$C_RESET" "$C_YELLOW" "$C_RESET"
  printf '             %s└─%s└─%s└─%s└──────────┘%s\n' \
    "$C_VIOLET" "$C_BLUE" "$C_RED" "$C_GREEN$C_YELLOW" "$C_RESET"
  printf '\n'
}

# Frame 3 — cards start sliding out from behind
frame_3() {
  printf '\n'
  printf '         %s┌──┐%s    %s┌──┐%s\n' "$C_VIOLET" "$C_RESET" "$C_BLUE" "$C_RESET"
  printf '         %s│  │%s    %s│  │%s    %s┌──────────┐%s\n' "$C_VIOLET" "$C_RESET" "$C_BLUE" "$C_RESET" "$C_YELLOW" "$C_RESET"
  printf '   %s┌──┐%s%s└──┘%s    %s└──┘%s    %s│ %s◉%s    %s◉%s   %s│%s   %s┌──┐%s\n' \
    "$C_RED" "$C_RESET" "$C_VIOLET" "$C_RESET" "$C_BLUE" "$C_RESET" "$C_YELLOW" "$C_BOLD" "$C_RESET" "$C_BOLD" "$C_RESET" "$C_YELLOW" "$C_RESET" "$C_GREEN" "$C_RESET"
  printf '   %s│  │%s              %s│          │%s   %s│  │%s\n' "$C_RED" "$C_RESET" "$C_YELLOW" "$C_RESET" "$C_GREEN" "$C_RESET"
  printf '   %s└──┘%s              %s│   ──────  │%s   %s└──┘%s\n' "$C_RED" "$C_RESET" "$C_YELLOW" "$C_RESET" "$C_GREEN" "$C_RESET"
  printf '                         %s└──────────┘%s\n' "$C_YELLOW" "$C_RESET"
  printf '\n'
}

# Frame 4 — Wendy complete, arms raised
frame_4() {
  printf '\n'
  printf '       %s┌──────┐%s          %s┌──────┐%s\n' "$C_VIOLET" "$C_RESET" "$C_BLUE" "$C_RESET"
  printf '       %s│  /\\  │%s          %s│  /\\  │%s\n' "$C_VIOLET" "$C_RESET" "$C_BLUE" "$C_RESET"
  printf '       %s│ /  \\ │%s          %s│ /  \\ │%s\n' "$C_VIOLET" "$C_RESET" "$C_BLUE" "$C_RESET"
  printf '       %s└──────┘%s          %s└──────┘%s\n' "$C_VIOLET" "$C_RESET" "$C_BLUE" "$C_RESET"
  printf '                %s┌──────────────┐%s\n' "$C_YELLOW" "$C_RESET"
  printf '   %s┌──────┐%s   %s│  %s◉%s        %s◉%s    │%s   %s┌──────┐%s\n' \
    "$C_RED" "$C_RESET" "$C_YELLOW" "$C_BOLD" "$C_RESET" "$C_BOLD" "$C_RESET" "$C_YELLOW" "$C_RESET" "$C_GREEN" "$C_RESET"
  printf '   %s│      │%s   %s│              │%s   %s│      │%s\n' "$C_RED" "$C_RESET" "$C_YELLOW" "$C_RESET" "$C_GREEN" "$C_RESET"
  printf '   %s│ Wendy│%s   %s│   ────────   │%s   %s│  Hi! │%s\n' "$C_RED" "$C_RESET" "$C_YELLOW" "$C_RESET" "$C_GREEN" "$C_RESET"
  printf '   %s└──────┘%s   %s└──────────────┘%s   %s└──────┘%s\n' "$C_RED" "$C_RESET" "$C_YELLOW" "$C_RESET" "$C_GREEN" "$C_RESET"
  printf '\n'
}

ascii_title() {
  printf '\n'
  printf '%s        _     _ _       _                         _                                _   %s\n' "$C_BOLD" "$C_RESET"
  printf '%s __   _| |__ (_) |_ ___| |__   ___   __ _ _ __ __| |    __ _  __ _  ___ _ __  _ __| |_ %s\n' "$C_BOLD" "$C_RESET"
  printf '%s \\ \\ / / `_ \\| | __/ _ \\ `_ \\ / _ \\ / _` | `__/ _` |   / _` |/ _` |/ _ \\ `_ \\| `__| __|%s\n' "$C_BOLD" "$C_RESET"
  printf '%s  \\ V /| | | | | ||  __/ |_) | (_) | (_| | | | (_| |  | (_| | (_| |  __/ | | | |  | |_ %s\n' "$C_BOLD" "$C_RESET"
  printf '%s   \\_/ |_| |_|_|\\__\\___|_.__/ \\___/ \\__,_|_|  \\__,_|___\\__,_|\\__, |\\___|_| |_|_|   \\__|%s\n' "$C_BOLD" "$C_RESET"
  printf '%s                                                  |_____|     |___/                    %s\n' "$C_BOLD" "$C_RESET"
  printf '\n'
}

play_animation() {
  frame_1
  sleep 0.6
  clear_lines 8
  frame_2
  sleep 0.6
  clear_lines 8
  frame_3
  sleep 0.6
  clear_lines 8
  frame_4
  sleep 0.4
}

# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────


info() { printf '%s>%s %s\n' "$C_BLUE" "$C_RESET" "$1"; }
ok()   { printf '%s✓%s %s\n' "$C_GREEN" "$C_RESET" "$1"; }
warn() { printf '%s!%s %s\n' "$C_YELLOW" "$C_RESET" "$1" >&2; }
err()  { printf '%s✗%s %s\n' "$C_RED" "$C_RESET" "$1" >&2; }

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    err "Command \`$1\` is required but not found."
    exit 1
  fi
}

ask_password() {
  local prompt="$1"
  local var
  printf '%s' "$prompt"
  stty -echo
  IFS= read -r var
  stty echo
  printf '\n'
  echo "$var"
}

hash_password() {
  # SHA256 hex (bash-compatible, no bcrypt needed). Server compares using SHA256.
  local pw="$1"
  if command -v openssl >/dev/null 2>&1; then
    printf '%s' "$pw" | openssl dgst -sha256 | awk '{print $NF}'
  elif command -v shasum >/dev/null 2>&1; then
    printf '%s' "$pw" | shasum -a 256 | awk '{print $1}'
  else
    err "No tool available to hash password (openssl/shasum missing)."
    exit 1
  fi
}

detect_asset() {
  local os arch
  os="$(uname -s)"
  arch="$(uname -m)"
  case "$os" in
    Darwin)
      case "$arch" in
        arm64|aarch64) echo "companion-macos-arm64" ;;
        x86_64) echo "companion-macos-x64" ;;
        *) err "Unsupported macOS architecture: $arch"; exit 1 ;;
      esac
      ;;
    Linux)
      case "$arch" in
        x86_64|amd64) echo "companion-linux-x64" ;;
        *) err "Unsupported Linux architecture: $arch"; exit 1 ;;
      esac
      ;;
    MINGW*|MSYS*|CYGWIN*)
      echo "companion-windows-x64.exe"
      ;;
    *)
      err "Unsupported OS: $os"
      exit 1
      ;;
  esac
}

# ─────────────────────────────────────────────────────────────────────────────
# Main flow
# ─────────────────────────────────────────────────────────────────────────────

main() {
  require_cmd curl
  require_cmd uname

  play_animation
  ascii_title

  printf '%sWelcome to Whiteboard Agent.%s\n' "$C_BOLD" "$C_RESET"
  printf 'Wendy will guide you through setting up your local companion.\n\n'

  # ── Cloudflare Tunnel ─────────────────────────────────────────────────────
  printf '%sCloudflare Tunnel required%s\n' "$C_BOLD" "$C_RESET"
  printf 'Whiteboard Agent exposes your companion on the internet via Cloudflare Tunnel.\n'
  printf 'Documentation: %shttps://developers.cloudflare.com/cloudflare-one/connections/connect-networks/get-started/%s\n\n' \
    "$C_BLUE" "$C_RESET"
  printf '%sPress Enter when your Cloudflare URL is ready…%s' "$C_DIM" "$C_RESET"
  read -r _

  # ── Public URL ────────────────────────────────────────────────────────────
  local companion_url
  while true; do
    printf '\n%sYour companion public URL%s (e.g. https://wb.example.com): ' "$C_BOLD" "$C_RESET"
    read -r companion_url
    if [[ "$companion_url" =~ ^https://[a-zA-Z0-9.-]+ ]]; then
      break
    fi
    warn "URL must start with https://"
  done

  # ── Username ──────────────────────────────────────────────────────────────
  local username
  printf '\n%sOwner username%s: ' "$C_BOLD" "$C_RESET"
  read -r username
  if [[ -z "$username" ]]; then
    err "Username cannot be empty."
    exit 1
  fi

  # ── Password ──────────────────────────────────────────────────────────────
  local pw1 pw2
  while true; do
    pw1="$(ask_password "${C_BOLD}Password${C_RESET}: ")"
    pw2="$(ask_password "${C_BOLD}Confirm password${C_RESET}: ")"
    if [[ "$pw1" == "$pw2" && -n "$pw1" ]]; then
      break
    fi
    warn "Passwords do not match (or empty). Try again."
  done

  local password_hash
  password_hash="$(hash_password "$pw1")"
  unset pw1 pw2

  # ── Asset detection + download ────────────────────────────────────────────
  local asset
  asset="$(detect_asset)"
  info "Detected asset: $asset"

  local install_dir="${WHITEBOARD_INSTALL_DIR:-$HOME/.whiteboard-agent}"
  mkdir -p "$install_dir"

  info "Fetching latest release…"
  local release_json
  release_json="$(curl -fsSL "https://api.github.com/repos/palmthree-studio/whiteboard-agent/releases/latest")"

  local download_url
  if command -v jq >/dev/null 2>&1; then
    download_url="$(printf '%s' "$release_json" | jq -r --arg n "$asset" '.assets[] | select(.name == $n) | .browser_download_url')"
  else
    # Fallback grep/sed without jq
    download_url="$(printf '%s' "$release_json" \
      | tr ',' '\n' \
      | grep -E '"browser_download_url"' \
      | grep -E "/${asset}\"" \
      | head -n1 \
      | sed -E 's/.*"(https:[^"]+)".*/\1/')"
  fi

  if [[ -z "$download_url" ]]; then
    err "Could not find asset $asset in the latest release."
    exit 1
  fi

  local binary_path="$install_dir/companion"
  if [[ "$asset" == *.exe ]]; then
    binary_path="$install_dir/companion.exe"
  fi

  info "Downloading $download_url"
  curl -fsSL "$download_url" -o "$binary_path"
  chmod +x "$binary_path"
  ok "Binary installed: $binary_path"

  # ── Generate whiteboard_agent.md ──────────────────────────────────────────
  local template_url="https://raw.githubusercontent.com/palmthree-studio/whiteboard-agent/master/scripts/whiteboard_agent_template.md"
  local md_path="$install_dir/whiteboard_agent.md"
  info "Generating $md_path"
  local template
  template="$(curl -fsSL "$template_url" 2>/dev/null || true)"
  if [[ -z "$template" ]]; then
    warn "Remote template unavailable — using minimal fallback."
    template="# Whiteboard Agent\n\nServer URL: \$COMPANION_URL/mcp\n"
  fi
  printf '%s\n' "${template//\$COMPANION_URL/$companion_url}" > "$md_path"
  ok "MCP config: $md_path"

  # ── Start companion ───────────────────────────────────────────────────────
  printf '\n%sStarting companion…%s\n' "$C_BOLD" "$C_RESET"
  printf '%sCtrl+C to stop.%s\n\n' "$C_DIM" "$C_RESET"

  printf '%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n' "$C_BOLD" "$C_RESET"
  printf '%s▸ Public URL%s       : %s\n' "$C_BOLD" "$C_RESET" "$companion_url"
  printf '%s▸ Username%s         : %s\n' "$C_BOLD" "$C_RESET" "$username"
  printf '%s▸ MCP config%s       : %s\n' "$C_BOLD" "$C_RESET" "$md_path"
  printf '%s▸ Binary%s           : %s\n' "$C_BOLD" "$C_RESET" "$binary_path"
  printf '%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n\n' "$C_BOLD" "$C_RESET"

  printf '%sWendy: "All set — happy brainstorming!"%s\n\n' "$C_YELLOW" "$C_RESET"

  COMPANION_URL="$companion_url" \
  COMPANION_USERNAME="$username" \
  COMPANION_PASSWORD_HASH="$password_hash" \
  exec "$binary_path"
}

main "$@"
