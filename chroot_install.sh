#!/bin/bash
# *****************************************************************************
# Function:     SDcard fabrication
# Description:  SDcard format, extract ubuntu filesystem from iso, and copy
#               (3559/mini).run file into "/var", "/" directory in SDcard.
# Date:         2018/09/03-v0.5
# Author:       nanweijia
# Input:        1.SDcard fullname(e.g:/dev/mmcblk1)
#               2.Path include ubuntu-xxx-server-arm64.iso and (3559/mini).run
#               3.iso filename(e.g:ubuntu-16.04.3-server-arm64.iso)
#               4.mini filename(e.g:xxx.run)
#               5.3559 filename(e.g:xxx.run)
# *****************************************************************************

apt-get update
apt-get install openssh-server -y
exit
# end
