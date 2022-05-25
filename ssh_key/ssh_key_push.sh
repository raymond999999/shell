#!/bin/bash
#
#**********************************************************************************************
#Author:        Raymond
#QQ:            88563128
#Date:          2021-11-19
#FileName:      ssh_key_push.sh
#URL:           raymond.blog.csdn.net
#Description:   ssh_key_push for CentOS 7/8 & Ubuntu 18.04/24.04 & Rocky 8
#Copyright (C): 2021 All rights reserved
#*********************************************************************************************
COLOR="echo -e \\033[01;31m"
END='\033[0m'

export SSHPASS=123456
HOSTS="
172.31.0.6
172.31.0.7
172.31.2.18
172.31.2.20"

os(){
    OS_ID=`sed -rn '/^NAME=/s@.*="([[:alpha:]]+).*"$@\1@p' /etc/os-release`
}

ssh_key_push(){
    rm -rf ~/.ssh/id_rsa*
    ssh-keygen -f /root/.ssh/id_rsa -P '' &> /dev/null
    if [ ${OS_ID} == "CentOS" -o ${OS_ID} == "Rocky" ] &> /dev/null;then
        rpm -q sshpass &> /dev/null || { ${COLOR}"安装sshpass软件包"${END};yum -y install sshpass &> /dev/null; }
    else
        dpkg -S sshpass &> /dev/null || { ${COLOR}"安装sshpass软件包"${END};apt -y install sshpass &> /dev/null; }
    fi
    for i in $HOSTS;do
        {
            sshpass -e ssh-copy-id -o StrictHostKeyChecking=no -i /root/.ssh/id_rsa.pub $i &> /dev/null
            [ $? -eq 0 ] && echo $i is finished || echo $i is false
        }&
    done
    wait
}

main(){
    os
    ssh_key_push
}

main
