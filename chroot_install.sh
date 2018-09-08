#!/bin/bash
# *****************************************************************************
# Function:     Execute in chroot
# Description:  Install ssh and adduser hisilicon
# Date:         2018/09/08
# Author:       leonan
# *****************************************************************************

apt-get update
apt-get install openssh-server -y
apt-get install unzip -y

adduser --disabled-password --gecos "" hisilicon
echo -e "user\nuser" | passwd hisilicon
echo "user       ALL=(ALL:ALL) ALL" >> /etc/sudoers
exit
# end
