#!/usr/bin/env bash
#
# 7_install_yay.sh - Build and install yay-bin from the AUR.
#
# MUST be run as a normal user (a member of the wheel group with working
# sudo), NOT as root. makepkg refuses to run as root, and even if it
# didn't, building AUR packages as root is a well-known footgun.
#
# Run inside the chroot as the user created by 3_configure_base.sh:
#     su - <username>
#     cd /home/postinstall
#     ./7_install_yay.sh
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

die() { echo "Error: $*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Preconditions
# ---------------------------------------------------------------------------

# The big one: makepkg will exit immediately with "Running makepkg as root
# is not allowed" if we get this far as root. Catch it early with a clear
# message instead of letting the tool produce its own confusing error.
(( EUID != 0 )) || die "must be run as a normal user, not root"

command -v git     >/dev/null || die "git is required (pacman -S git)"
command -v makepkg >/dev/null || die "makepkg is required (pacman -S base-devel)"
command -v sudo    >/dev/null || die "sudo is required to install the built package"

# makepkg -si needs passwordless (or password-ful) sudo. We can't test the
# password here, but we can at least verify sudo exists and the user is
# allowed to use it.
sudo -n true 2>/dev/null || true   # best-effort; password prompt is fine

# ---------------------------------------------------------------------------
# Work directory
# ---------------------------------------------------------------------------
# Build in a scratch directory under the user's home. Avoids polluting
# $PWD (which may be /home/postinstall, a repo we don't want to dirty)
# and keeps everything within the user's own filesystem permissions.

BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/yay-bin.XXXXXX")"
trap 'rm -rf -- "$BUILD_DIR"' EXIT

echo "#>> Building yay-bin in $BUILD_DIR"

# ---------------------------------------------------------------------------
# Fetch
# ---------------------------------------------------------------------------

echo "#>> Cloning https://aur.archlinux.org/yay-bin.git"
git clone --depth=1 https://aur.archlinux.org/yay-bin.git "$BUILD_DIR"

# ---------------------------------------------------------------------------
# Build and install
# ---------------------------------------------------------------------------
# makepkg -s  : install missing (repo) dependencies via pacman
# makepkg -i  : install the built package via pacman -U
# Both need sudo. base-devel is not in the dependency list because every
# Arch install script assumes it's already present.

echo "#>> Running makepkg -si"
( cd "$BUILD_DIR" && makepkg -si )

# ---------------------------------------------------------------------------
# Verify
# ---------------------------------------------------------------------------

command -v yay >/dev/null || die "yay was not installed"

echo
echo "#>> yay installed: $(yay --version | head -n1)"
echo "#>> Next: ./8_cleanup.sh"
