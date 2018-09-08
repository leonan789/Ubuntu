#!/bin/bash
# *****************************************************************************
# Function:     SDcard fabrication
# Description:  SDcard format, extract ubuntu filesystem from iso, and copy
#               (3559/mini).run file into "/var", "/" directory in SDcard.
# Date:         2018/09/08-v0.8
# Author:       nanweijia
# Input:        1.SDcard fullname(e.g:/dev/mmcblk1)
#               2.Path include ubuntu-xxx-server-arm64.iso and (3559/mini).run
#               3.iso filename(e.g:ubuntu-16.04.3-server-arm64.iso)
#               4.mini filename(e.g:xxx.run)
#               5.3559 filename(e.g:xxx.run)
# *****************************************************************************

# ************************Variable*********************************************
DEV_NAME=$1
ISO_FILE_DIR=$2
ISO_FILE=$3
RUN_MINI=$4
RUN_3559=$5
DATE=`date +"%F %X"`
TMPDIR_SD_MOUNT=sd_mount_dir
TMPDIR_DATE=`date +"%y%m%d%H%M%S"`
# end

# ************************Record Process***************************************
# Description:  Record running process or result
# Input:        1.level: Process/Failed
#               2.message: Percent/Reason 
# *****************************************************************************
function recordProcess()
{
    level=$1
    msg=$2
    > make_ubuntu_sd.process
    echo -e "${level}:${msg}$" >> make_ubuntu_sd.process
}
# end recordProcess()

# ************************Extract ubuntufs from iso*****************************
# Description:  mount iso file , extract root filesystem from squashfs 
#               after execute function it will create squashfs-root/ in "./"
# ******************************************************************************
function ubuntufsExtract()
{
    mkdir $TMPDIR_DATE
    mount -o loop ${ISO_FILE_DIR}/$ISO_FILE $TMPDIR_DATE
    cp ${TMPDIR_DATE}/install/filesystem.squashfs ./
    if [ $? -ne 0 ];then
        recordProcess "Failed" "Copy 'filesystem.squashfs' fail!"
        exit 1;
    fi

    unsquashfs filesystem.squashfs
}
# end

