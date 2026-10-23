#!/bin/bash
# Run FEMU as a Zoned Namespace SSD (ZNS) on an arm64 Mac.
#
# The guest needs Linux 5.9 or newer with CONFIG_BLK_DEV_ZONED and 4 KiB pages,
# which the Ubuntu 24.04 arm64 image satisfies. nvme-cli 1.12 or newer gives
# the `nvme zns` commands.
#
# Knobs: SSD_SIZE_MB (4096), SSH_PORT (2222), OSIMGF.

SSD_SIZE_MB=${SSD_SIZE_MB:-4096}
NUM_CHANNELS=8
NUM_CHIPS_PER_CHANNEL=4
NUM_PLANES_PER_CHIP=2
NUM_BLOCKS_PER_CHIP=32
# QLC. MLC is not allowed here.
FLASH_TYPE=4

FEMU_DEVICE_OPTS="devsz_mb=${SSD_SIZE_MB},namespaces=1,femu_mode=3"
FEMU_DEVICE_OPTS+=",zns_num_ch=${NUM_CHANNELS},zns_num_lun=${NUM_CHIPS_PER_CHANNEL}"
FEMU_DEVICE_OPTS+=",zns_num_plane=${NUM_PLANES_PER_CHIP}"
FEMU_DEVICE_OPTS+=",zns_num_blk=${NUM_BLOCKS_PER_CHIP}"
FEMU_DEVICE_OPTS+=",zns_flash_type=${FLASH_TYPE}"
VM_NAME=FEMU-ZNSSD-VM
export FEMU_DEVICE_OPTS VM_NAME

exec "$(dirname "$0")/run-femu-arm64.sh"
