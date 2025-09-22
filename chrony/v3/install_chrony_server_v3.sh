#!/bin/bash
#
#**********************************************************************************
#Author:        Raymond
#QQ:            88563128
#MP:            Raymond运维
#Date:          2025-09-22
#FileName:      install_chrony_server_v3.sh
#URL:           https://wx.zsxq.com/group/15555885545422
#Description:   The chrony server script install supports 
#               “Rocky Linux 8, 9 and 10, AlmaLinux 8, 9 and 10, CentOS 7, 
#               CentOS Stream 8, 9 and 10, openEuler 22.03 and 24.03 LTS, 
#               AnolisOS 8 and 23, OpenCloudOS 8 and 9, Kylin Server v10 and v11, 
#               UOS Server v20, Ubuntu Server 18.04, 20.04, 22.04 and 24.04 LTS,  
#               Debian 11 , 12 and 13, openSUSE Leap 15“ operating systems.
#Copyright (C): 2025 All rights reserved
#**********************************************************************************
COLOR="echo -e \\033[01;31m"
END='\033[0m'

os(){
    . /etc/os-release
    MAIN_NAME=`sed -rn '/^NAME=/s@.*="([[:alpha:]]+).*"$@\1@p' /etc/os-release`
    if [ ${MAIN_NAME} == "Kylin" ];then
        MAIN_VERSION_ID=`sed -rn '/^VERSION_ID=/s@.*="([[:alpha:]]+)(.*)"$@\2@p' /etc/os-release`
    else
        MAIN_VERSION_ID=`sed -rn '/^VERSION_ID=/s@.*="?([0-9]+)\.?.*"?@\1@p' /etc/os-release`
    fi
    if [ ${MAIN_NAME} == "Ubuntu" -o ${MAIN_NAME} == "Debian" ];then
        FULL_NAME="${PRETTY_NAME}"
    elif [ ${MAIN_NAME} == "UOS" ];then
        FULL_NAME="${NAME}"
    else
        FULL_NAME="${NAME} ${VERSION_ID}"
    fi
}

os
NTP_SERVER1=ntp.aliyun.com
NTP_SERVER2=ntp.tencent.com
NTP_SERVER3=ntp.tuna.tsinghua.edu.cn

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
    install_chrony
}

if [ ${MAIN_NAME} == "Rocky" ];then
    if [ ${MAIN_VERSION_ID} == 8 -o ${MAIN_VERSION_ID} == 9 -o ${MAIN_VERSION_ID} == 10 ];then
        main
    fi
elif [ ${MAIN_NAME} == "AlmaLinux" ];then
    if [ ${MAIN_VERSION_ID} == 8 -o ${MAIN_VERSION_ID} == 9 -o ${MAIN_VERSION_ID} == 10 ];then
        main
    fi
elif [ ${MAIN_NAME} == "CentOS" ];then
    if [ ${MAIN_VERSION_ID} == 7 -o ${MAIN_VERSION_ID} == 8 -o ${MAIN_VERSION_ID} == 9 -o ${MAIN_VERSION_ID} == 10 ];then
        main
    fi
elif [ ${MAIN_NAME} == "openEuler" ];then
    if [ ${MAIN_VERSION_ID} == 22 -o ${MAIN_VERSION_ID} == 24 ];then
        main
    fi
elif [ ${MAIN_NAME} == "Anolis" ];then
    if [ ${MAIN_VERSION_ID} == 8 -o ${MAIN_VERSION_ID} == 23 ];then
        main
    fi
elif [ ${MAIN_NAME} == 'OpenCloudOS' ];then
    if [ ${MAIN_VERSION_ID} == 8 -o ${MAIN_VERSION_ID} == 9 ];then
        main
    fi
elif [ ${MAIN_NAME} == "Kylin" ];then
    if [ ${MAIN_VERSION_ID} == 10 -o ${MAIN_VERSION_ID} == 11 ];then
        main
    fi
elif [ ${MAIN_NAME} == "UOS" ];then
    if [ ${MAIN_VERSION_ID} == 20 ];then
        main
    fi
elif [ ${MAIN_NAME} == "openSUSE" ];then
    if [ ${MAIN_VERSION_ID} == 15 ];then
        main
    fi
elif [ ${MAIN_NAME} == "Ubuntu" ];then
    if [ ${MAIN_VERSION_ID} == 18 -o ${MAIN_VERSION_ID} == 20 -o ${MAIN_VERSION_ID} == 22 -o ${MAIN_VERSION_ID} == 24 ];then
        main
    fi
elif [ ${MAIN_NAME} == 'Debian' ];then
    if [ ${MAIN_VERSION_ID} == 11 -o ${MAIN_VERSION_ID} == 12 -o ${MAIN_VERSION_ID} == 13 ];then
        main
    fi
else
    ${COLOR}"此脚本不支持${FULL_NAME}操作系统！"${END}
fi
