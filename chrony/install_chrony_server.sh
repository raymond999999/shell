#!/bin/bash
#
#**********************************************************************************************
#Author:        Raymond
#QQ:            88563128
#Date:          2021-11-22
#FileName:      install_chrony_server.sh
#URL:           raymond.blog.csdn.net
#Description:   install_chrony_server for CentOS 7/8 & Ubuntu 18.04/20.04 & Rocky 8
#Copyright (C): 2021 All rights reserved
#*********************************************************************************************
COLOR="echo -e \\033[01;31m"
END='\033[0m'

os(){
    OS_ID=`sed -rn '/^NAME=/s@.*="([[:alpha:]]+).*"$@\1@p' /etc/os-release`
}

install_chrony(){
    if [ ${OS_ID} == "CentOS" -o ${OS_ID} == "Rocky" ] &> /dev/null;then
        yum -y install chrony &> /dev/null
        sed -i -e '/^pool.*/d' -e '/^server.*/d' -e '/^# Please consider .*/a\server ntp.aliyun.com iburst\nserver time1.cloud.tencent.com iburst\nserver ntp.tuna.tsinghua.edu.cn iburst' -e 's@^#allow.*@allow 0.0.0.0/0@' -e 's@^#local.*@local stratum 10@' /etc/chrony.conf
        systemctl enable --now chronyd &> /dev/null
        systemctl is-active chronyd &> /dev/null ||  { ${COLOR}"chrony 启动失败,退出!"${END} ; exit; }
        ${COLOR}"chrony安装完成"${END}
    else
        apt -y install chrony &> /dev/null
        sed -i -e '/^pool.*/d' -e '/^# See http:.*/a\server ntp.aliyun.com iburst\nserver time1.cloud.tencent.com iburst\nserver ntp.tuna.tsinghua.edu.cn iburst' /etc/chrony/chrony.conf
        echo "allow 0.0.0.0/0" >> /etc/chrony/chrony.conf
        echo "local stratum 10" >> /etc/chrony/chrony.conf
        systemctl enable --now chronyd &> /dev/null
        systemctl is-active chronyd &> /dev/null ||  { ${COLOR}"chrony 启动失败,退出!"${END} ; exit; }
        ${COLOR}"chrony安装完成"${END}
    fi
}

main(){
    os
    install_chrony
}

main
