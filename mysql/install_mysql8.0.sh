#!/bin/bash
#
#*************************************************************************************************
#Author:        Raymond
#QQ:            88563128
#Date:          2022-09-05
#FileName:      install_mysql8.0.sh
#URL:           raymond.blog.csdn.net
#Description:   install_mysql8.0 centos 7/8/stream 8 & ubuntu 18.04/20.04 & Rocky 8
#Copyright (C): 2022 All rights reserved
#*************************************************************************************************
SRC_DIR=/usr/local/src
COLOR="echo -e \\033[01;31m"
END='\033[0m'
MYSQL_URL=https://mirrors.cloud.tencent.com/mysql/downloads/MySQL-
MYSQL_VERSION='8.0/'
MYSQL_FILE='mysql-8.0.28-linux-glibc2.12-x86_64.tar.xz'
MYSQL_ROOT_PASSWORD=123456

os(){
    OS_ID=`sed -rn '/^NAME=/s@.*="([[:alpha:]]+).*"$@\1@p' /etc/os-release`
    OS_RELEASE_VERSION=`sed -rn '/^VERSION_ID=/s@.*="?([0-9]+)\.?.*"?@\1@p' /etc/os-release`
}

check_file(){
    cd  ${SRC_DIR}
    if [ ${OS_ID} == "CentOS" -o ${OS_ID} == "Rocky" ] &> /dev/null;then
        rpm -q wget &> /dev/null || yum -y install wget &> /dev/null
    fi
    if [ ! -e ${MYSQL_FILE} ];then
        ${COLOR}"缺少${MYSQL_FILE}文件"${END}
        ${COLOR}'开始下载MYSQL二进制安装包'${END}
        wget ${MYSQL_URL}${MYSQL_VERSION}${MYSQL_FILE} || { ${COLOR}"MYSQL二进制安装包下载失败"${END}; exit; }
    else
        ${COLOR}"${MYSQL_FILE}文件已准备好"${END}
    fi
}

install_mysql(){
    [ -d /usr/local/mysql ] && { ${COLOR}"MySQL数据库已存在，安装失败"${END};exit; }
    ${COLOR}"开始安装MySQL数据库..."${END}
    ${COLOR}'开始安装MYSQL依赖包'${END}
    if [[ ${OS_RELEASE_VERSION} == 8 ]] &> /dev/null;then
        yum -y install libaio perl-Data-Dumper ncurses-compat-libs &> /dev/null
    elif [[ ${OS_RELEASE_VERSION} == 7 ]] &> /dev/null;then
        yum -y install libaio perl-Data-Dumper &> /dev/null
    else
        apt update &> /dev/null;apt -y install numactl libaio-dev libtinfo5 &> /dev/null
    fi
    cd  ${SRC_DIR}
    tar xf ${MYSQL_FILE} -C /usr/local/
    MYSQL_DIR=`echo ${MYSQL_FILE}| sed -nr 's/^(.*[0-9]).*/\1/p'`
    ln -s  /usr/local/${MYSQL_DIR} /usr/local/mysql
    id mysql &> /dev/null || { useradd -s /sbin/nologin -r  mysql ; ${COLOR}"创建mysql用户"${END}; }
    chown -R  mysql.mysql /usr/local/mysql/
    echo 'PATH=/usr/local/mysql/bin/:$PATH' > /etc/profile.d/mysql.sh
    .  /etc/profile.d/mysql.sh
    cat > /etc/my.cnf <<-EOF
[mysqld]
server-id=1
log-bin
datadir=/data/mysql
socket=/data/mysql/mysql.sock
log-error=/data/mysql/mysql.log
pid-file=/data/mysql/mysql.pid
[client]
socket=/data/mysql/mysql.sock
EOF
    [ -d /data/mysql ] || mkdir -p /data/mysql &> /dev/null
    chown -R  mysql.mysql /data/mysql
    mysqld --initialize --user=mysql --datadir=/data/mysql 
    cp /usr/local/mysql/support-files/mysql.server  /etc/init.d/mysqld
    if [ ${OS_ID} == "CentOS" -o ${OS_ID} == "Rocky" ] &> /dev/null;then
        chkconfig --add mysqld
    else
        update-rc.d -f mysqld defaults
    fi
    cat > /lib/systemd/system/mysqld.service <<-EOF
[Unit]
Description=mysql database server
After=network.target

[Service]
Type=notify
PrivateNetwork=false
Type=forking
Restart=no
TimeoutSec=5min
IgnoreSIGPIPE=no
KillMode=process
GuessMainPID=no
RemainAfterExit=yes
SuccessExitStatus=5 6
ExecStart=/etc/init.d/mysqld start
ExecStop=/etc/init.d//mysqld stop
ExecReload=/etc/init.d/mysqld reload

[Install]
WantedBy=multi-user.target
Alias=mysqld.service
EOF
    systemctl daemon-reload
    systemctl enable --now mysqld &> /dev/null
    [ $? -ne 0 ] && { ${COLOR}"数据库启动失败，退出!"${END};exit; }
    MYSQL_OLDPASSWORD=`awk '/A temporary password/{print $NF}' /data/mysql/mysql.log`
    mysqladmin  -uroot -p${MYSQL_OLDPASSWORD} password ${MYSQL_ROOT_PASSWORD} &>/dev/null
    ${COLOR}"MySQL数据库安装完成"${END}
}

main(){
    os
    check_file
    install_mysql
}

main
