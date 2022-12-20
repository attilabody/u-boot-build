#!/bin/bash
set -ex
threads=$(nproc)
cc="CROSS_COMPILE=/opt/shared/cross/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-"
MAKEOPTS="KBUILD_VERBOSE=1 ARCH=arm ${cc} BL31=../trusted-firmware-a/build/rk3328/release/bl31/bl31.elf -j${threads}"

[ -d trusted-firmware-a ] || git clone https://git.trustedfirmware.org/TF-A/trusted-firmware-a.git
[ -d u-boot ] || git clone git@github.com:u-boot/u-boot.git

git -C trusted-firmware-a pull
git -C u-boot restore .
git -C u-boot clean -dxf
git -C u-boot pull

pushd trusted-firmware-a
make realclean
make ${cc} PLAT=rk3328 -j$(nproc) bl31
popd

pushd u-boot
make ${MAKEOPTS} roc-cc-rk3328_defconfig
make ${MAKEOPTS} -j$(nproc)
make ${MAKEOPTS} -j$(nproc) u-boot.itb

pwd
cp arch/arm/dts/rk3328-roc-cc.dts arch/arm/dts/rk3328-mkspi.dts
#
cp configs/roc-cc-rk3328_defconfig configs/mkspi_defconfig
sed -ie "s/roc-cc/mkspi/g" configs/mkspi_defconfig
sed -ie 's/rk3328-roc-cc.dtb \\/rk3328-roc-cc.dtb \\\n\trk3328-mkspi.dtb \\/g' arch/arm/Makefile

make ${MAKEOPTS} clean
make ${MAKEOPTS} mkspi_defconfig
make ${MAKEOPTS} -j$(nproc)
make ${MAKEOPTS} -j$(nproc) u-boot.itb

popd
