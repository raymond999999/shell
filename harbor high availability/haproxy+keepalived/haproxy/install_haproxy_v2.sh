#!/bin/bash
#
#************************************************************************************************************
#Author:        Raymond
#QQ:            88563128
#Date:          2024-01-30
#FileName:      install_haproxy_v2.sh
#URL:           raymond.blog.csdn.net
#Description:   install_haproxy for CentOS 7 & CentOS Stream 8/9 & Ubuntu 18.04/20.04/22.04 & Rocky 8/9
#Copyright (C): 2024 All rights reserved
#************************************************************************************************************
SRC_DIR=/usr/local/src
COLOR="echo -e \\033[01;31m"
END='\033[0m'
CPUS=`lscpu |awk '/^CPU\(s\)/{print $2}'`

#lua下载地址：”https://www.lua.org/ftp/lua-5.4.6.tar.gz“，请提前下载。
LUA_FILE=lua-5.4.6.tar.gz

#haproxy下载地址：“https://www.haproxy.org/download/2.8/src/haproxy-2.8.5.tar.gz”，请提前下载。
HAPROXY_FILE=haproxy-2.8.5.tar.gz
HAPROXY_INSTALL_DIR=/apps/haproxy
STATS_AUTH_USER=admin
STATS_AUTH_PASSWORD=123456
VIP=172.31.3.188
HARBOR01=172.31.3.106
HARBOR02=172.31.3.107

os(){
    OS_ID=`sed -rn '/^NAME=/s@.*="([[:alpha:]]+).*"$@\1@p' /etc/os-release`
}

check_file (){
    cd ${SRC_DIR}
    ${COLOR}'检查Haproxy相关源码包'${END}
    if [ ! -e ${LUA_FILE} ];then
        ${COLOR}"缺少${LUA_FILE}文件,请把文件放到${SRC_DIR}目录下"${END}
        exit
    elif [ ! -e ${HAPROXY_FILE} ];then
        ${COLOR}"缺少${HAPROXY_FILE}文件,请把文件放到${SRC_DIR}目录下"${END}
        exit
    else
        ${COLOR}"相关文件已准备好"${END}
    fi
}

install_haproxy(){
    [ -d ${HAPROXY_INSTALL_DIR} ] && { ${COLOR}"Haproxy已存在，安装失败"${END};exit; }
    ${COLOR}"开始安装Haproxy"${END}
    ${COLOR}"开始安装Haproxy依赖包，请稍等..."${END}
    if [ ${OS_ID} == "CentOS" -o ${OS_ID} == "Rocky" ] &> /dev/null;then
        yum -y install gcc make readline-devel openssl-devel pcre-devel systemd-devel zlib-devel &> /dev/null
    else
        apt update &> /dev/null;apt -y install gcc make libreadline-dev openssl libssl-dev libpcre3 libpcre3-dev zlib1g-dev libsystemd-dev &> /dev/null
    fi
    tar xf ${LUA_FILE}
    LUA_DIR=`echo ${LUA_FILE} | sed -nr 's/^(.*[0-9]).([[:lower:]]).*/\1/p'`
    cd ${LUA_DIR}
    make linux test
    cd ${SRC_DIR}
    tar xf ${HAPROXY_FILE}
    HAPROXY_DIR=`echo ${HAPROXY_FILE} | sed -nr 's/^(.*[0-9]).([[:lower:]]).*/\1/p'`
    cd ${HAPROXY_DIR}
    make -j ${CPUS} ARCH=x86_64 TARGET=linux-glibc USE_PCRE=1 USE_OPENSSL=1 USE_ZLIB=1 USE_SYSTEMD=1 USE_CPU_AFFINITY=1 USE_LUA=1 LUA_INC=${SRC_DIR}/${LUA_DIR}/src/ LUA_LIB=${SRC_DIR}/${LUA_DIR}/src/
    make install PREFIX=${HAPROXY_INSTALL_DIR}
    [ $? -eq 0 ] && $COLOR"Haproxy编译安装成功"$END ||  { $COLOR"Haproxy编译安装失败,退出!"$END;exit; }
    [ -L /usr/sbin/haproxy ] || ln -s ../..${HAPROXY_INSTALL_DIR}/sbin/haproxy /usr/sbin/ &> /dev/null
    cat > /lib/systemd/system/haproxy.service <<-EOF
[Unit]
Description=HAProxy Load Balancer
After=syslog.target network.target

[Service]
ExecStartPre=/usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg -c -q
ExecStart=/usr/sbin/haproxy -Ws -f /etc/haproxy/haproxy.cfg -p /var/lib/haproxy/haproxy.pid
ExecReload=/bin/kill -USR2 $MAINPID

[Install]
WantedBy=multi-user.target
EOF
    [ -d /etc/haproxy ] || mkdir /etc/haproxy &> /dev/null 
    cat > /etc/haproxy/haproxy.cfg <<-EOF
global
    maxconn 100000
    chroot ${HAPROXY_INSTALL_DIR}
    stats socket /var/lib/haproxy/haproxy.sock mode 600 level admin
    user haproxy
    group haproxy
    daemon
    pidfile /var/lib/haproxy/haproxy.pid
    log 127.0.0.1 local2 info

defaults
    option http-keep-alive
    option forwardfor
    maxconn 100000
    mode http
    timeout connect 300000ms
    timeout client 300000ms
    timeout server 300000ms

listen stats
    mode http
    bind 0.0.0.0:9999
    stats enable
    log global
    stats uri /haproxy-status
    stats auth ${STATS_AUTH_USER}:${STATS_AUTH_PASSWORD}

listen harbor-80
    bind ${VIP}:80
    mode http
    log global
    balance source
    server ${HARBOR01} ${HARBOR01}:80 check inter 3s fall 2 rise 5
    server ${HARBOR02} ${HARBOR02}:80 check inter 3s fall 2 rise 5
EOF
    cat >> /etc/sysctl.conf <<-EOF
net.ipv4.ip_nonlocal_bind = 1
EOF
    sysctl -p &> /dev/null 
    [ -d /var/lib/haproxy/ ] || mkdir -p /var/lib/haproxy/ &> /dev/null
    useradd -r -s /sbin/nologin -d /var/lib/haproxy haproxy
    systemctl daemon-reload
    systemctl enable --now haproxy &> /dev/null
    systemctl is-active haproxy &> /dev/null && ${COLOR}"Haproxy 服务启动成功!"${END} ||  { ${COLOR}"Haproxy 启动失败,退出!"${END} ; exit; }
    ${COLOR}"Haproxy安装完成"${END}
}

main(){
    os
    check_file
    install_haproxy
}

main
