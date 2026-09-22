#!/usr/bin/env bash
#
# 8_cleanup.sh - Final cleanup after a successful install:
#                  * remove the copied repository at /home/postinstall
#                  * prune the pacman and AUR helper package cache
#                  * remove orphaned packages
#                  * remove leftover *.pacnew / *.pacsave files
#
# Run as a normal user (the one created by 3_configure_base.sh), with
# sudo available, AFTER you have rebooted into the installed system and
# confirmed everything works.
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

die()  { echo "Error: $*" >&2; exit 1; }
info() { echo "#>> $*"; }

confirm() {
    local prompt="$1" ans
    read -rp "$prompt [y/N] " ans
    [[ "${ans,,}" == "y" ]]
}

# ---------------------------------------------------------------------------
# Preconditions
# ---------------------------------------------------------------------------
# This script wipes the install repo. If it's run inside the ISO's
# /mnt chroot before rebooting, the operator loses their only copy of
# the scripts on the target system. Require the user to run it as a
# regular login, not root, and not from inside an arch-chroot of a
# still-mounted install.

(( EUID != 0 )) || die "must be run as a normal user, not root"

# The install repo lives here per 2_copy_repo_and_chroot.sh. If it isn't
# present, we're probably on the running system already (or running from
# the wrong place) -- bail out rather than deleting something else.
REPO_DIR="/home/postinstall"

# ---------------------------------------------------------------------------
# Confirmation
# ---------------------------------------------------------------------------

cat <<EOF
This will:
  1. Delete $REPO_DIR
  2. Remove orphaned packages
  3. Clear the pacman package cache (sudo)
  4. Clear the yay package cache
  5. Remove *.pacnew / *.pacsave files (sudo)

It will NOT touch anything else in your home directory.
EOF

confirm "Proceed?" || die "aborted by user"

# ---------------------------------------------------------------------------
# 1. Remove the install repo
# ---------------------------------------------------------------------------

if [[ -d "$REPO_DIR" ]]; then
    info "Removing $REPO_DIR"
    sudo rm -rf -- "$REPO_DIR"
else
    info "$REPO_DIR does not exist, skipping"
fi

# ---------------------------------------------------------------------------
# 2. Remove orphaned packages
# ---------------------------------------------------------------------------
# An orphan is a package installed as a dependency that is no longer
# required by anything. Requires no confirmation per-package: the list
# is printed first so the operator can see what will go.

info "Checking for orphaned packages"
mapfile -t ORPHANS < <(pacman -Qtdq 2>/dev/null || true)

if (( ${#ORPHANS[@]} > 0 )); then
    printf '    %s\n' "${ORPHANS[@]}"
    if confirm "Remove these ${#ORPHANS[@]} orphan(s)?"; then
        sudo pacman -Rns --noconfirm -- "${ORPHANS[@]}"
    else
        info "skipping orphan removal"
    fi
else
    info "no orphans found"
fi

# ---------------------------------------------------------------------------
# 3. Clear pacman cache
# ---------------------------------------------------------------------------
# `pacman -Scc` removes every cached package and the sync databases.
# Use --noconfirm because pacman's own prompt is easy to misread.
# If you'd rather keep the last N versions of each package, use
# `paccache -rk1` from pacman-contrib instead.

if confirm "Clear the entire pacman cache (sudo)?"; then
    info "Clearing pacman cache"
    sudo pacman -Scc --noconfirm
else
    info "skipping pacman cache cleanup"
fi

# ---------------------------------------------------------------------------
# 4. Clear yay cache
# ---------------------------------------------------------------------------
# yay-bin (installed by 7_install_yay.sh) provides `yay -Scc` which
# cleans both the pacman cache and yay's own AUR build cache. If yay
# isn't installed, fall back to removing the cache directories directly.

if command -v yay >/dev/null 2>&1; then
    if confirm "Clear the yay / AUR build cache?"; then
        info "Clearing yay cache"
        yay -Scc --noconfirm
    else
        info "skipping yay cache cleanup"
    fi
else
    info "yay not found; removing known AUR cache directories"
    rm -rf -- "${XDG_CACHE_HOME:-$HOME/.cache}/yay" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# 5. *.pacnew / *.pacsave
# ---------------------------------------------------------------------------
# When pacman installs a package whose config file has been modified
# locally, it drops a .pacnew alongside the original instead of
# overwriting it. Removing them silently is wrong -- the operator may
# need to merge changes. We only *list* them here.

info "Scanning for *.pacnew / *.pacsave files"
mapfile -t PNEW < <(sudo find /etc -name '*.pacnew' -o -name '*.pacsave' 2>/dev/null || true)

if (( ${#PNEW[@]} > 0 )); then
    echo "    The following files need manual review:"
    printf '        %s\n' "${PNEW[@]}"
    echo "    See: https://wiki.archlinux.org/title/Pacman/Pacnew_and_Pacsave"
else
    info "none found"
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------

echo
echo "#>> Cleanup complete."
echo "#>> It is now safe to remove the installation media and reboot."
