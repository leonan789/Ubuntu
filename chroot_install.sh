#!/bin/bash
# *****************************************************************************
# Function:     Execute in chroot
# Description:  Install ssh and adduser hisilicon
# Date:         2018/09/08
# Author:       nanweijia
# *****************************************************************************

apt-get update
apt-get install openssh-server -y
apt-get install unzip -y

adduser --disabled-password --gecos "" hisilicon
echo -e "hisilicon\nhisilicon" | passwd hisilicon
echo "hisilicon       ALL=(ALL:ALL) ALL" >> /etc/sudoers
exit
# end
