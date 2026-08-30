#!/bin/bash

export ARCH="arm"
export CROSS_COMPILE=arm-linux-gnueabihf-

export SDK_PATH=/mnt/ssd20x
cd ${SDK_PATH}

# !!! 1 compile SSD202 SDK
cd ${SDK_PATH}/ssd20x-uboot-open

# !!! equal configuration
# make WT2012_defconfig
# make infinity2m_spinand_defconfig
make WT2022_defconfig
make -j4
cd ..

cp \
${SDK_PATH}/ssd20x-uboot-open/u-boot_spinand.xz.img.bin \
${SDK_PATH}/ssd20x-images-open/WT2022/boot/u-boot_spinand.xz.img.bin

cp \
${SDK_PATH}/ssd20x-uboot-open/u-boot_spinand.xz.img.bin \
${SDK_PATH}/ssd20x-images-open/WT2022/uboot_s.bin

cd ${SDK_PATH}/ssd20x-images-open/partition
chmod +x part.sh
./part.sh
# ./part.sh 2G
# The default is 128MB(1Gbit) flash
# To configure, 256MB(2GBit) flash Need to transfer in 2G Parameters
cp cis.bin ${SDK_PATH}/ssd20x-images-open/WT2022

# !!! 2 Compile kernel
cd ${SDK_PATH}/ssd20x-kernel-open
make WT2022_defconfig
make clean
make -j4
cp ./arch/arm/boot/uImage.xz ${SDK_PATH}/ssd20x-images-open/WT2022/kernel

# !!! 3 Make a file system
cd ${SDK_PATH}/ssd20x-rootfs-open/ssd202
# root-sstar.tar.gz To compile openwrt Generated root-sstar
tar zxvf root-sstar.tar.gz
cp ${Youer_Files} ${SDK_PATH}/ssd20x-rootfs-open/ssd202/root-sstar/usr

# Package dependency mtd-utils, This tool needs to be installed in advance 
sudo apt-get install mtd-utils
cd ${SDK_PATH}/ssd20x-rootfs-open
./mk_tools.sh
./mk_ubi.sh ssd202
