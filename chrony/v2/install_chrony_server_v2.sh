#!/bin/bash
#
#**********************************************************************************
#Author:        Raymond
#QQ:            88563128
#Date:          2025-04-10
#FileName:      install_chrony_server_v2.sh
#MIRROR:        https://wx.zsxq.com/group/15555885545422
#Description:   The chrony server install script supports 
#               “Rocky Linux 8 and 9, Almalinux 8 and 9, CentOS 7, 
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
    OS_ID=`sed -rn '/^NAME=/s@.*="([[:alpha:]]+).*"$@\1@p' /etc/os-release`
}

install_chrony(){
    if [ ${OS_ID} == "Rocky" -o ${OS_ID} == "AlmaLinux" -o ${OS_ID} == "CentOS" -o ${OS_ID} == "openEuler" -o ${OS_ID} == "Anolis" -o ${OS_ID} == "OpenCloudOS" -o ${OS_ID} == "openSUSE" -o ${OS_ID} == "Kylin" -o ${OS_ID} == "UOS" ];then
        if [ ${OS_ID} == "openSUSE" ];then
            INSTALL_TOOL='zypper'
        else
            INSTALL_TOOL='yum'
        fi
        rpm -q chrony &> /dev/null || { ${COLOR}"安装chrony包，请稍等..."${END};${INSTALL_TOOL} install -y chrony &> /dev/null; }
        if [ ${OS_ID} == "OpenCloudOS" ];then
            sed -i -e '/^pool.*/d' -e '/^server.*/d' -e '/^# Use public.*/a\server '${NTP_SERVER1}' iburst\nserver '${NTP_SERVER2}' iburst\nserver '${NTP_SERVER3}' iburst' -e 's@^#allow.*@allow 0.0.0.0/0@' -e 's@^#local.*@local stratum 10@' /etc/chrony.conf
        else
            sed -i -e '/^pool.*/d' -e '/^server.*/d' -e '/^# Please consider .*/a\server '${NTP_SERVER1}' iburst\nserver '${NTP_SERVER2}' iburst\nserver '${NTP_SERVER3}' iburst' -e 's@^#allow.*@allow 0.0.0.0/0@' -e 's@^#local.*@local stratum 10@' /etc/chrony.conf
        fi
    else
        dpkg -s chrony &>/dev/null || { ${COLOR}"安装chrony包，请稍等..."${END};apt install -y chrony &> /dev/null; }
        if [ ${OS_ID} == "Ubuntu" ];then
            sed -i -e '/^pool.*/d' -e '/^# See http:.*/a\server '${NTP_SERVER1}' iburst\nserver '${NTP_SERVER2}' iburst\nserver '${NTP_SERVER3}' iburst' /etc/chrony/chrony.conf
        else
            sed -i -e '/^pool.*/d' -e '/^# Use Debian.*/a\server '${NTP_SERVER1}' iburst\nserver '${NTP_SERVER2}' iburst\nserver '${NTP_SERVER3}' iburst' /etc/chrony/chrony.conf
        fi
        echo "allow 0.0.0.0/0" >> /etc/chrony/chrony.conf
        echo "local stratum 10" >> /etc/chrony/chrony.conf
    fi
    systemctl restart chronyd && systemctl enable --now chronyd &> /dev/null
    systemctl is-active chronyd &> /dev/null ||  { ${COLOR}"chrony 启动失败,退出!"${END} ; exit; }
    ${COLOR}"chrony安装完成"${END}
}

main(){
    os
    install_chrony
}

main
