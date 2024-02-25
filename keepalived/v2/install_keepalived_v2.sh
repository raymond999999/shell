#!/bin/bash
#
#************************************************************************************************************
#Author:        Raymond
#QQ:            88563128
#Date:          2024-01-26
#FileName:      install_keepalived_v2.sh
#URL:           raymond.blog.csdn.net
#Description:   install_keepalived for CentOS 7 & CentOS Stream 8/9 & Ubuntu 18.04/20.04/22.04 & Rocky 8/9
#Copyright (C): 2024 All rights reserved
#************************************************************************************************************
SRC_DIR=/usr/local/src
COLOR="echo -e \\033[01;31m"
END='\033[0m'
KEEPALIVED_URL=https://keepalived.org/software/
KEEPALIVED_FILE=keepalived-2.2.8.tar.gz
KEEPALIVED_INSTALL_DIR=/apps/keepalived
CPUS=`lscpu |awk '/^CPU\(s\)/{print $2}'`
NET_NAME=`ip a |awk -F"[: ]" '/^2/{print $3}'`
VIP=172.31.0.180

os(){
    OS_ID=`sed -rn '/^NAME=/s@.*="([[:alpha:]]+).*"$@\1@p' /etc/os-release`
    OS_RELEASE_VERSION=`sed -rn '/^VERSION_ID=/s@.*="?([0-9]+)\.?.*"?@\1@p' /etc/os-release`
}

check_file (){
    cd  ${SRC_DIR}
    if [ ${OS_ID} == "CentOS" -o ${OS_ID} == "Rocky" ] &> /dev/null;then
        rpm -q wget &> /dev/null || { ${COLOR}"安装wget工具，请稍等..."${END};yum -y install wget &> /dev/null; }
    fi
    if [ ! -e ${KEEPALIVED_FILE} ];then
        ${COLOR}"缺少${KEEPALIVED_FILE}文件,如果是离线包,请放到${SRC_DIR}目录下"${END}
        ${COLOR}'开始下载Keepalived源码包'${END}
        wget ${KEEPALIVED_URL}${KEEPALIVED_FILE} || { ${COLOR}"Keepalived源码包下载失败"${END}; exit; }
    else
        ${COLOR}"${KEEPALIVED_FILE}文件已准备好"${END}
    fi
}

install_keepalived(){
    ${COLOR}"开始安装Keepalived，请稍等..."${END}
    ${COLOR}"开始安装Keepalived依赖包，请稍等..."${END}
    if [ ${OS_ID} == "Rocky" -a ${OS_RELEASE_VERSION} == 8 ];then
        MIRROR=mirrors.sjtug.sjtu.edu.cn
        if [ `grep -R "\[powertools\]" /etc/yum.repos.d/*.repo` ];then
            dnf config-manager --set-enabled powertools
        else
            cat > /etc/yum.repos.d/PowerTools.repo <<-EOF
[PowerTools]
name=PowerTools
baseurl=https://${MIRROR}/rocky/\$releasever/PowerTools/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial
EOF
        fi
    fi
    if [ ${OS_ID} == "CentOS" -a ${OS_RELEASE_VERSION} == 8 ];then
        MIRROR=mirrors.aliyun.com
        if [ `grep -R "\[powertools\]" /etc/yum.repos.d/*.repo` ];then
            dnf config-manager --set-enabled powertools
        else
            cat > /etc/yum.repos.d/PowerTools.repo <<-EOF
[PowerTools]
name=PowerTools
baseurl=https://${MIRROR}/centos/\$stream/PowerTools/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        fi
    fi
    if [ ${OS_RELEASE_VERSION} == 9 ];then
        yum -y install make gcc ipvsadm autoconf automake openssl-devel libnl3-devel iptables-devel ipset file net-snmp-devel glib2-devel pcre2-devel libnftnl libmnl systemd-devel &> /dev/null
    elif [ ${OS_RELEASE_VERSION} == 8 ];then	
        yum -y install make gcc ipvsadm autoconf automake openssl-devel libnl3-devel iptables-devel ipset-devel file-devel net-snmp-devel glib2-devel pcre2-devel libnftnl-devel libmnl-devel systemd-devel &> /dev/null
    elif [ ${OS_RELEASE_VERSION} == 7 ];then
        yum -y install make gcc libnfnetlink-devel libnfnetlink ipvsadm libnl libnl-devel libnl3 libnl3-devel lm_sensors-libs net-snmp-agent-libs net-snmp-libs openssh-server openssh-clients openssl openssl-devel automake iproute &> /dev/null
    elif [ ${OS_RELEASE_VERSION} == "20" -o ${OS_RELEASE_VERSION} == "22" ];then
        apt update &> /dev/null;apt -y install make gcc ipvsadm build-essential pkg-config automake autoconf libipset-dev libnl-3-dev libnl-genl-3-dev libssl-dev libxtables-dev libip4tc-dev libip6tc-dev libipset-dev libmagic-dev libsnmp-dev libglib2.0-dev libpcre2-dev libnftnl-dev libmnl-dev libsystemd-dev
    else
        apt update &> /dev/null;apt -y install make gcc ipvsadm build-essential pkg-config automake autoconf iptables-dev libipset-dev libnl-3-dev libnl-genl-3-dev libssl-dev libxtables-dev libip4tc-dev libip6tc-dev libipset-dev libmagic-dev libsnmp-dev libglib2.0-dev libpcre2-dev libnftnl-dev libmnl-dev libsystemd-dev &> /dev/null
    fi
    tar xf ${KEEPALIVED_FILE}
    KEEPALIVED_DIR=`echo ${KEEPALIVED_FILE} | sed -nr 's/^(.*[0-9]).*/\1/p'`
    cd ${KEEPALIVED_DIR}
    ./configure --prefix=${KEEPALIVED_INSTALL_DIR} --disable-fwmark
    make -j $CPUS && make install
    [ $? -eq 0 ] && $COLOR"Keepalived编译安装成功"$END ||  { $COLOR"Keepalived编译安装失败,退出!"$END;exit; }
    [ -d /etc/keepalived ] || mkdir -p /etc/keepalived &> /dev/null
    read -p "请输入是主服务端或备用服务端，例如（MASTER或BACKUP）: " STATE
    read -p "请输入优先级，例如（100或80）: " PRIORITY
    cat > /etc/keepalived/keepalived.conf <<EOF
! Configuration File for keepalived

global_defs {
   notification_email {
     acassen@firewall.loc
     failover@firewall.loc
     sysadmin@firewall.loc
   }
   notification_email_from Alexandre.Cassen@firewall.loc
   smtp_server 192.168.200.1
   smtp_connect_timeout 30
   router_id LVS_DEVEL
   vrrp_skip_check_adv_addr
   vrrp_strict
   vrrp_garp_interval 0
   vrrp_gna_interval 0
}

vrrp_instance VI_1 {
    state ${STATE}
    interface ${NET_NAME}
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
    systemctl is-active keepalived &> /dev/null ||  { ${COLOR}"Keepalived 启动失败,退出!"${END} ; exit; }
    ${COLOR}"Keepalived安装完成"${END}
}

main(){
    os
    check_file
    install_keepalived
}

main
