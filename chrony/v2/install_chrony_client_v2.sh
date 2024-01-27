#!/bin/bash
#
#*************************************************************************************************************
#Author:        Raymond
#QQ:            88563128
#Date:          2024-01-19
#FileName:      install_chrony_client_v2.sh
#URL:           raymond.blog.csdn.net
#Description:   install_chrony_client for CentOS 7 & CentOS Stream 8/9 & Ubuntu 18.04/20.04/22.04 & Rocky 8/9
#Copyright (C): 2021 All rights reserved
#*************************************************************************************************************
COLOR="echo -e \\033[01;31m"
END='\033[0m'
SERVER=172.31.0.9

os(){
    OS_ID=`sed -rn '/^NAME=/s@.*="([[:alpha:]]+).*"$@\1@p' /etc/os-release`
}

install_chrony(){
    if [ ${OS_ID} == "CentOS" -o ${OS_ID} == "Rocky" ] &> /dev/null;then
        rpm -q chrony &> /dev/null || { ${COLOR}"安装chrony包，请稍等..."${END};yum -y install chrony &> /dev/null; }
        sed -i -e '/^pool.*/d' -e '/^server.*/d' -e '/^# Please consider .*/a\server '${SERVER}' iburst' /etc/chrony.conf
        systemctl restart chronyd && systemctl enable --now chronyd &> /dev/null
        systemctl is-active chronyd &> /dev/null ||  { ${COLOR}"chrony 启动失败,退出!"${END} ; exit; }
        ${COLOR}"chrony安装完成"${END}
    else
        dpkg -s chrony &>/dev/null || { ${COLOR}"安装chrony包，请稍等..."${END};apt -y install chrony &> /dev/null; }
        sed -i -e '/^pool.*/d' -e '/^# See http:.*/a\server '${SERVER}' iburst' /etc/chrony/chrony.conf
        systemctl restart chronyd && systemctl enable --now chronyd &> /dev/null
        systemctl is-active chronyd &> /dev/null ||  { ${COLOR}"chrony 启动失败,退出!"${END} ; exit; }
        ${COLOR}"chrony安装完成"${END}
    fi
}

main(){
    os
    install_chrony
}

main