# ************************configure ubuntu**************************************
# Description:  install ssh, configure user/ip and so on
# ******************************************************************************
function configUbuntu()
{
    recordProcess "Process" "4/6(Install openssh in ubuntu)"
    # 1. install ssh
    mkdir squashfs-root/cdtmp
    mount -o bind $TMPDIR_DATE squashfs-root/cdtmp
    mv squashfs-root/etc/apt/sources.list squashfs-root/etc/apt/sources.list.bak
    touch squashfs-root/etc/apt/sources.list
    echo "deb file:/cdtmp xenial main restrict" > squashfs-root/etc/apt/sources.list
    cp ./chroot_install.sh ./squashfs-root
    chroot squashfs-root /bin/bash -c "./chroot_install.sh"
    umount squashfs-root/cdtmp
    rm -rf squashfs-root/cdtmp
    rm squashfs-root/chroot_install.sh

    recordProcess "Process" "5/6(Ubuntu user configure)"
    # 2. add user
    #echo "hisilicon:x:1000:0::/home/hisilicon:" >> squashfs-root/etc/passwd
    #echo "hisilicon:$6$Zlr1mw83$vw/cmjEg8vpvWj3Cenp9a78lmmx.b7UH2xVvTw32KWwLpwWGRMFb9Fiyw/DoxvaxWIQdz7CkUGjx/cujDkuQR/:17775:0:99999:7:::" >> squashfs-root/etc/shadow
    #cp -r squashfs-root/etc/skel squashfs-root/home/hisilicon
    #echo "hisilicon       ALL=(ALL:ALL) ALL" >> squashfs-root/etc/sudoers

    # 3. config host
    echo 'davinci-mini' > squashfs-root/etc/hostname
    echo '127.0.0.1        localhost davinci-mini' > squashfs-root/etc/hosts
    echo '127.0.1.1        davinci-mini' >> squashfs-root/etc/hosts

    # 4. config ip
    echo "source /etc/network/interfaces.d/*
    auto lo
    iface lo inet loopback
    
    auto eth0
    iface eth0 inet static
    address 192.168.0.2
    netmask 255.255.255.0
    gateway 192.168.0.1
    
    auto usb0
    iface usb0 inet static
    address 192.168.1.2
    netmask 255.255.255.0
    " > squashfs-root/etc/network/interfaces

    # 5. cp third party file 
    #cp ${ISO_FILE_DIR}/$RUN_MINI squashfs-root/var
    #cp ${ISO_FILE_DIR}/$RUN_3559 squashfs-root/var
	mkdir squashfs-root/home/hisilicon/newest_version
	cp ./newest_version/* squashfs-root/home/hisilicon/newest_version
    #cp ./minirc_cp.sh squashfs-root/home/hisilicon/newest_version
    #cp ./minirc_sys_init.sh squashfs-root/home/hisilicon/newest_version

	# 6. auto-run minirc_cp.sh and minirc_sys_init.sh when start ubuntu
	echo"#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.
cd /home/hisilicon/newest_version/

chmod +x /home/hisilicon/newest_version/minirc_cp.sh
/bin/bash /home/hisilicon/newest_version/minirc_cp.sh

chmod +x /home/hisilicon/newest_version/minirc_sys_init.sh
/bin/bash /home/hisilicon/newest_version/minirc_sys_init.sh

exit 0
" > squashfs-root/etc/rc.local

    recordProcess "Process" "6/6(Copy root filesystem to SDcard)"
    # 7. copy root filesystem and cleanup
    cp -a squashfs-root/* $TMPDIR_SD_MOUNT
    umount $TMPDIR_DATE
    rm -rf $TMPDIR_DATE
    rm -rf squashfs-root
    rm filesystem.squashfs
}
# end

# ************************Check args*******************************************
if [ $(id -u) -ne 0 ];then
    recordProcess "Failed" "Please change to root user"
    exit 1
fi

if [ $# -ne 5 ];then
    recordProcess "Failed" "ERROR parameter number! Usage: $0 <dev fullname> <img path> <iso fullname> <mini filename> <3559 filename>"
    exit 1;
fi
# end

# ************************Check the directory**********************************
if [ ! -d "$ISO_FILE_DIR" ];then
    recordProcess "Failed" "$ISO_FILE_DIR is not exist"
    exit 1
fi

if [ ! -b "$DEV_NAME" ];then
    recordProcess "Failed" "$DEV_NAME is not a block device file!"
    exit 1
fi
# end

# ************************SDcard format ***************************************
recordProcess "Process" "1/6(Start to format SDcard)"
if [ `ls -1 $DEV_NAME* 2>/dev/null | wc -l` -gt 1 ];then
    for i in `ls -1 $DEV_NAME*`; do
        echo "d

        w" | fdisk $DEV_NAME
    done
else
	echo "d

        w" | fdisk $DEV_NAME
fi
umount $DEV_NAME 2>/dev/null

echo "n




w" | fdisk $DEV_NAME

echo "y
" | mkfs.ext2 -L ubuntu_fs ${DEV_NAME}1
if [ $? -ne 0 ];then
     recordProcess "Failed" "Format SDcard fail!"
     exit 1;
fi   
# end

# output:squashfs-root/
recordProcess "Process" "2/6(Extract ubuntu root filesystem)"
ubuntufsExtract

# ************************Check architecture************************************
arch=`uname -m`
if [[ $arch =~ "x86" ]];then
     cp /usr/bin/qemu-aarch64-static squashfs-root/usr/bin/
fi
# end

# ************************Copy file to SDcard***********************************
if [ -d "$TMPDIR_SD_MOUNT" ];then
    umount $TMPDIR_SD_MOUNT 2>/dev/null
    rm -rf $TMPDIR_SD_MOUNT
fi

mkdir $TMPDIR_SD_MOUNT
mount ${DEV_NAME}1 $TMPDIR_SD_MOUNT 2>/dev/null
# config root filesystem
recordProcess "Process" "3/0(Configure ubuntu root filesystem)"
configUbuntu

umount $TMPDIR_SD_MOUNT 2>/dev/null
if [ $? -ne 0 ];then
    recordProcess "Failed" "\033[31mUmount $TMPDIR_SD_MOUNT to SDcard failed\033[0m"
    exit 1
else
	> make_ubuntu_sd.process
	echo "Success$" >> make_ubuntu_sd.process
fi
# end
