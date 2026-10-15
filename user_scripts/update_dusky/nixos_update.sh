#!/usr/bin/env bash
# =============================================================================
# nixos_update.sh — NixOS System Updater
# Equivalent of system_update.sh, adapted for NixOS + Nix Flakes.
#
# Usage:
#   nixos_update.sh -s | --system     Rebuild system only (nixos-rebuild switch)
#   nixos_update.sh -f | --flake      Update flake inputs only (nix flake update)
#   nixos_update.sh -A | --all        Flake update + nixos-rebuild switch
#   nixos_update.sh -H | --home       Apply home-manager only (home-manager switch)
#   nixos_update.sh -d | --dry        Dry-build only (no system changes)
#   nixos_update.sh -h | --help       Show this help
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# Prevent execution as root
if (( EUID == 0 )); then
    printf "\e[38;5;196m[ERROR]\e[0m This script must not be run as root. Execute as a standard user.\n" >&2
    exit 1
fi

# Terminal colors
declare -r C_RESET=$'\e[0m'
declare -r C_INFO=$'\e[38;5;111m'
declare -r C_SUCCESS=$'\e[38;5;114m'
declare -r C_WARN=$'\e[38;5;214m'
declare -r C_ERR=$'\e[38;5;196m'
declare -r C_STEP=$'\e[38;5;81m'

# State
declare -i OPT_SYSTEM=0
declare -i OPT_FLAKE=0
declare -i OPT_HOME=0
declare -i OPT_DRY=0
declare -r MAIN_PID=$$
declare SUDO_PID=0

# Flake path — assumes script is in ~/dusky/user_scripts/update_dusky/
FLAKE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FLAKE_HOST="dusky"
FLAKE_USER="plancton"

# Logging
log_info()    { printf "%b[INFO]%b  %s\n"    "$C_INFO"    "$C_RESET" "$1"; }
log_step()    { printf "%b[STEP]%b  %s\n"    "$C_STEP"    "$C_RESET" "$1"; }
log_success() { printf "%b[OK]%b    %s\n"    "$C_SUCCESS" "$C_RESET" "$1"; }
log_warn()    { printf "%b[WARN]%b  %s\n"    "$C_WARN"    "$C_RESET" "$1" >&2; }
log_err()     { printf "%b[ERROR]%b %s\n"    "$C_ERR"     "$C_RESET" "$1" >&2; }
die()         { log_err "$1"; exit 1; }

show_help() {
    cat <<EOF
Usage: ${0##*/} [OPTIONS]

NixOS system updater using Nix Flakes.
Flake directory: ${FLAKE_DIR}

Options:
  -s, --system    Rebuild system only       (sudo nixos-rebuild switch --flake .#${FLAKE_HOST})
  -f, --flake     Update flake inputs only  (nix flake update)
  -H, --home      Apply Home Manager only   (home-manager switch --flake .#${FLAKE_USER})
  -A, --all       Full update: flake update + nixos-rebuild switch
  -d, --dry       Dry build (no changes)    (sudo nixos-rebuild dry-build --flake .#${FLAKE_HOST})
  -h, --help      Show this help message
EOF
}

if (( $# == 0 )); then
    show_help
    exit 1
fi

while (( $# > 0 )); do
    case "$1" in
        -s|--system) OPT_SYSTEM=1 ;;
        -f|--flake)  OPT_FLAKE=1 ;;
        -H|--home)   OPT_HOME=1 ;;
        -A|--all)    OPT_SYSTEM=1; OPT_FLAKE=1 ;;
        -d|--dry)    OPT_DRY=1 ;;
        -h|--help)   show_help; exit 0 ;;
        *) die "Invalid argument: $1. Use --help for usage." ;;
    esac
    shift
done

# Validate flake directory
[[ -f "${FLAKE_DIR}/flake.nix" ]] || die "flake.nix not found in ${FLAKE_DIR}. Is FLAKE_DIR correct?"

# ---------------------------------------------------------
# Sudo Keep-Alive (same pattern as system_update.sh)
# ---------------------------------------------------------
trap 'die "Update aborted: Sudo credentials expired unexpectedly."' USR1

keep_sudo_alive() {
    local sleep_pid=0
    trap '(( sleep_pid > 0 )) && kill "$sleep_pid" 2>/dev/null || true; exit 0' TERM
    while sudo -nv 2>/dev/null; do
        sleep 60 &
        sleep_pid=$!
        wait "$sleep_pid" || true
        sleep_pid=0
    done
    kill -USR1 "$MAIN_PID" 2>/dev/null || true
}

cleanup() {
    if (( SUDO_PID > 0 )); then
        kill -TERM "$SUDO_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT

# Acquire sudo if needed
if (( OPT_SYSTEM == 1 || OPT_DRY == 1 )); then
    log_info "Acquiring sudo privileges..."
    sudo -v || die "Sudo authentication failed or was cancelled."
    keep_sudo_alive &
    SUDO_PID=$!
fi

# ---------------------------------------------------------
# Execution
# ---------------------------------------------------------
log_info "Starting NixOS update sequence (flake: ${FLAKE_DIR})..."

pushd "$FLAKE_DIR" > /dev/null

if (( OPT_FLAKE == 1 )); then
    log_step "Updating flake inputs..."
    nix flake update
    log_success "Flake inputs updated."
fi

if (( OPT_DRY == 1 )); then
    log_step "Dry-build: sudo nixos-rebuild dry-build --flake .#${FLAKE_HOST}"
    sudo nixos-rebuild dry-build --flake ".#${FLAKE_HOST}"
    log_success "Dry-build completed. No changes applied."
    popd > /dev/null
    exit 0
fi

if (( OPT_SYSTEM == 1 )); then
    log_step "Rebuilding NixOS system: sudo nixos-rebuild switch --flake .#${FLAKE_HOST}"
    sudo nixos-rebuild switch --flake ".#${FLAKE_HOST}"
    log_success "NixOS system rebuild completed."
fi

if (( OPT_HOME == 1 )); then
    log_step "Applying Home Manager: home-manager switch --flake .#${FLAKE_USER}"
    home-manager switch --flake ".#${FLAKE_USER}"
    log_success "Home Manager switch completed."
fi

popd > /dev/null
log_success "Update sequence finished successfully."
