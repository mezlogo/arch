#!/usr/bin/env bash
#
# 5_config_network.sh - Install systemd-networkd .network files and
#                       enable the network stack: systemd-networkd for
#                       link/DHCP management, systemd-resolved for DNS,
#                       iwd for wireless authentication. Run inside the
#                       chroot after 3_configure_base.sh.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

die() { echo "Error: $*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Preconditions
# ---------------------------------------------------------------------------

(( EUID == 0 )) || die "must be run as root"

[[ -d /etc/systemd ]] \
    || die "this script must be run inside the installed system (arch-chroot)"

# ---------------------------------------------------------------------------
# Install .network files
# ---------------------------------------------------------------------------
# Note the explicit "$SCRIPT_DIR" — the original used a bare glob
# (`cp *.network ...`), which silently copied nothing when the script
# was invoked from any directory other than the repo root.

shopt -s nullglob
network_files=("$SCRIPT_DIR"/*.network)
shopt -u nullglob

(( ${#network_files[@]} > 0 )) \
    || die "no *.network files found next to $SCRIPT_DIR"

echo "#>> Installing .network files:"
for f in "${network_files[@]}"; do
    echo "    $(basename "$f")"
    install -m 0644 -- "$f" /etc/systemd/network/
done

# ---------------------------------------------------------------------------
# iwd: let systemd-networkd do DHCP, iwd only authenticates
# ---------------------------------------------------------------------------
# Out of the box iwd manages IP configuration for the interfaces it
# controls, which fights with systemd-networkd. Turning that off makes
# iwd a pure 802.11 supplicant: it associates and authenticates, then
# hands the link to systemd-networkd, which reads 25-wireless.network
# and runs DHCP.

echo "#>> Configuring iwd to defer IP configuration to systemd-networkd"
mkdir -p /etc/iwd
cat > /etc/iwd/main.conf <<'EOF'
[General]
EnableNetworkConfiguration=false
EOF

# ---------------------------------------------------------------------------
# resolv.conf -> resolved stub
# ---------------------------------------------------------------------------

echo "#>> Pointing /etc/resolv.conf at systemd-resolved stub"
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# ---------------------------------------------------------------------------
# Enable services
# ---------------------------------------------------------------------------

echo "#>> Enabling network services"
systemctl enable systemd-networkd.service
systemctl enable systemd-resolved.service
systemctl enable iwd.service

# ---------------------------------------------------------------------------
# NTP
# ---------------------------------------------------------------------------

echo "#>> Enabling NTP"
timedatectl set-ntp true

# ---------------------------------------------------------------------------
# Do NOT block boot on network-online.target
# ---------------------------------------------------------------------------
# The original script ran `systemctl mask network-online.target`, which
# breaks *every* service that depends on it (sshd, pacman-init,
# systemd-networkd-wait-online, ...). The intent was almost certainly
# "don't stall boot waiting for the network". The correct way to say
# that is to disable the wait-online helper, not to mask the target
# that other units pull in.

echo "#>> Making network-online.target non-blocking"
systemctl disable systemd-networkd-wait-online.service 2>/dev/null || true

# ---------------------------------------------------------------------------
# Make sure systemd-networkd doesn't try to manage wlan itself when iwd
# is in use — with EnableNetworkConfiguration=false this is a no-op,
# but keeping iwd out of "unmanaged" mode is worth stating explicitly.
# Nothing to do here; listed for documentation purposes.
# ---------------------------------------------------------------------------

echo
echo "#>> Network configuration complete."
echo "#>> Verify after first boot with:"
echo "     networkctl status"
echo "     resolvectl status"
echo "     iwctl station <dev> show"
