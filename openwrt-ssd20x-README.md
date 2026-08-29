# openwrt-sstar
wireless-tag supports sigmstar SSD201/SSD202

# Install dependencies
ubuntu 16.04.7 64 bit system

````sh
sudo apt-get install subversion build-essential libncurses5-dev zlib1g-dev gawk git ccache
sudo apt-get install gettext libssl-dev xsltproc libxml-parser-perl
sudo apt-get install gengetopt default-jre-headless ocaml-nox sharutils texinfo
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install zlib1g:i386 libstdc++6:i386 libc6:i386 libc6-dev-i386
````

# Download code
1. Download the main project code
```
git clone https://github.com/wireless-tag-com/openwrt-ssd20x.git
```

# Install toolchian

1. Download toolchain
Link: https://pan.baidu.com/s/1SUk1a-drbWo1tkHQzCgchg
Extraction code: 1o3d

2. unzip toolchain

```
sudo -xvf tar wt-gcc-arm-8.2-2018.08-x86_64-arm-linux-gnueabihf.tag.gz -C /opt/
```

3. Set the environment variables, modify the ~/.profile file,
   and add the following line to the end of the file
```
nano ~/.profile
PATH="/opt/gcc-arm-8.2-2018.08-x86_64-arm-linux-gnueabihf/bin:$PATH"
```

Enabling environment variables manually
```
source ~/.profile
```

Test cross toolchain
```
arm-linux-gnueabihf-gcc --version
```


# 编译

1. Generate model configuration file

```
cd 18.06
./scripts/feeds update -a
./scripts/feeds install -a -f
```
or

```
./scripts/feeds update luci
./scripts/feeds install -a -p luci

./scripts/feeds update packages
./scripts/feeds install -a -p packages

./scripts/feeds update routing
./scripts/feeds install -a -p routing

./scripts/feeds update telephony
./scripts/feeds install -a -p telephony
```

```
make WT2022_wt
make WT2020_wt
make -j1 V=sc

```

| Model name | Instruction     |
| ---------- | --------------- |
| WT2022     | SSD202+CC0702I50R(1024*600)+2Gbit QSPI NAND|
| WT2011     | SSD202+CC0702I50R(1024*600)+2Gbit QSPI NAND|
| WT2020     | SSD202+FRD720X720BK(720*720)+2Gbit QSPI NAND|
| WT2015     | SSD201+Dual Ethernet PHY+2Gbit QSPI NAND|

2. Compile

```
make V=s -j4
```

3. Compiled product
    at bin/target/sstar/ssd20x/WT2022

| file name                | Instruction                 |
| ------------------------ | --------------------------- |
| WT2022-sysupgrade.bin    |                             |
| WT2022-uImage.xz         |                             |
| WT2022-root-ubi.img      | Root file system (SPI NAND) |


# Upgrade
In the system, enter the system background through the serial port or telnet,
and execute the following command:

```
cd /tmp
tftp -g 192.168.1.88 -r WT2022-sysupgrade.bin
sysupgrade WT2022-sysupgrade.bin
```

After the upgrade is complete, the system will automatically restart

To upgrade through the serial port and network port under uboot
(press the enter button during the power-on phase), execute the following command:

Set environment variables, start the network

```
setenv serverip 192.168.1.88
setenv ipaddr 192.168.1.11
setenv ethinitauto 1
saveenv
reset
```

After rebooting, press Enter to re-enter uboot

## SPI NAND
upgrade

### The internet

```
tftp 0x21000000 WT2022-root-ubi.img
nand erase.part ubi
nand write.e 0x21000000 ubi ${filesize}
```

### U disk (FAT32 file system)
Put WT2022-root-ubi.img into the root directory of the U disk

```
fatload usb 0 WT2022-root-ubi.img
nand erase.part ubi
nand write.e 0x21000000 ubi ${filesize}
```

### TF/SD card (FAT32 file system)
Put WT2022-root-ubi.img into the root directory of TF card/SD card

```
mmc rescan 0
fatload mmc 0 0x21000000 WT2022-root-ubi.img
nand erase.part ubi
nand write.e 0x21000000 ubi ${filesize}
```

## Brush system
If the system is not the openwrt system for the first time,
please use the following command to flash the machine
to the openwrt system under uboot,
and then use the above steps to upgrade

### The internet

```
tftp 0x21000000 SSD202_openwrt.bin
nand erase.chip
nand write.e 0x21000000 0x00 ${filesize}
reset
```

### U disk (FAT32 file system)
Put SSD202_openwrt.bin into the root directory of the U disk

```
usb start 1
fatload usb 0 0x21000000 SSD202_openwrt.bin
nand erase.chip
nand write.e 0x21000000 0x00 ${filesize}
reset
```

### TF/SD card (FAT32 file system)
Put SSD202_openwrt.bin into the root directory of TF card/SD card

```
mmc rescan 0
fatload mmc 0 0x21000000 SSD202_openwrt.bin
nand erase.chip
nand write.e 0x21000000 0x00 ${filesize}
reset
```
