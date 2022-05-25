#!/bin/bash
#
#**********************************************************************************************
#Author:        Raymond
#QQ:            88563128
#Date:          2021-12-29
#FileName:      install_keepalived_backup.sh
#URL:           raymond.blog.csdn.net
#Description:   install_keepalived for CentOS 7/8 & Ubuntu 18.04/20.04 & Rocky 8
#Copyright (C): 2021 All rights reserved
#*********************************************************************************************
SRC_DIR=/usr/local/src
COLOR="echo -e \\033[01;31m"
END='\033[0m'
KEEPALIVED_URL=https://keepalived.org/software/
KEEPALIVED_FILE=keepalived-2.2.4.tar.gz
KEEPALIVED_INSTALL_DIR=/apps/keepalived
CPUS=`lscpu |awk '/^CPU\(s\)/{print $2}'`
NET_NAME=`ip addr |awk -F"[: ]" '/^2: e.*/{print $3}'`
STATE=BACKUP
PRIORITY=80
VIP=172.31.0.188


os(){
    OS_ID=`sed -rn '/^NAME=/s@.*="([[:alpha:]]+).*"$@\1@p' /etc/os-release`
    OS_ID_LOWER=`sed -rn '/^NAME=/s@.*="([[:alpha:]]+).*"$@\1@p' /etc/os-release | tr -t "[A-Z]" "[a-z]"`
    OS_RELEASE_VERSION=`sed -rn '/^VERSION_ID=/s@.*="?([0-9]+)\.?.*"?@\1@p' /etc/os-release`
}

check_file (){
    cd  ${SRC_DIR}
    if [ ${OS_ID} == "CentOS" -o ${OS_ID} == "Rocky" ] &> /dev/null;then
        rpm -q wget &> /dev/null || yum -y install wget &> /dev/null
    fi
    if [ ! -e ${KEEPALIVED_FILE} ];then
        ${COLOR}"缺少${KEEPALIVED_FILE}文件,如果是离线包,请把文件放到${SRC_DIR}目录下"${END}
        ${COLOR}'开始下载Keepalived源码包'${END}
        wget ${KEEPALIVED_URL}${KEEPALIVED_FILE} || { ${COLOR}"Keepalived源码包下载失败"${END}; exit; }
    else
        ${COLOR}"相关文件已准备好"${END}
    fi
}

install_keepalived(){
    [ -d ${KEEPALIVED_INSTALL_DIR} ] && { ${COLOR}"Keepalived已存在，安装失败"${END};exit; }
    ${COLOR}"开始安装Keepalived"${END}
    ${COLOR}"开始安装Keepalived依赖包"${END}
    if [ ${OS_ID} == "Rocky" -a ${OS_RELEASE_VERSION} == 8 ];then
        URL=mirrors.sjtug.sjtu.edu.cn
		if [ ! `grep -R "\[PowerTools\]" /etc/yum.repos.d/` ];then
            cat > /etc/yum.repos.d/PowerTools.repo <<-EOF
[PowerTools]
name=PowerTools
baseurl=https://${URL}/rocky/\$releasever/PowerTools/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial
EOF
        fi
    fi
    if [ ${OS_ID} == "CentOS" -a ${OS_RELEASE_VERSION} == 8 ];then
        URL=mirrors.cloud.tencent.com
        if [ ! `grep -R "\[PowerTools\]" /etc/yum.repos.d/` ];then
            cat > /etc/yum.repos.d/PowerTools.repo <<-EOF
[PowerTools]
name=PowerTools
baseurl=https://${URL}/centos/\$releasever/PowerTools/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        fi
    fi
    if [[ ${OS_RELEASE_VERSION} == 8 ]] &> /dev/null;then
        yum -y install make gcc ipvsadm autoconf automake openssl-devel libnl3-devel iptables-devel ipset-devel file-devel net-snmp-devel glib2-devel pcre2-devel libnftnl-devel libmnl-devel systemd-devel &> /dev/null
    elif [[ ${OS_RELEASE_VERSION} == 7 ]] &> /dev/null;then
        yum -y install make gcc libnfnetlink-devel libnfnetlink ipvsadm libnl libnl-devel libnl3 libnl3-devel lm_sensors-libs net-snmp-agent-libs net-snmp-libs openssh-server openssh-clients openssl openssl-devel automake iproute &> /dev/null
    elif [[ ${OS_RELEASE_VERSION} == 20 ]] &> /dev/null;then
        apt update &> /dev/null;apt -y install make gcc ipvsadm build-essential pkg-config automake autoconf libipset-dev libnl-3-dev libnl-genl-3-dev libssl-dev libxtables-dev libip4tc-dev libip6tc-dev libipset-dev libmagic-dev libsnmp-dev libglib2.0-dev libpcre2-dev libnftnl-dev libmnl-dev libsystemd-dev
    else
        apt update &> /dev/null;apt -y install make gcc ipvsadm build-essential pkg-config automake autoconf iptables-dev libipset-dev libnl-3-dev libnl-genl-3-dev libssl-dev libxtables-dev libip4tc-dev libip6tc-dev libipset-dev libmagic-dev libsnmp-dev libglib2.0-dev libpcre2-dev libnftnl-dev libmnl-dev libsystemd-dev &> /dev/null
    fi
    tar xf ${KEEPALIVED_FILE}
    KEEPALIVED_DIR=`echo ${KEEPALIVED_FILE} | sed -nr 's/^(.*[0-9]).([[:lower:]]).*/\1/p'`
    cd ${KEEPALIVED_DIR}
    ./configure --prefix=${KEEPALIVED_INSTALL_DIR} --disable-fwmark
    make -j $CPUS && make install
    [ $? -eq 0 ] && ${COLOR}"Keepalived编译安装成功"${END} ||  { ${COLOR}"Keepalived编译安装失败,退出!"${END};exit; }
    [ -d /etc/keepalived ] || mkdir -p /etc/keepalived &> /dev/null
    cat > /etc/keepalived/keepalived.conf <<EOF
! Configuration File for keepalived

global_defs {
   notification_email {
     acassen
   }
   notification_email_from Alexandre.Cassen@firewall.loc
   smtp_server 192.168.200.1
   smtp_connect_timeout 30
   router_id LVS_DEVEL
}

vrrp_instance VI_1 {
    state ${STATE}
    interface ${NET_NAME}
    garp_master_delay 10
    smtp_alert
    virtual_router_id 51
    priority ${PRIORITY}
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        ${VIP} dev ${NET_NAME} label ${NET_NAME}:1
    }
}
EOF
    cp ./keepalived/keepalived.service /lib/systemd/system/
    echo "PATH=${KEEPALIVED_INSTALL_DIR}/sbin:${PATH}" > /etc/profile.d/keepalived.sh
    systemctl daemon-reload
    systemctl enable --now keepalived &> /dev/null 
    systemctl is-active keepalived &> /dev/null && ${COLOR}"Keepalived 服务启动成功!"${END} ||  { ${COLOR}"Keepalived 启动失败,退出!"${END} ; exit; }
    ${COLOR}"Keepalived安装完成"${END}
}

main(){
    os
    check_file
    install_keepalived
}

main
