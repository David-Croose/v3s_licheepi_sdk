#!/bin/sh

############################################################
# this is a tool to make rootfs' ssh work by modifying the
# reference configuration file
############################################################

if [ $# -ne 1 ]; then
    echo "wrong parameter"
    echo "demo usage: [sudo] ./config_ssh.sh /mnt/sdb2/"
    exit 1
fi

sudo echo "PermitRootLogin yes" >> $1/etc/ssh/sshd_config
sudo echo "PermitEmptyPasswords yes" >> $1/etc/ssh/sshd_config
