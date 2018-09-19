#!/bin/bash
# *****************************************************************************
# Function:     Execute in chroot
# Description:  Install software and adduser hisilicon
# Date:         2018/09/18_release1.18
# Author:       nanweijia
# *****************************************************************************

locale-gen zh_CN.UTF-8 en_US.UTF-8 en_HK.UTF-8
apt-get update
apt-get install openssh-server -y
apt-get install unzip -y
apt-get install vim -y
apt-get install gcc -y
apt-get install zlib -y
apt-get install python2.7 -y
apt-get install python3 -y
apt-get install pciutils -y
apt-get install strace -y
apt-get install nfs-common -y

CurTime=$((($(date +%s ) - $(date +%s -d '19700101'))/86400))
useradd -m hisilicon
sed -i "/^hisilicon:/c\hisilicon:$6$Zlr1mw83$vw/cmjEg8vpvWj3Cenp9a78lmmx.b7UH2xVvTw32KWwLpwWGRMFb9Fiyw/DoxvaxWIQdz7CkUGjx/cujDkuQR/:$CurTime:0:99999:7:::" /etc/shadow
echo "hisilicon       ALL=(ALL:ALL) ALL" >> /etc/sudoers
exit
# end
