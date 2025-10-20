#!/bin/bash
#
#**********************************************************************************
#Author:        Raymond
#QQ:            88563128
#MP:            Raymond运维
#Date:          2025-10-19
#FileName:      remove_snap.sh
#URL:           https://wx.zsxq.com/group/15555885545422
#Description:   The remove snap script supports 
#               "Ubuntu Server 20.04, 22.04 and 24.04 LTS" operating systems.
#Copyright (C): 2025 All rights reserved
#**********************************************************************************
COLOR="echo -e \\033[01;31m"
END='\033[0m'
LOGIN_USER=`whoami`

os(){
    . /etc/os-release
    MAIN_NAME=`sed -rn '/^NAME=/s@.*="([[:alpha:]]+).*"$@\1@p' /etc/os-release`
    if [ ${MAIN_NAME} == "Kylin" ];then
        MAIN_VERSION_ID=`sed -rn '/^VERSION_ID=/s@.*="([[:alpha:]]+)(.*)"$@\2@p' /etc/os-release`
    else
        MAIN_VERSION_ID=`sed -rn '/^VERSION_ID=/s@.*="?([0-9]+)\.?.*"?@\1@p' /etc/os-release`
    fi
}

ubuntu_remove_snap(){
    dpkg -s snapd &> /dev/null || { ${COLOR}"snap已卸载！"${END};exit; }
    systemctl disable snapd.service && systemctl disable snapd.socket && systemctl disable snapd.seeded.service
    if [ ${MAIN_NAME} == "Ubuntu" ];then
        if [ ${MAIN_VERSION_ID} == 20 -o ${MAIN_VERSION_ID} == 22 ];then
            snap remove --purge lxd
            sum=$(snap list | awk 'NR>=2{print $1}' | wc -l)
            while [ $sum -ne 0 ];do
                for p in $(snap list | awk 'NR>=2{print $1}'); do
                    snap remove --purge $p
                done
                sum=$(snap list | awk 'NR>=2{print $1}' | wc -l)
            done
        fi
    fi
    apt -y autoremove --purge snapd
    rm -rf ~/snap && sudo rm -rf /snap && rm -rf /var/snap && rm -rf /var/lib/snapd && rm -rf /var/cache/snapd
    cat > /etc/apt/preferences.d/no-snapd.pref << EOF
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF
    apt update
    ${COLOR}"${PRETTY_NAME}操作系统，snap卸载完成！"${END}
}

main(){
    if [ ${LOGIN_USER} == "root" ];then
        ubuntu_remove_snap
    else
        ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录后再执行此脚本！"${END}
    fi
}

os
if [ ${MAIN_NAME} == "Ubuntu" ];then
    if [ ${MAIN_VERSION_ID} == 20 -o ${MAIN_VERSION_ID} == 22 -o ${MAIN_VERSION_ID} == 24 ];then
        main
    fi
else
    ${COLOR}"此脚本不支持${PRETTY_NAME}操作系统！"${END}
fi
