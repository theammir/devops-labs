#!/usr/bin/env bash
# Run inside the NixOS installer (live ISO). Partitions /dev/vda, assembles
# /mnt/etc/nixos, runs nixos-install, then poweroffs.
set -euxo pipefail

REPO="${1:?usage: install-vm.sh <path-to-repo-root>}"
ARCH=$(uname -m)

# ---- partition + format -----------------------------------------------------
# Clear any stale filesystem signatures from prior attempts so the kernel's
# autoprobe doesn't latch onto e.g. an old FAT boot sector when we mount.
wipefs -a /dev/vda || true
case "$ARCH" in
  aarch64)
    # GPT + ESP + ext4 root (UEFI / systemd-boot)
    parted -s /dev/vda mklabel gpt
    parted -s /dev/vda mkpart ESP fat32 1MiB 512MiB
    parted -s /dev/vda set 1 esp on
    parted -s /dev/vda mkpart root ext4 512MiB 100%
    partprobe /dev/vda || true
    wipefs -a /dev/vda1 /dev/vda2 || true
    mkfs.fat -F32 -n ESP /dev/vda1
    mkfs.ext4 -F -L nixos-root /dev/vda2
    mount -t ext4 /dev/vda2 /mnt
    mkdir -p /mnt/boot
    mount -t vfat /dev/vda1 /mnt/boot
    ;;
  x86_64)
    # MBR + ext4 (BIOS / grub)
    parted -s /dev/vda mklabel msdos
    parted -s /dev/vda mkpart primary ext4 1MiB 100%
    parted -s /dev/vda set 1 boot on
    partprobe /dev/vda || true
    wipefs -a /dev/vda1 || true
    mkfs.ext4 -F -L nixos-root /dev/vda1
    mount -t ext4 /dev/vda1 /mnt
    ;;
  *) echo "unsupported guest arch: $ARCH"; exit 1 ;;
esac

# ---- assemble /etc/nixos ----------------------------------------------------
ETC=/mnt/etc/nixos
mkdir -p "$ETC/modules" "$ETC/mywebapp-src"

cp "$REPO/deploy/nixos/configuration.nix" "$ETC/configuration.nix"
cp "$REPO/deploy/nixos/mywebapp-pkg.nix"  "$ETC/mywebapp-pkg.nix"

cp "$REPO/nixos/common.nix"     "$ETC/modules/common.nix"
cp "$REPO/nixos/mywebapp.nix"   "$ETC/modules/mywebapp.nix"
cp "$REPO/nixos/postgresql.nix" "$ETC/modules/postgresql.nix"
cp "$REPO/nixos/nginx.nix"      "$ETC/modules/nginx.nix"

# python source for derivation
cp -r "$REPO/mywebapp/." "$ETC/mywebapp-src/"
# strip dev-only state
rm -rf "$ETC/mywebapp-src/.venv" "$ETC/mywebapp-src/.ruff_cache" "$ETC/mywebapp-src/__pycache__"

# runtime app config
cp "$REPO/mywebapp/config.example.toml" "$ETC/config.toml"

# ---- install ----------------------------------------------------------------
nixos-install --no-root-passwd --root /mnt

poweroff
