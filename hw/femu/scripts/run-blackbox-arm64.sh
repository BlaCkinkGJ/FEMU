#!/bin/bash
# Run FEMU as a black-box SSD (BBSSD) on an arm64 Mac.
#
# Same controller and NAND geometry as run-blackbox.sh, which is a 16 GiB
# media, but less of it is exposed: ssd_size defaults to 4096 instead of 12288
# so the device backend fits in a 16 GiB Mac next to the guest's 4 GiB. The
# exposed namespace still leaves the media 75% over-provisioned for GC.
#
# Knobs: ssd_size (4096), SSH_PORT (2222), VM_SMP, VM_MEM, OSIMGF.

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

FEMU_DEVICE_OPTS="devsz_mb=${ssd_size},namespaces=1,femu_mode=1"
FEMU_DEVICE_OPTS+=",secsz=${secsz},secs_per_pg=${secs_per_pg},pgs_per_blk=${pgs_per_blk}"
FEMU_DEVICE_OPTS+=",blks_per_pl=${blks_per_pl},pls_per_lun=${pls_per_lun}"
FEMU_DEVICE_OPTS+=",luns_per_ch=${luns_per_ch},nchs=${nchs}"
FEMU_DEVICE_OPTS+=",pg_rd_lat=${pg_rd_lat},pg_wr_lat=${pg_wr_lat}"
FEMU_DEVICE_OPTS+=",blk_er_lat=${blk_er_lat},ch_xfer_lat=${ch_xfer_lat}"
FEMU_DEVICE_OPTS+=",gc_thres_pcent=${gc_thres_pcent}"
FEMU_DEVICE_OPTS+=",gc_thres_pcent_high=${gc_thres_pcent_high}"
VM_NAME=FEMU-BBSSD-VM
export FEMU_DEVICE_OPTS VM_NAME

exec "$(dirname "$0")/run-femu-arm64.sh"
