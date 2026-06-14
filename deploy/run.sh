#!/usr/bin/env bash
# Boot the installed qcow2 with port forwards (8080→80, 2222→22).
set -euo pipefail

DISK="${DISK:-./nixos.qcow2}"
MEM="${MEM:-2048}"
SMP="${SMP:-2}"
[ -f "$DISK" ] || { echo "disk not found: $DISK (run ./deploy/setup.sh first)"; exit 1; }

HOST_OS=$(uname -s)
HOST_ARCH=$(uname -m)

case "$HOST_ARCH" in
  arm64|aarch64) QARCH=aarch64; MACHINE="virt,gic-version=max" ;;
  x86_64|amd64)  QARCH=x86_64;  MACHINE="q35" ;;
  *) echo "unsupported host arch: $HOST_ARCH"; exit 1 ;;
esac

QEMU="qemu-system-${QARCH}"
command -v "$QEMU" >/dev/null || { echo "$QEMU not in PATH"; exit 1; }

case "$HOST_OS" in
  Darwin) ACCEL=hvf; CPU=host ;;
  Linux)  [ -r /dev/kvm ] && { ACCEL=kvm; CPU=host; } || { ACCEL=tcg; CPU=max; } ;;
  *)      ACCEL=tcg; CPU=max ;;
esac
MACHINE="${MACHINE},accel=${ACCEL}"

FW_ARGS=()
if [ "$QARCH" = aarch64 ]; then
  fw_candidates=(
    "${FW:-}"
    "$(dirname "$(command -v "$QEMU")")/../share/qemu/edk2-aarch64-code.fd"
    "/opt/homebrew/share/qemu/edk2-aarch64-code.fd"
    "/usr/local/share/qemu/edk2-aarch64-code.fd"
    "/usr/share/qemu/edk2-aarch64-code.fd"
    "/usr/share/AAVMF/AAVMF_CODE.fd"
    "/usr/share/edk2/aarch64/QEMU_EFI.silent.fd"
  )
  FW_PATH=""
  for c in "${fw_candidates[@]}"; do
    [ -n "$c" ] && [ -f "$c" ] && FW_PATH="$c" && break
  done
  [ -z "$FW_PATH" ] && { echo "aarch64 UEFI firmware not found; set FW=<path>"; exit 1; }
  FW_ARGS=(-bios "$FW_PATH")
fi

exec "$QEMU" \
  -machine "$MACHINE" -cpu "$CPU" \
  -m "$MEM" -smp "$SMP" \
  "${FW_ARGS[@]}" \
  -drive "if=virtio,format=qcow2,file=$DISK" \
  -device virtio-net-pci,netdev=n \
  -netdev "user,id=n,hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:80" \
  -serial mon:stdio -nographic
