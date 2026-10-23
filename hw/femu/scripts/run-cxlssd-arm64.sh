#!/bin/bash
# Run the FEMU CXL SSD on an arm64 Mac.
#
# A CXL Type-3 memory device whose DRAM page cache sits in front of the FEMU
# FTL, below a pxb-cxl host bridge and a cxl-rp root port on the virt machine.
# der stays off, so every access is trapped: memslot and cylon need KVM and an
# x86 host kernel.
#
# The guest needs CONFIG_CXL_BUS, CXL_PCI, CXL_ACPI, CXL_MEM, CXL_PORT,
# CXL_REGION and DEV_DAX, plus cxl-cli and daxctl. The Ubuntu 24.04 arm64 cloud
# image has the config as modules but does not ship the files and offers no
# matching linux-modules-extra package, so the device is visible in lspci and
# never binds. A cxl-fmw window on virt also makes the firmware fail with
# "unhandled exception ec=0x20", so none is configured: virt places the bridge
# itself. Use an x86_64 Linux guest for guest-side CXL work.
#
# Knobs: CXL_SIZE (256M), CACHE_PAGES, CACHE_WAYS (1), DER (off),
# BLOCKS_PER_PLANE (0 lets FEMU size it), SSH_PORT (2222).

CXL_SIZE=${CXL_SIZE:-256M}
if [[ $CXL_SIZE =~ ^([0-9]+)([MG])$ ]]; then
	size_mb=${BASH_REMATCH[1]}
	[[ ${BASH_REMATCH[2]} == G ]] && size_mb=$((size_mb * 1024))
else
	echo 'CXL_SIZE must be an integer followed by M or G' >&2
	exit 1
fi

CACHE_PAGES=${CACHE_PAGES:-$(((size_mb / 20) * 256))}
CACHE_WAYS=${CACHE_WAYS:-1}
[[ $CACHE_WAYS == full ]] && CACHE_WAYS=$CACHE_PAGES
BLOCKS_PER_PLANE=${BLOCKS_PER_PLANE:-0}
DER=${DER:-off}
LOG_DIR=${LOG_DIR:-.}

MACHINE="virt,accel=hvf,cxl=on"

# No NVMe controller in this mode, the FTL is reached through CXL.mem.
FEMU_DEVICE_OPTS=""
FEMU_EXTRA_ARGS="-object memory-backend-ram,id=cxlmem,size=${CXL_SIZE}"
FEMU_EXTRA_ARGS+=" -device pxb-cxl,id=cxl.0,bus=pcie.0,bus_nr=52"
FEMU_EXTRA_ARGS+=" -device cxl-rp,id=cxl-rp0,bus=cxl.0,chassis=0,slot=0"
FEMU_EXTRA_ARGS+=" -device femu-cxl-ssd,id=cxlssd,bus=cxl-rp0,volatile-memdev=cxlmem"
FEMU_EXTRA_ARGS+=",cache-pages=${CACHE_PAGES},cache-ways=${CACHE_WAYS}"
FEMU_EXTRA_ARGS+=",cache-policy=fifo,der=${DER},prefetch-degree=0,prefetch-stride=1"
FEMU_EXTRA_ARGS+=",channels=8,luns-per-channel=8,blocks-per-plane=${BLOCKS_PER_PLANE}"
FEMU_EXTRA_ARGS+=",pages-per-block=256,read-ns=40000,program-ns=200000"
FEMU_EXTRA_ARGS+=",erase-ns=2000000,channel-ns=0,gc-threshold=75,gc-threshold-high=95"
FEMU_EXTRA_ARGS+=",ftl=on,lsa-control=off"
FEMU_EXTRA_ARGS+=",cylon-first-touch-program=off,cylon-free-writeback=off"
FEMU_EXTRA_ARGS+=",log-dir=${LOG_DIR//,/,,},log-limit=64M"
VM_NAME=FEMU-CXLSSD-VM

export MACHINE FEMU_DEVICE_OPTS FEMU_EXTRA_ARGS VM_NAME

exec "$(dirname "$0")/run-femu-arm64.sh"
