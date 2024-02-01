#!/bin/bash
#
#************************************************************************************************************
#Author:        Raymond
#QQ:            88563128
#Date:          2024-01-31
#FileName:      install_nginx.sh
#URL:           raymond.blog.csdn.net
#Description:   install_haproxy for CentOS 7 & CentOS Stream 8/9 & Ubuntu 18.04/20.04/22.04 & Rocky 8/9
#Copyright (C): 2024 All rights reserved
#************************************************************************************************************
SRC_DIR=/usr/local/src
COLOR="echo -e \\033[01;31m"
END='\033[0m'

NGINX_URL=https://nginx.org/download/
NGINX_FILE=nginx-1.24.0.tar.gz
NGINX_INSTALL_DIR=/apps/nginx
CPUS=`lscpu |awk '/^CPU\(s\)/{print $2}'`

os(){
    OS_ID=`sed -rn '/^NAME=/s@.*="([[:alpha:]]+).*"$@\1@p' /etc/os-release`
}

check_file (){
    cd ${SRC_DIR}
    if [ ${OS_ID} == "CentOS" -o ${OS_ID} == "Rocky" ] &> /dev/null;then
        rpm -q wget &> /dev/null || { ${COLOR}"安装wget工具，请稍等..."${END};yum -y install wget &> /dev/null; }
    fi
    if [ ! -e ${NGINX_FILE} ];then
        ${COLOR}"缺少${NGINX_FILE}文件"${END}
        ${COLOR}'开始下载Nginx源码包'${END}
        wget ${NGINX_URL}${NGINX_FILE} || { ${COLOR}"Nginx源码包下载失败"${END}; exit; }
    else
        ${COLOR}"${NGINX_FILE}文件已准备好"${END}       
    fi
} 

install_nginx(){
    [ -d ${NGINX_INSTALL_DIR} ] && { ${COLOR}"Nginx已存在，安装失败"${END};exit; }
    ${COLOR}"开始安装Nginx"${END}
    ${COLOR}"开始安装Nginx依赖包，请稍等..."${END}
    if [ ${OS_ID} == "CentOS" -o ${OS_ID} == "Rocky" ] &> /dev/null;then
        yum -y install make gcc pcre-devel openssl-devel zlib-devel &> /dev/null
    else
        apt update &> /dev/null;apt -y install make gcc libpcre3 libpcre3-dev openssl libssl-dev zlib1g-dev &> /dev/null
    fi
    id nginx  &> /dev/null || { useradd -s /sbin/nologin -r nginx; ${COLOR}"创建Nginx用户"${END}; }
    if [ ${OS_ID} == "CentOS" -o ${OS_ID} == "Rocky" ] &> /dev/null;then
        rpm -q tar &> /dev/null || { ${COLOR}"安装tar工具，请稍等..."${END};yum -y install tar &> /dev/null; }
    fi
    tar xf ${NGINX_FILE}
    NGINX_DIR=`echo ${NGINX_FILE}| sed -nr 's/^(.*[0-9]).*/\1/p'`
    cd ${NGINX_DIR}
    ./configure --prefix=${NGINX_INSTALL_DIR} --user=nginx --group=nginx --with-http_ssl_module --with-http_v2_module --with-http_realip_module --with-http_stub_status_module --with-http_gzip_static_module --with-pcre --with-stream --with-stream_ssl_module --with-stream_realip_module 
    make -j ${CPUS} && make install 
    [ $? -eq 0 ] && ${COLOR}"Nginx编译安装成功"${END} ||  { ${COLOR}"Nginx编译安装失败,退出!"${END};exit; }
    chown -R nginx.nginx /apps/nginx
    echo "PATH=${NGINX_INSTALL_DIR}/sbin:${PATH}" > /etc/profile.d/nginx.sh
    cat > /lib/systemd/system/nginx.service <<EOF
[Unit]
Description=nginx - high performance web server
Documentation=http://nginx.org/en/docs/
After=network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=${NGINX_INSTALL_DIR}/logs/nginx.pid
ExecStart=${NGINX_INSTALL_DIR}/sbin/nginx -c ${NGINX_INSTALL_DIR}/conf/nginx.conf
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s TERM \$MAINPID
LimitNOFILE=100000

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable --now nginx &> /dev/null 
    systemctl is-active nginx &> /dev/null ||  { ${COLOR}"Nginx 启动失败,退出!"${END} ; exit; }
    ${COLOR}"Nginx安装完成"${END}
}

main(){
    os
    check_file
    install_nginx
}

main
