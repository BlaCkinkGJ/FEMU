#!/bin/bash
# Shared launcher behind the run-*-arm64.sh scripts.
#
# The mode scripts set the variables below and exec this file. Everything
# macOS-specific lives here: the edk2 firmware, the virt machine, HVF, the
# threaded qcow2 AIO that Darwin supports, and slirp networking.
#
#   FEMU_DEVICE_OPTS  properties for -device femu, empty means no NVMe device
#   FEMU_EXTRA_ARGS   extra QEMU arguments, split on whitespace
#   VM_NAME           QEMU -name (default FEMU-arm64)
#   VM_SMP, VM_MEM    guest vCPUs and RAM (4, 4G)
#   MACHINE           -machine value (virt,accel=hvf)
#   SSH_PORT          host port forwarded to guest port 22 (2222)
#   OSIMGF, IMGDIR    guest image (see make-guest-image-arm64.sh)
#   QEMU, FEMU_EFI    binaries, for a different build directory
#   QMP_SOCK          QMP unix socket (./qmp-sock)

IMGDIR=${IMGDIR:-$HOME/images}
OSIMGF=${OSIMGF:-$IMGDIR/u20s-arm64.qcow2}
SSH_PORT=${SSH_PORT:-2222}
VM_NAME=${VM_NAME:-FEMU-arm64}
VM_SMP=${VM_SMP:-4}
VM_MEM=${VM_MEM:-4G}
MACHINE=${MACHINE:-virt,accel=hvf}
QEMU=${QEMU:-./qemu-system-aarch64}
FEMU_EFI=${FEMU_EFI:-./pc-bios/edk2-aarch64-code.fd}
QMP_SOCK=${QMP_SOCK:-./qmp-sock}
FEMU_DEVICE_OPTS=${FEMU_DEVICE_OPTS:-}
FEMU_EXTRA_ARGS=${FEMU_EXTRA_ARGS:-}

if [[ ! -x $QEMU ]]; then
	echo "no $QEMU here, run this from build-femu/ or set QEMU" >&2
	exit 1
fi
if [[ ! -r $FEMU_EFI ]]; then
	echo "no edk2 firmware at $FEMU_EFI, set FEMU_EFI" >&2
	exit 1
fi
if [[ ! -e $OSIMGF ]]; then
	echo "guest image $OSIMGF not found, build one with ./make-guest-image-arm64.sh" >&2
	exit 1
fi

femu_device=""
if [[ -n $FEMU_DEVICE_OPTS ]]; then
	femu_device="-device femu,${FEMU_DEVICE_OPTS}"
fi

# Unquoted expansions are deliberate: the two strings are argument lists.
exec "$QEMU" \
	-name "$VM_NAME",debug-threads=on \
	-machine "$MACHINE" -cpu host -smp "$VM_SMP" -m "$VM_MEM" \
	-bios "$FEMU_EFI" \
	-drive file="$OSIMGF",if=none,id=hd0,format=qcow2,aio=threads \
	-device virtio-scsi-pci,bus=pcie.0 -device scsi-hd,drive=hd0 \
	$FEMU_EXTRA_ARGS $femu_device \
	-netdev user,id=n0,hostfwd=tcp::${SSH_PORT}-:22 \
	-device virtio-net-pci,bus=pcie.0,netdev=n0 \
	-qmp unix:${QMP_SOCK},server,nowait \
	-nographic
