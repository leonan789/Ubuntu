#!/bin/bash
# *****************************************************************************
# Function:     SDcard fabrication
# Description:  SDcard format, extract ubuntu filesystem from iso, and copy
#               (3559/mini).run file into "/var", "/" directory in SDcard.
# Date:         2018/09/18-v1.18
# Author:       nanweijia
# Input:        1.SDcard fullname(e.g:/dev/sda)
#               2.Path include ubuntu-xxx-server-arm64.iso and (3559/mini).rar
#               3.iso filename(e.g:ubuntu-16.04.3-server-arm64.iso)
#               4.mini filename(e.g:xxx.rar)
# *****************************************************************************

# ************************Variable*********************************************
ScriptPath=`dirname $0`
ScriptPath=`cd $ScriptPath;pwd`
DEV_NAME=$1
ISO_FILE_DIR=$2
ISO_FILE=$3
RUN_MINI=$4
DATE=`date +"%F %X"`
TMPDIR_SD_MOUNT=sd_mount_dir
TMPDIR_DATE=`date +"%y%m%d%H%M%S"`
# end

# ************************Record Process***************************************
# Description:  Record running process or result
# Input:        1.level: Process/Failed 2.message: Step/Reason
# *****************************************************************************
function recordProcess()
{
    level=$1
    msg=$2
    > $ScriptPath/make_ubuntu_sd.process
    echo -e "${level}:${msg}$" >> $ScriptPath/make_ubuntu_sd.process
}
# end recordProcess()

# ************************Extract ubuntufs from iso*****************************
# Description:  mount iso file , extract root filesystem from squashfs, after
# execute function it will create squashfs-root/ in "./"
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
    recordProcess "Process" "2/3(Install software in ubuntu)"
    # 1. install software
    mkdir -p squashfs-root/cdtmp
    mount -o bind $TMPDIR_DATE squashfs-root/cdtmp
    mv squashfs-root/etc/apt/sources.list squashfs-root/etc/apt/sources.list.bak
    touch squashfs-root/etc/apt/sources.list
    echo "deb file:/cdtmp xenial main restrict" > squashfs-root/etc/apt/sources.list
    cp $ScriptPath/chroot_install.sh ./squashfs-root
    chroot squashfs-root /bin/bash -c "./chroot_install.sh"
    umount squashfs-root/cdtmp
    rm -rf squashfs-root/cdtmp
    rm squashfs-root/chroot_install.sh
    mv squashfs-root/etc/apt/sources.list.bak squashfs-root/etc/apt/sources.list

    # 2. add user
    # execute in ./chroot_install.sh

    # 3. config host
    echo 'davinci-mini' > squashfs-root/etc/hostname
    echo '127.0.0.1        localhost' > squashfs-root/etc/hosts
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
    mkdir -p squashfs-root/opt/mini
    cp ${ISO_FILE_DIR}/$RUN_MINI squashfs-root/opt/mini
    cp $ScriptPath/minirc_boot.sh squashfs-root/var
    if [ $? -ne 0 ];then
        recordProcess "Failed" "\033[31mCopy minirc_boot.sh to filesystem failed\033[0m"
        exit 1
    fi


    # 6. auto-run minirc_cp.sh and minirc_sys_init.sh when start ubuntu
    echo "#!/bin/sh -e
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
cd /var/

chmod +x /var/minirc_boot.sh
/bin/bash /var/minirc_boot.sh /opt/mini/$RUN_MINI

exit 0
" > squashfs-root/etc/rc.local

    recordProcess "Process" "3/3(Copy root filesystem to SDcard)"
    # 7. copy root filesystem and cleanup
    if [[ $arch =~ "x86" ]];then
        rm squashfs-root/usr/bin/qemu-aarch64-static
    fi
    cp -a squashfs-root/* $TMPDIR_SD_MOUNT
    if [ $? -ne 0 ];then
        recordProcess "Failed" "\033[31mCopy root filesystem to SDcard failed\033[0m"
        exit 1
    fi

    umount $TMPDIR_DATE
    rm -rf $TMPDIR_DATE
    rm -rf squashfs-root
    rm filesystem.squashfs
}
# end

# ########################Begin Executing######################################
# ************************Check args*******************************************
if [ $(id -u) -ne 0 ];then
    recordProcess "Failed" "Please change to root user"
    exit 1
fi

if [ $# -ne 4 ];then
    recordProcess "Failed" "ERROR parameter number! Usage: $0 <dev fullname> <img path> <iso fullname> <mini filename>"
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
recordProcess "Process" "1/3(Start to format SDcard)"
sdmnt=`df -h | grep $DEV_NAME | grep /media* | awk '{print $6}'`
umount $sdmnt
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
" | mkfs.ext3 -L ubuntu_fs ${DEV_NAME}1
if [ $? -ne 0 ];then
     recordProcess "Failed" "Format SDcard fail!"
     exit 1;
fi
# end

# output:squashfs-root/
ubuntufsExtract

# ************************Check architecture************************************
arch=`uname -m`
if [[ $arch =~ "x86" ]];then
     cp /usr/bin/qemu-aarch64-static squashfs-root/usr/bin/
     if [ $? -ne 0 ];then
         recordProcess "Failed" "qemu-user-static and binfmt-support should be installed!"
         exit 1;
     fi
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
configUbuntu

umount $TMPDIR_SD_MOUNT 2>/dev/null
if [ $? -ne 0 ];then
    recordProcess "Failed" "\033[31mUmount $TMPDIR_SD_MOUNT to SDcard failed\033[0m"
    exit 1
else
    > $ScriptPath/make_ubuntu_sd.process
    echo "Success$" >> $ScriptPath/make_ubuntu_sd.process
fi
# end
