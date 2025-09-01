#!/bin/bash
#
#*************************************************************************************************
#Author:        Raymond
#QQ:            88563128
#Date:          2022-09-05
#FileName:      install_mysql5.6.sh
#URL:           raymond.blog.csdn.net
#Description:   install_mysql5.6 for centos 7/8/stream 8 & ubuntu 18.04/20.04 & Rocky 8
#Copyright (C): 2022 All rights reserved
#*************************************************************************************************
SRC_DIR=/usr/local/src
COLOR="echo -e \\033[01;31m"
END='\033[0m'

MYSQL_URL=https://mirrors.cloud.tencent.com/mysql/downloads/MySQL-
MYSQL_VERSION='5.6/'
MYSQL_FILE='mysql-5.6.51-linux-glibc2.12-x86_64.tar.gz'
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
    if [ !  -e ${MYSQL_FILE} ];then
        ${COLOR}"缺少${MYSQL_FILE}文件"${END}
        ${COLOR}'开始下载MYSQL二进制安装包'${END}
        wget ${MYSQL_URL}${MYSQL_VERSION}${MYSQL_FILE} || { ${COLOR}"MYSQL二进制安装包下载失败"${END}; exit; } 
    else
        ${COLOR}"${MYSQL_FILE}文件已准备好"${END}
    fi
}

install_mysql(){
    [ -d /usr/local/mysql ] && { ${COLOR}"数据库已存在，安装失败"${END};exit; }
    ${COLOR}"开始安装MySQL数据库..."${END}
    cd  ${SRC_DIR}
    ${COLOR}'开始安装MYSQL依赖包'${END}
    if [[ ${OS_RELEASE_VERSION} == 8 ]] &> /dev/null;then
        yum install -y libaio perl-Data-Dumper autoconf ncurses-compat-libs &> /dev/null
    elif [[ ${OS_RELEASE_VERSION} == 7 ]] &> /dev/null;then
        yum install -y libaio perl-Data-Dumper &> /dev/null
    else
        apt update &> /dev/null;apt -y install numactl libaio-dev libtinfo5 &> /dev/null
    fi
    tar xf ${MYSQL_FILE} -C /usr/local/
    MYSQL_DIR=`echo ${MYSQL_FILE}| sed -nr 's/^(.*[0-9]).*/\1/p'`
    ln -s  /usr/local/${MYSQL_DIR} /usr/local/mysql
    id mysql &> /dev/null || { useradd -s /sbin/nologin -r  mysql ; ${COLOR}"创建mysql用户"${END}; }
    chown -R  mysql.mysql /usr/local/mysql/
    [  -d /data/mysql ] || mkdir -p /data/mysql &> /dev/null
    chown -R mysql.mysql /data/mysql
    /usr/local/mysql/scripts/mysql_install_db --user=mysql --datadir=/data/mysql --basedir=/usr/local/mysql/ &> /dev/null
    cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld
    chmod a+x /etc/init.d/mysqld
    echo 'PATH=/usr/local/mysql/bin/:$PATH' > /etc/profile.d/mysql.sh
    .  /etc/profile.d/mysql.sh
    cat > /etc/my.cnf <<-EOF
[mysqld]
socket=/tmp/mysql.sock
user=mysql
symbolic-links=0
datadir=/data/mysql
innodb_file_per_table=1
log-bin
pid-file=/data/mysql/mysqld.pid

[client]
port=3306
socket=/tmp/mysql.sock

[mysqld_safe]
log-error=/var/log/mysqld.log
EOF
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
ExecStop=/etc/init.d/mysqld stop
ExecReload=/etc/init.d/mysqld reload

[Install]
WantedBy=multi-user.target
Alias=mysqld.service
EOF
    systemctl daemon-reload
    systemctl enable --now mysqld &> /dev/null
    [ $? -ne 0 ] && { ${COLOR}"数据库启动失败，退出!"${END};exit; }	
    ${COLOR}"数据库安装完成"${END}
}

mysql_secure(){
    /usr/local/mysql/bin/mysql_secure_installation <<EOF

y
${MYSQL_ROOT_PASSWORD}
${MYSQL_ROOT_PASSWORD}
y
y
y
y
EOF
}

main(){
    os
    check_file
    install_mysql
    mysql_secure
}

main
