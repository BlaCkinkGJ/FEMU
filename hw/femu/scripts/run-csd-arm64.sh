#!/bin/bash
# Run FEMU as a Computational Storage Drive (CSD) on an arm64 Mac.
#
# Shared-library programs work everywhere. uBPF programs need the build option
# --enable-csd-ubpf, which this build does not have. csd_pause is x86 KVM only,
# so it stays off.
#
# Knobs: ssd_size (4096), fdm_size (64), SSH_PORT (2222).

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
ch_xfer_lat=0
gc_thres_pcent=75
gc_thres_pcent_high=95

fdm_size=${fdm_size:-64}
nr_cu=${nr_cu:-4}
csf_runtime_scale=${csf_runtime_scale:-3}

FEMU_DEVICE_OPTS="devsz_mb=${ssd_size},namespaces=1,femu_mode=4"
FEMU_DEVICE_OPTS+=",secsz=${secsz},secs_per_pg=${secs_per_pg},pgs_per_blk=${pgs_per_blk}"
FEMU_DEVICE_OPTS+=",blks_per_pl=${blks_per_pl},pls_per_lun=${pls_per_lun}"
FEMU_DEVICE_OPTS+=",luns_per_ch=${luns_per_ch},nchs=${nchs}"
FEMU_DEVICE_OPTS+=",pg_rd_lat=${pg_rd_lat},pg_wr_lat=${pg_wr_lat}"
FEMU_DEVICE_OPTS+=",blk_er_lat=${blk_er_lat},ch_xfer_lat=${ch_xfer_lat}"
FEMU_DEVICE_OPTS+=",gc_thres_pcent=${gc_thres_pcent}"
FEMU_DEVICE_OPTS+=",gc_thres_pcent_high=${gc_thres_pcent_high}"
FEMU_DEVICE_OPTS+=",fdm_size=${fdm_size},nr_cu=${nr_cu}"
FEMU_DEVICE_OPTS+=",csf_runtime_scale=${csf_runtime_scale}"
VM_NAME=FEMU-CSD-VM
export FEMU_DEVICE_OPTS VM_NAME

exec "$(dirname "$0")/run-femu-arm64.sh"
