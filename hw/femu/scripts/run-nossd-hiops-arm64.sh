#!/bin/bash
# Run FEMU in NoSSD mode tuned for high IOPS on an arm64 Mac.
#
# The per-queue multipoller gives each I/O queue its own polling thread, so
# drive the device from a polled engine in the guest (fio with io_uring, several
# jobs, large iodepth). HVF caps what this Mac can show: for numbers that mean
# anything, use an x86_64 Linux host with KVM.
#
# Knobs: FEMU_DEVSZ_MB (4096), FEMU_QUEUES (8), FEMU_MULTIPOLLER (1),
# VM_SMP (4), VM_MEM (4G), SSH_PORT (2222).

FEMU_DEVICE_OPTS="devsz_mb=${FEMU_DEVSZ_MB:-4096},namespaces=1,femu_mode=2"
FEMU_DEVICE_OPTS+=",queues=${FEMU_QUEUES:-8}"
FEMU_DEVICE_OPTS+=",multipoller_enabled=${FEMU_MULTIPOLLER:-1}"
VM_NAME=FEMU-NoSSD-MQ-VM
export FEMU_DEVICE_OPTS VM_NAME
export VM_SMP=${VM_SMP:-4} VM_MEM=${VM_MEM:-4G}

exec "$(dirname "$0")/run-femu-arm64.sh"
