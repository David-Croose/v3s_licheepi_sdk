#!/bin/bash

#############################################################
# this is a tool to add rtl8723bs' firmware, modules and
# other stuff into rootfs
#############################################################

echo "Please enter your rootfs path:"
read fspath

echo "Please enter your WIFI AP name:"
read apname
echo "Please enter your WIFI AP password:"
read appassword

# [1]
if [ ! -d $fspath/lib/firmware/rtlwifi/ ]; then
    sudo mkdir -p $fspath/lib/firmware/rtlwifi/
fi
sudo cp rtl8723bs_nic.bin $fspath/lib/firmware/rtlwifi/

# [2]
if [ ! -d $fspath/lib/modules/rtl ]; then
	sudo mkdir -p $fspath/lib/modules
fi
sudo cp r8723bs.ko $fspath/lib/modules

# [3]
sudo rm -f $fspath/etc/wpa_supplicant.conf
sudo cat>$fspath/etc/wpa_supplicant.conf<<EOF
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

# [4]
sudo cat>>$fspath/etc/init.d/rcS<<EOF
#############################################
# for wifi rtl8723bs
#############################################
insmod /lib/modules/r8723bs.ko
ifconfig wlan0 up
wpa_supplicant -B -d -i wlan0 -c /etc/wpa_supplicant.conf
udhcpc -i wlan0
EOF

echo OK
