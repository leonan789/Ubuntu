#!/bin/sh

minirc_boot_log()
{
    cur_time=$(date +%Y-%m-%d,%H:%m:%s)
	if [ ! -e /var/davinci/log/boot.log ]; then
		mkdir -p /var/davinci/log
		echo "$cur_time  create log file" > /var/davinci/log/boot.log
	fi
    echo "$cur_time  $1" >> /var/davinci/log/boot.log
}

minirc_upgrade_log()
{
    cur_time=$(date +%Y-%m-%d,%H:%m:%s)
	if [ ! -e /var/davinci/log/upgrade.log ]; then
		mkdir -p /var/davinci/log
		echo "$cur_time  create log file" > /var/davinci/log/upgrade.log
	fi
    echo "$cur_time  $1" >> /var/davinci/log/upgrade.log
}

if [ ! -n "$1" ]; then
	RAR_FILE="/opt/mini/mini_oi.rar"
else
	RAR_FILE=$1
fi

INSTALL_CACHE_DIR="/tmp/mini/install_cache"

minirc_boot_log "mini boot start"

if [ ! -d ${INSTALL_CACHE_DIR} ]; then
	rm -rf ${INSTALL_CACHE_DIR}
fi

#extrack new version package
if [ -e ${RAR_FILE} ]; then
	minirc_upgrade_log "extrack package, file name:${RAR_FILE}"
	mkdir -p ${INSTALL_CACHE_DIR}
	unzip ${RAR_FILE} -d ${INSTALL_CACHE_DIR}
	if [ $? -ne 0 ]; then
		minirc_upgrade_log "extrack package(${RAR_FILE}) fail"
		rm -rf ${INSTALL_CACHE_DIR}
	else
		minirc_upgrade_log "extrack package succ"
    fi
fi

#check files
if [ ! -e ${INSTALL_CACHE_DIR}/mini_oi/sys_version.conf ]; then
    minirc_upgrade_log "mini upgrade fail, package file check fail"
	rm -rf ${INSTALL_CACHE_DIR}
else
	minirc_upgrade_log "no new version"
fi

#start to install new version
if [ -d ${INSTALL_CACHE_DIR} ]; then
	minirc_upgrade_log "start to install package"
	${INSTALL_CACHE_DIR}/mini_oi/scripts/minirc_install.sh >> /var/davinci/log/upgrade.log
	#É¾³ýrarÎÄ¼þ
	rm ${RAR_FILE}
fi

#mini start to init
if [ -e /var/davinci/scripts/minirc_sys_init.sh ]; then
	minirc_boot_log "system start to init"
	chmod +x /var/davinci/scripts/minirc_sys_init.sh
	/var/davinci/scripts/minirc_sys_init.sh
	minirc_boot_log "system init finish"
else
	minirc_boot_log "system init fail"
fi

#start to upgrade firmware 
if [ -e /var/davinci/scripts/minirc_firmware_upgrade.sh ]; then
	/var/davinci/scripts/minirc_firmware_upgrade.sh >> /var/davinci/log/upgrade.log
fi
