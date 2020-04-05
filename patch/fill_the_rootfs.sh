#!/bin/sh

#############################################################
# this is a tool to add rtl8723bs' firware, module and other
# stuff into rootfs
#############################################################

if [ $# -ne 1 ]; then
    echo "wrong parameter"
	echo "demo usage: [sudo] ./fill_the_rootfs.sh /mnt/sdb2/"
    exit 1
fi

echo the destination is: $1

# [1]
if [ ! -d $1/lib/firmware/rtlwifi/ ]; then
    sudo mkdir -p $1/lib/firmware/rtlwifi/
fi
sudo cp rtl8723bs_nic.bin $1/lib/firmware/rtlwifi/

# [2]
sudo cp r8723bs.ko $1/root

# [3]
sudo echo > $1/etc/wpa_supplicant.conf
conf="
#############################################
# sam add
#############################################
ctrl_interface=/var/run/wpa_supplicant
ctrl_interface_group=0
ap_scan=1
network={
    ssid=\"OPPO K1\"
    scan_ssid=1
    key_mgmt=WPA-EAP WPA-PSK IEEE8021X NONE
    pairwise=TKIP CCMP
    group=CCMP TKIP WEP104 WEP40
    psk=\"12345678\"
    priority=5
}"
sudo cat>$1/etc/wpa_supplicant.conf<<EOF
$conf
EOF

# [4]
setup="
#############################################
# sam add
#############################################
insmod /root/r8723bs.ko
ifconfig wlan0 up
wpa_supplicant -B -d -i wlan0 -c /etc/wpa_supplicant.conf
udhcpc -i wlan0"
sudo cat>>$1/etc/init.d/rcS<<EOF
$setup
EOF

echo OK
