#!/bin/bash
# Huaicheng <huaicheng@cs.uchicago.edu>
# Copy necessary scripts for running FEMU

FSD="../femu-scripts"

CPL=(pkgdep.sh femu-compile.sh make-guest-image.sh run-guest-ssh.sh
     run-whitebox.sh run-blackbox.sh run-blackbox-fdp.sh run-nossd.sh
     run-zns.sh run-csd.sh run-kvssd.sh pin.sh ftk
     make-guest-image-arm64.sh run-femu-arm64.sh
     run-nossd-arm64.sh run-nossd-hiops-arm64.sh
     run-blackbox-arm64.sh run-blackbox-fdp-arm64.sh
     run-zns-arm64.sh run-kvssd-arm64.sh run-csd-arm64.sh
     run-whitebox-arm64.sh run-cxlssd-arm64.sh)

echo ""
echo "==> Copying following FEMU script to current directory:"
for f in "${CPL[@]}"
do
	if [[ ! -e $FSD/$f ]]; then
		echo "Make sure you are under build-femu/ directory!"
		exit
	fi
	cp -r $FSD/$f . && echo "    --> $f"
done
echo "Done!"
echo ""
