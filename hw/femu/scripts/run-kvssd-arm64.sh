#!/bin/bash
# Run FEMU as a key-value SSD (KV) on an arm64 Mac.
#
# The guest needs Linux 6.0 or newer: there is no block device, the namespace
# is reached through NVMe passthrough as /dev/ngXnY. The Ubuntu 24.04 image
# has 6.8. Guest tools: nvme-cli `io-passthru` and hw/femu/scripts/kv-probe.c.
#
# Knobs: ssd_size (4096), KV_INDEX (hash|lsm), KV_LSM_OPTS, SSH_PORT (2222).

secsz=512
secs_per_pg=8
pgs_per_blk=256
blks_per_pl=256
pls_per_lun=1
luns_per_ch=8
nchs=8
ssd_size=${ssd_size:-4096}

pg_rd_lat=40000
pg_wr_lat=200000
blk_er_lat=2000000
gc_thres_pcent=75

kv_index=${KV_INDEX:-hash}
kv_lsm_opts=${KV_LSM_OPTS:-}

FEMU_DEVICE_OPTS="devsz_mb=${ssd_size},namespaces=1,femu_mode=5"
FEMU_DEVICE_OPTS+=",secsz=${secsz},secs_per_pg=${secs_per_pg},pgs_per_blk=${pgs_per_blk}"
FEMU_DEVICE_OPTS+=",blks_per_pl=${blks_per_pl},pls_per_lun=${pls_per_lun}"
FEMU_DEVICE_OPTS+=",luns_per_ch=${luns_per_ch},nchs=${nchs}"
FEMU_DEVICE_OPTS+=",pg_rd_lat=${pg_rd_lat},pg_wr_lat=${pg_wr_lat}"
FEMU_DEVICE_OPTS+=",blk_er_lat=${blk_er_lat},gc_thres_pcent=${gc_thres_pcent}"
FEMU_DEVICE_OPTS+=",kv_index=${kv_index}"
if [[ -n $kv_lsm_opts ]]; then
	FEMU_DEVICE_OPTS+=",${kv_lsm_opts}"
fi
VM_NAME=FEMU-KVSSD-VM
export FEMU_DEVICE_OPTS VM_NAME

exec "$(dirname "$0")/run-femu-arm64.sh"
