#!/bin/bash
# Build an Ubuntu 24.04 arm64 guest image for FEMU on macOS (HVF).
#
# Same contract as make-guest-image.sh, but for an arm64 host: the guest is
# arm64, it boots through the edk2 firmware, and the seed ISO is made with
# hdiutil. Output defaults to $IMGDIR/u20s-arm64.qcow2, which
# run-nossd-arm64.sh expects.
set -euo pipefail

RELEASE_URL="https://cloud-images.ubuntu.com/releases/noble/release"
CLOUD_IMG="ubuntu-24.04-server-cloudimg-arm64.img"
READY_MARK="FEMU-GUEST-IMAGE-READY"
FAIL_MARK="FEMU-GUEST-IMAGE-FAILED"

outdir=${IMGDIR:-${HOME:?HOME is not set}/images}
name="u20s-arm64.qcow2"
size="32G"
timeout_s=1800
qemu=${QEMU:-./qemu-system-aarch64}
qemu_img=${QEMU_IMG:-./qemu-img}
firmware=${FEMU_EFI:-./pc-bios/edk2-aarch64-code.fd}

die() { echo "error: $*" >&2; exit 1; }
info() { echo "==> $*"; }

while (( $# > 0 )); do
	case "$1" in
	-o|--outdir) outdir=${2:?missing value for $1}; shift ;;
	-n|--name) name=${2:?missing value for $1}; shift ;;
	-s|--size) size=${2:?missing value for $1}; shift ;;
	--qemu) qemu=${2:?missing value for $1}; shift ;;
	--qemu-img) qemu_img=${2:?missing value for $1}; shift ;;
	--efi) firmware=${2:?missing value for $1}; shift ;;
	--timeout) timeout_s=${2:?missing value for $1}; shift ;;
	-f|--force) force=1 ;;
	-h|--help) sed -n '2,8p' "$0"; exit 0 ;;
	*) die "unknown option $1" ;;
	esac
	shift
done

[[ -x "$qemu" ]] || die "no qemu at $qemu (build first, or pass --qemu)"
[[ -x "$qemu_img" ]] || die "no qemu-img at $qemu_img (pass --qemu-img)"
[[ -r "$firmware" ]] || die "no edk2 firmware at $firmware (pass --efi)"
command -v hdiutil > /dev/null || die "hdiutil not found (macOS only)"

mkdir -p "$outdir"
img="$outdir/$name"
cache="$outdir/cache"
mkdir -p "$cache"

if [[ -f "$img" && -z "${force:-}" ]]; then
	info "$img exists; pass --force to replace it"
	exit 0
fi

info "fetching SHA256SUMS"
sums="$cache/SHA256SUMS"
curl -fsSL --retry 3 -o "$sums" "$RELEASE_URL/SHA256SUMS"
want=$(awk -v f="*$CLOUD_IMG" '$2 == f { print $1 }' "$sums")
[[ "$want" =~ ^[0-9a-f]{64}$ ]] || die "$CLOUD_IMG not listed in SHA256SUMS"

base="$cache/$CLOUD_IMG"
if ! { [[ -f "$base" ]] && [[ $(shasum -a 256 "$base" | cut -d' ' -f1) == "$want" ]]; }; then
	info "downloading $CLOUD_IMG"
	curl -fL --progress-bar --retry 3 -o "$base.part" "$RELEASE_URL/$CLOUD_IMG"
	[[ $(shasum -a 256 "$base.part" | cut -d' ' -f1) == "$want" ]] ||
		{ rm -f "$base.part"; die "SHA256 mismatch for $CLOUD_IMG"; }
	mv "$base.part" "$base"
fi
info "base image verified: $want"

key="$outdir/femu-guest-key"
if [[ ! -f "$key" ]]; then
	info "generating SSH key $key"
	ssh-keygen -q -t ed25519 -N "" -C femu-guest -f "$key"
fi
pub=$(head -n1 "$key.pub")

pkgs="  - nvme-cli
  - fio"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

cat > "$work/user-data" <<EOF
#cloud-config
hostname: femu-guest
users:
  - name: femu
    shell: /bin/bash
    groups: [sudo]
    sudo: "ALL=(ALL) NOPASSWD:ALL"
    lock_passwd: true
    ssh_authorized_keys:
      - $pub
ssh_pwauth: false
package_update: true
packages:
$pkgs
write_files:
  - path: /etc/default/grub.d/90-femu-serial.cfg
    content: |
      GRUB_CMDLINE_LINUX_DEFAULT="console=ttyAMA0,115200n8 console=tty1"
      GRUB_TERMINAL="console serial"
      GRUB_TIMEOUT=1
runcmd:
  - [ update-grub ]
  - [ systemctl, disable, systemd-networkd-wait-online.service ]
  - [ touch, /etc/cloud/cloud-init.disabled ]
  - [ sh, -c, 'if command -v nvme && command -v fio; then echo $READY_MARK > /dev/ttyAMA0; else echo $FAIL_MARK > /dev/ttyAMA0; fi' ]
power_state:
  mode: poweroff
  condition: true
EOF
printf 'instance-id: femu-guest-1\nlocal-hostname: femu-guest\n' > "$work/meta-data"
cat > "$work/network-config" <<EOF
version: 2
ethernets:
  wired:
    match:
      name: "en*"
    dhcp4: true
EOF

seed="$outdir/femu-seed.iso"
rm -f "$seed"
hdiutil makehybrid -quiet -o "$seed" -iso -joliet \
	-iso-volume-name cidata -joliet-volume-name cidata "$work"

info "creating $name"
rm -f "$img"
"$qemu_img" convert -O qcow2 "$base" "$img"
"$qemu_img" resize "$img" "$size"

log="$outdir/$name.provision.log"
info "provisioning (log: $log); this takes a few minutes"
set +e
"$qemu" \
	-name femu-guest-provision \
	-machine virt,accel=hvf -cpu host -smp 4 -m 4G \
	-bios "$firmware" \
	-drive file="$img",if=none,id=hd0,format=qcow2,aio=threads \
	-device virtio-scsi-pci -device scsi-hd,drive=hd0 \
	-drive file="$seed",media=cdrom,format=raw \
	-netdev user,id=n0 -device virtio-net-pci,netdev=n0 \
	-nographic -no-reboot > "$log" 2>&1 &
qp=$!
( sleep "$timeout_s"; kill "$qp" 2>/dev/null ) &
watchdog=$!
wait "$qp"
rc=$?
kill "$watchdog" 2>/dev/null
set -e

if grep -q "$READY_MARK" "$log"; then
	info "guest image ready: $img"
	echo "log in with: ssh -i $key -p 8080 femu@localhost"
	exit 0
fi
die "provisioning failed (rc=$rc); see $log"
