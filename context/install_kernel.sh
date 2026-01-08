#!/bin/bash

make -j$((CORES * 3 / 2)) ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH=/mnt/root modules_install

if [ ! -f "/mnt/boot/$KERNEL-backup.img" ]; then
  cp "/mnt/boot/$KERNEL.img" "/mnt/boot/$KERNEL-backup.img"
fi
cp arch/arm/boot/zImage "/mnt/boot/$KERNEL.img"
cp arch/arm/boot/dts/broadcom/*.dtb /mnt/boot/
cp arch/arm/boot/dts/overlays/*.dtb* /mnt/boot/overlays/
cp arch/arm/boot/dts/overlays/README /mnt/boot/overlays/
