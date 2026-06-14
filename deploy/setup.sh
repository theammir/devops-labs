#!/usr/bin/env bash
# Boot NixOS installer ISO with empty qcow2 attached and repo shared via 9p.
# After install completes inside the VM, run ./run.sh.
set -euo pipefail

usage() {
  cat <<EOF
usage: $0 <path-to-nixos-iso>

env overrides:
  DISK=./nixos.qcow2   target disk image
  SIZE=8G              disk size if creating
  MEM=4096             RAM (MiB)
  SMP=2                vCPU count
  FW=<path>            UEFI firmware (aarch64 only; auto-detected if unset)
EOF
  exit 1
}

[ $# -eq 1 ] || usage
ISO="$1"
[ -f "$ISO" ] || { echo "iso not found: $ISO"; exit 1; }

DISK="${DISK:-./nixos.qcow2}"
SIZE="${SIZE:-8G}"
MEM="${MEM:-4096}"
SMP="${SMP:-2}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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

if [ ! -f "$DISK" ]; then
  echo "creating $DISK ($SIZE)"
  qemu-img create -f qcow2 "$DISK" "$SIZE"
fi

QEMU_ARGS=(
  -machine "$MACHINE" -cpu "$CPU"
  -m "$MEM" -smp "$SMP"
  "${FW_ARGS[@]}"
  -drive "if=virtio,format=qcow2,file=$DISK"
  -cdrom "$ISO" -boot d
  -device virtio-net-pci,netdev=n
  -netdev "user,id=n,hostfwd=tcp::2222-:22"
  -virtfs "local,path=$REPO_ROOT,mount_tag=repo,security_model=none,id=repo"
  -serial mon:stdio -nographic
)

# The stock installer ISO gives no host->guest control channel, so we spawn
# qemu under expect, wait for the installer shell, and send the install steps.
# Runs headless: the VM console is NOT shown; only the commands we issue are
# printed to stdout.
command -v expect >/dev/null || { echo "this script requires 'expect' in PATH"; exit 1; }
export DEBUG="${DEBUG:-0}"
[ "$DEBUG" = 0 ] && echo "Driving install headless... (DEBUG=1 to show the VM console)" \
                 || echo "Driving install (DEBUG: showing VM console)..."

DRIVER="$(mktemp -t setup-vm-XXXXXX.exp)"
trap 'rm -f "$DRIVER"' EXIT
cat >"$DRIVER" <<'EXP'
# argv = qemu binary + its args (passed by setup.sh)
# Match any NixOS shell prompt tail: "...]#" (root) or "...]$" (user). No
# trailing space: PS1 puts an ANSI color-reset escape between the $/# and the
# space, so "$ " never appears literally.
set prompt {\][#$]}

# Headless unless DEBUG: don't echo the VM console; print only commands we run.
if {[info exists env(DEBUG)] && $env(DEBUG) ne "0"} { log_user 1 } else { log_user 0 }
spawn {*}$argv

# Wait for the installer shell. The minimal ISO autologins (as root or nixos);
# if it instead shows a login: prompt, log in as root (no password).
set timeout 600
puts "\[setup\] waiting for installer shell..."
expect {
  -re {login: *$}       { send "root\r"; exp_continue }
  -re {[Pp]assword: *$} { send "\r"; exp_continue }
  -re $prompt {}
  timeout { puts stderr "\[setup\] timed out waiting for shell (retry with DEBUG=1 to see the console)"; exit 1 }
  eof     { puts stderr "\[setup\] qemu exited before shell"; exit 1 }
}

# Run a command in the guest, echoing it, and wait for the next prompt.
proc run {cmd} {
  global prompt
  puts "\[setup\] + $cmd"
  send "$cmd\r"
  expect {
    -re $prompt {}
    timeout { puts stderr "\[setup\] stalled: $cmd"; exit 1 }
  }
}

run "sudo mkdir -p /mnt-repo"
run "sudo mount -t 9p -o trans=virtio,version=9p2000.L repo /mnt-repo"

# Install is long (partition + nixos-install) and ends in poweroff -> eof.
puts "\[setup\] + sudo bash /mnt-repo/deploy/install-vm.sh /mnt-repo (running; this takes a while)"
send "sudo bash /mnt-repo/deploy/install-vm.sh /mnt-repo\r"
set timeout -1
expect eof
puts "\[setup\] install finished, VM powered off."
EXP

expect "$DRIVER" "$QEMU" "${QEMU_ARGS[@]}"
echo "Done. Next: ./deploy/run.sh"
