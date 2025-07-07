#!/bin/bash
#
#**********************************************************************************
#Author:        Raymond
#QQ:            88563128
#Date:          2025-06-10
#FileName:      install_chrony_server_v3.sh
#MIRROR:        https://wx.zsxq.com/group/15555885545422
#Description:   The chrony server install script supports 
#               “Rocky Linux 8, 9 and 10, Almalinux 8, 9 and 10, CentOS 7, 
#               CentOS Stream 8, 9 and 10, Ubuntu 18.04, 20.04, 22.04 and 24.04, 
#               Debian 11 and 12, openEuler 22.03 and 24.03, AnolisOS 8 and 23, 
#               OpencloudOS 8 and 9, openSUSE 15, Kylin Server v10, 
#               Uos Server v20“ operating systems.
#Copyright (C): 2025 All rights reserved
#**********************************************************************************
COLOR="echo -e \\033[01;31m"
END='\033[0m'
NTP_SERVER1=ntp.aliyun.com
NTP_SERVER2=ntp.tencent.com
NTP_SERVER3=ntp.tuna.tsinghua.edu.cn

os(){
    . /etc/os-release
    MAIN_NAME=`sed -rn '/^NAME=/s@.*="([[:alpha:]]+).*"$@\1@p' /etc/os-release`
    if [ ${MAIN_NAME} == "Ubuntu" -o ${MAIN_NAME} == "Debian" ];then
        FULL_NAME="${PRETTY_NAME}"
    elif [ ${MAIN_NAME} == "UOS" ];then
        FULL_NAME="${NAME}"
    else
        FULL_NAME="${NAME} ${VERSION_ID}"
    fi
}

install_chrony(){
    if [ ${MAIN_NAME} == "Rocky" -o ${MAIN_NAME} == "AlmaLinux" -o ${MAIN_NAME} == "CentOS" -o ${MAIN_NAME} == "openEuler" -o ${MAIN_NAME} == "Anolis" -o ${MAIN_NAME} == "OpenCloudOS" -o ${MAIN_NAME} == "openSUSE" -o ${MAIN_NAME} == "Kylin" -o ${MAIN_NAME} == "UOS" ];then
        if [ ${MAIN_NAME} == "openSUSE" ];then
            INSTALL_TOOL='zypper'
        else
            INSTALL_TOOL='yum'
        fi
        rpm -q chrony &> /dev/null || { ${COLOR}"安装chrony包，请稍等......"${END};${INSTALL_TOOL} install -y chrony &> /dev/null; }
        if [ ${MAIN_NAME} == "OpenCloudOS" ];then
            sed -i -e '/^pool.*/d' -e '/^server.*/d' -e '/^# Use public.*/a\server '${NTP_SERVER1}' iburst\nserver '${NTP_SERVER2}' iburst\nserver '${NTP_SERVER3}' iburst' -e 's@^#allow.*@allow 0.0.0.0/0@' -e 's@^#local.*@local stratum 10@' /etc/chrony.conf
        else
            sed -i -e '/^pool.*/d' -e '/^server.*/d' -e '/^# Please consider .*/a\server '${NTP_SERVER1}' iburst\nserver '${NTP_SERVER2}' iburst\nserver '${NTP_SERVER3}' iburst' -e 's@^#allow.*@allow 0.0.0.0/0@' -e 's@^#local.*@local stratum 10@' /etc/chrony.conf
        fi
    else
        dpkg -s chrony &>/dev/null || { ${COLOR}"安装chrony包，请稍等......"${END};apt install -y chrony &> /dev/null; }
        if [ ${MAIN_NAME} == "Ubuntu" ];then
            sed -i -e '/^pool.*/d' -e '/^# See http:.*/a\server '${NTP_SERVER1}' iburst\nserver '${NTP_SERVER2}' iburst\nserver '${NTP_SERVER3}' iburst' /etc/chrony/chrony.conf
        else
            sed -i -e '/^pool.*/d' -e '/^# Use Debian.*/a\server '${NTP_SERVER1}' iburst\nserver '${NTP_SERVER2}' iburst\nserver '${NTP_SERVER3}' iburst' /etc/chrony/chrony.conf
        fi
        echo "allow 0.0.0.0/0" >> /etc/chrony/chrony.conf
        echo "local stratum 10" >> /etc/chrony/chrony.conf
    fi
    systemctl restart chronyd && systemctl enable --now chronyd &> /dev/null
    systemctl is-active chronyd &> /dev/null ||  { ${COLOR}"chrony 启动失败，退出！"${END} ; exit; }
    ${COLOR}"${FULL_NAME}操作系统，chrony服务端安装完成！"${END}
}

main(){
    os
    install_chrony
}

main
