#!/usr/bin/env bash
#
# 2_copy_repo_and_chroot.sh - Copy this repository into the freshly
#                             installed system and drop the operator
#                             into an arch-chroot so the post-install
#                             scripts can be run from inside the target.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_ROOT="${TARGET_ROOT:-/mnt}"
POSTINSTALL_DIR="${TARGET_ROOT}/home/postinstall"

die() { echo "Error: $*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Preconditions
# ---------------------------------------------------------------------------

(( EUID == 0 )) || die "must be run as root"

mountpoint -q "$TARGET_ROOT" \
    || die "$TARGET_ROOT is not a mountpoint; run 1_install_base.sh first"

[[ -f "${TARGET_ROOT}/etc/os-release" ]] \
    || die "$TARGET_ROOT does not look like an installed Arch root"

command -v arch-chroot >/dev/null \
    || die "arch-chroot not found; install arch-install-scripts"

# ---------------------------------------------------------------------------
# Idempotent copy
# ---------------------------------------------------------------------------

if [[ -e "$POSTINSTALL_DIR" ]]; then
    echo "Warning: $POSTINSTALL_DIR already exists."
    read -rp "Remove and re-copy? [y/N] " ans
    [[ "${ans,,}" == "y" ]] || die "aborted"
    rm -rf -- "$POSTINSTALL_DIR"
fi

mkdir -p -- "$POSTINSTALL_DIR"

# ---------------------------------------------------------------------------
# Copy repository contents (not the containing directory)
# ---------------------------------------------------------------------------
# The original `cp -r "$SCRIPT_DIR" "$DEST"` would create
# "$DEST/$(basename "$SCRIPT_DIR")", so the scripts ended up at
# /home/postinstall/<repo-name>/ instead of /home/postinstall/.
# Copying "$SCRIPT_DIR/." places the *contents* of the repo directly
# into $POSTINSTALL_DIR. `-a` preserves permissions, ownership and
# timestamps — important for the executable bit on the scripts.

echo "#>> Copying repo from $SCRIPT_DIR to $POSTINSTALL_DIR"
cp -a -- "$SCRIPT_DIR/." "$POSTINSTALL_DIR/"

# Belt and braces: make sure every script is executable, regardless of
# how the repo was checked out (some archive extractors drop +x).
chmod +x -- "$POSTINSTALL_DIR"/*.sh 2>/dev/null || true

echo "#>> Copied files:"
(cd "$POSTINSTALL_DIR" && ls -1)

# ---------------------------------------------------------------------------
# Drop into the chroot
# ---------------------------------------------------------------------------

cat <<EOF

#>> Entering arch-chroot in $TARGET_ROOT
#>> Next, inside the chroot:
#>>   cd /home/postinstall
#>>   ./3_configure_base.sh [-ai] <hostname> <root_partition> <username>

EOF

exec arch-chroot "$TARGET_ROOT"
