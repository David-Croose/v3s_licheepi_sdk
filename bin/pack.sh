#!/bin/bash

set -e

umount_all()
{
	set +e

	df | grep ${SDCARD}1 2>&1 1>/dev/null
	if [ $? == 0 ]; then
		umount ${SDCARD}1
	fi

	df | grep ${SDCARD}2 2>&1 1>/dev/null
	if [ $? == 0 ]; then
		umount ${SDCARD}2
	fi

	set -e
}

UBOOT=u-boot-sunxi-with-spl.bin
KERN=zImage
DTB=sun8i-v3s-licheepi-zero-dock.dtb

echo "=================================================================="
echo "Please enter your sdcard block device name:"
echo "e.g. /dev/sdb"
read SDCARD

echo "=================================================================="
echo "umounting sdcard..."
umount_all

echo "=================================================================="
echo "deleting all partitions..."
wipefs -a -f $SDCARD
# TODO  can this really work?
dd if=/dev/zero of=$SDCARD bs=1M count=1

echo "=================================================================="
echo "writing uboot into sdcard..."
dd if=$UBOOT of=$SDCARD bs=1024 seek=8

echo "=================================================================="
echo "creating partitions..."
fdisk $SDCARD < part.txt

echo "=================================================================="
echo "formating partitions..."
mkfs.fat ${SDCARD}1
mkfs.ext4 -F ${SDCARD}2

echo "=================================================================="
echo "mounting sdcard..."
rm -rf /tmp/mnt1 /tmp/mnt2
mkdir /tmp/mnt1 /tmp/mnt2
umount_all
mount ${SDCARD}1 /tmp/mnt1
mount ${SDCARD}2 /tmp/mnt2

echo "=================================================================="
echo "copying kernel and dtb..."
cp $KERN $DTB /tmp/mnt1

echo "=================================================================="
echo "copying rootfs..."
echo "please enter your rootfs full name:"
echo "default is rootfs.tar of buildroot"
read ROOTFS
if [ -z "$ROOTFS" ]; then
	ROOTFS=rootfs.tar
else
	echo "is that a debian base filesystem?(Y/n)"
	read ISDEBIAN
	if [ -z "$ISDEBIAN" ] || [ "$ISDEBIAN" = Y ]; then
		ISDEBIAN=true
	else
		ISDEBIAN=false
	fi
fi

echo "=================================================================="
echo "extracting rootfs..."
tar -xf $ROOTFS -C /tmp/mnt2

echo "=================================================================="
echo "setting up WIFI..."
echo "Please enter your WIFI AP name:"
read apname
echo "Please enter your WIFI AP password:"
read appassword

fspath=/tmp/mnt2

if [ ! -d $fspath/lib/firmware/rtlwifi/ ]; then
    mkdir -p $fspath/lib/firmware/rtlwifi/
fi
cp rtl8723bs_nic.bin $fspath/lib/firmware/rtlwifi/

if [ ! -d $fspath/lib/modules/rtl ]; then
	mkdir -p $fspath/lib/modules
fi
cp r8723bs.ko $fspath/lib/modules

mkdir -p $fspath/etc/
cat > $fspath/etc/wpa_supplicant.conf << EOF
#############################################
# for wifi rtl8723bs
#############################################
ctrl_interface=/var/run/wpa_supplicant
ctrl_interface_group=0
ap_scan=1
network={
    ssid="$apname"
    scan_ssid=1
    key_mgmt=WPA-EAP WPA-PSK IEEE8021X NONE
    pairwise=TKIP CCMP
    group=CCMP TKIP WEP104 WEP40
    psk="$appassword"
    priority=5
}
EOF

if [ "$ISDEBIAN" = "true" ]; then
	cat > $fspath/etc/rc.local <<- EOF
	#!/bin/bash
	#############################################
	# for wifi rtl8723bs
	#############################################
	insmod /lib/modules/r8723bs.ko
	ifconfig wlan0 up
	wpa_supplicant -B -d -i wlan0 -c /etc/wpa_supplicant.conf
	udhcpc -i wlan0

	exit 0
	EOF
	chmod +x $fspath/etc/rc.local

else
	# TODO  this boot script may not fit all filesystem
	cat > $fspath/etc/init.d/rcS <<- EOF
	#!/bin/sh
	#############################################
	# for wifi rtl8723bs
	#############################################
	insmod /lib/modules/r8723bs.ko
	ifconfig wlan0 up
	wpa_supplicant -B -d -i wlan0 -c /etc/wpa_supplicant.conf
	udhcpc -i wlan0
	EOF

fi

echo "=================================================================="
echo "unmounting sdcard..."
umount_all
rm -rf /tmp/mnt1 /tmp/mnt2
