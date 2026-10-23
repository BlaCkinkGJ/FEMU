#!/bin/bash
# Run FEMU as a WhiteBox SSD (Open-Channel SSD, OCSSD) on an arm64 Mac.
#
# With lba_index=3 the namespace exposes a 4 KiB + 16 B format, so the Ubuntu
# 24.04 guest attaches it as an ordinary block device and fio works. The
# host-managed OCSSD interface itself (LightNVM, zoned access) is not in that
# kernel: LightNVM was removed in 5.15. For host-managed use, install a 4.17 to
# 5.14 kernel in the guest (4.16 for OCSSD 1.2) or drive the device from SPDK.
#
# Knobs: OCVER (1 for OCSSD 1.2, 2 for 2.0), ssd_size (4096), SSH_PORT (2222).

OCVER=${OCVER:-2}
ssd_size=${ssd_size:-4096}
num_channels=2
num_chips_per_channel=4
num_planes_per_chip=2
num_pages_per_block=512
num_sectors_per_page=4
hw_sector_size=4096
oob_size=16

if [[ $OCVER != 1 && $OCVER != 2 ]]; then
	echo "OCVER must be 1 (OCSSD 1.2) or 2 (OCSSD 2.0), got $OCVER" >&2
	exit 1
fi

FEMU_DEVICE_OPTS="devsz_mb=${ssd_size},namespaces=1,femu_mode=0"
FEMU_DEVICE_OPTS+=",lver=${OCVER},lmetasize=${oob_size},nlbaf=5,lba_index=3,mdts=10"
FEMU_DEVICE_OPTS+=",lnum_ch=${num_channels},lnum_lun=${num_chips_per_channel}"
FEMU_DEVICE_OPTS+=",lnum_pln=${num_planes_per_chip}"
FEMU_DEVICE_OPTS+=",lsec_size=${hw_sector_size}"
FEMU_DEVICE_OPTS+=",lsecs_per_pg=${num_sectors_per_page}"
FEMU_DEVICE_OPTS+=",lpgs_per_blk=${num_pages_per_block}"
VM_NAME=FEMU-OCSSD-VM
export FEMU_DEVICE_OPTS VM_NAME

exec "$(dirname "$0")/run-femu-arm64.sh"
