#!/bin/bash
# Run FEMU as a black-box SSD with Flexible Data Placement (FDP) on an arm64 Mac.
#
# The controller is the BBSSD one, linked to a femu-subsys that carries the FDP
# numbers. Placement hints need passthrough commands or io_uring in the guest.
#
# Knobs: ssd_size (4096), fdp_nruh (4), fdp_nrg (1), SSH_PORT (2222).

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

fdp_nruh=${fdp_nruh:-4}
fdp_nrg=${fdp_nrg:-1}
fdp_nru=${fdp_nru:-$blks_per_pl}
subsys_id=femu-subsys-0

FEMU_EXTRA_ARGS="-device femu-subsys,id=${subsys_id},nqn=subsys0,fdp=on"
FEMU_EXTRA_ARGS+=",fdp.nruh=${fdp_nruh},fdp.nrg=${fdp_nrg},fdp.nru=${fdp_nru}"

FEMU_DEVICE_OPTS="devsz_mb=${ssd_size},namespaces=1,femu_mode=1"
FEMU_DEVICE_OPTS+=",secsz=${secsz},secs_per_pg=${secs_per_pg},pgs_per_blk=${pgs_per_blk}"
FEMU_DEVICE_OPTS+=",blks_per_pl=${blks_per_pl},pls_per_lun=${pls_per_lun}"
FEMU_DEVICE_OPTS+=",luns_per_ch=${luns_per_ch},nchs=${nchs}"
FEMU_DEVICE_OPTS+=",pg_rd_lat=${pg_rd_lat},pg_wr_lat=${pg_wr_lat}"
FEMU_DEVICE_OPTS+=",blk_er_lat=${blk_er_lat},ch_xfer_lat=${ch_xfer_lat}"
FEMU_DEVICE_OPTS+=",gc_thres_pcent=${gc_thres_pcent}"
FEMU_DEVICE_OPTS+=",gc_thres_pcent_high=${gc_thres_pcent_high}"
FEMU_DEVICE_OPTS+=",subsys=${subsys_id}"
VM_NAME=FEMU-FDP-VM
export FEMU_DEVICE_OPTS FEMU_EXTRA_ARGS VM_NAME

exec "$(dirname "$0")/run-femu-arm64.sh"
