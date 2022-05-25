#!/bin/bash
#
#**********************************************************************************************
#Author:        Raymond
#QQ:            88563128
#Date:          2021-12-20
#FileName:      ssh_key.sh
#URL:           raymond.blog.csdn.net
#Description:   ssh_key for CentOS 7/8 & Ubuntu 18.04/24.04 & Rocky 8
#Copyright (C): 2021 All rights reserved
#*********************************************************************************************
#基于key验证多主机ssh互相访问
COLOR="echo -e \\033[01;31m"
END='\033[0m'
PASS=123456
#设置网段最后的地址，4-255之间，越小扫描越快
END=254

IP=`ip a s eth0 | awk -F'[ /]+' 'NR==3{print $3}'`
NET=${IP%.*}.

os(){
    OS_ID=`sed -rn '/^NAME=/s@.*="([[:alpha:]]+).*"$@\1@p' /etc/os-release`
}

ssh_key_push(){
    rm -f /root/.ssh/id_rsa
    [ -e ./SCANIP.log ] && rm -f SCANIP.log
    for((i=3;i<="$END";i++));do
        ping -c 1 -w 1  ${NET}${i} &> /dev/null  && echo "${NET}${i}" >> SCANIP.log &
    done
    wait
    ssh-keygen -f /root/.ssh/id_rsa -P '' &> /dev/null
    if [ ${OS_ID} == "CentOS" -o ${OS_ID} == "Rocky" ] &> /dev/null;then
        rpm -q sshpass &> /dev/null || { ${COLOR}"安装sshpass软件包"${END};yum -y install sshpass &> /dev/null; }
    else
        dpkg -S sshpass &> /dev/null || { ${COLOR}"安装sshpass软件包"${END};apt -y install sshpass &> /dev/null; }
    fi
    sshpass -p ${PASS} ssh-copy-id -o StrictHostKeyChecking=no ${IP} 

    AliveIP=(`cat SCANIP.log`)
    for n in ${AliveIP[*]};do
        sshpass -p $PASS scp -o StrictHostKeyChecking=no -r /root/.ssh root@${n}:
    done

    #把.ssh/known_hosts拷贝到所有主机，使它们第一次互相访问时不需要输入回车
    for n in ${AliveIP[*]};do
        scp /root/.ssh/known_hosts ${n}:.ssh/
    done
}

main(){
    os
    ssh_key_push
}

main