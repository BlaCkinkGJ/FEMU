#!/bin/bash
# Run FEMU with no SSD model (NoSSD) on an arm64 Mac.
#
# The emulated NVMe controller lives in host DRAM: every I/O is a memory copy,
# with no NAND timing. The guest is the arm64 Ubuntu image from
# make-guest-image-arm64.sh, running under HVF.
#
# Knobs: FEMU_DEVSZ_MB (4096), SSH_PORT (2222), VM_SMP, VM_MEM, OSIMGF.

FEMU_DEVICE_OPTS="devsz_mb=${FEMU_DEVSZ_MB:-4096},namespaces=1,femu_mode=2"
VM_NAME=FEMU-NoSSD-VM
export FEMU_DEVICE_OPTS VM_NAME

exec "$(dirname "$0")/run-femu-arm64.sh"
