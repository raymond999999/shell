#!/bin/bash
#
#************************************************************************************************************
#Author:        Raymond
#QQ:            88563128
#Date:          2024-02-26
#FileName:      install_mariadb_binary.sh
#URL:           raymond.blog.csdn.net
#Description:   install_mysql_binary for CentOS 7 & CentOS Stream 8/9 & Ubuntu 18.04/20.04/22.04 & Rocky 8/9
#Copyright (C): 2024 All rights reserved
#************************************************************************************************************
SRC_DIR=/usr/local/src
COLOR="echo -e \\033[01;31m"
END='\033[0m'
DATA_DIR=/data/mysql
MARIADB_URL=https://mirrors.xtom.com.hk/mariadb//mariadb-11.3.2/bintar-linux-systemd-x86_64/
MARIADB_FILE='mariadb-11.3.2-linux-systemd-x86_64.tar.gz'

os(){
    OS_ID=`sed -rn '/^NAME=/s@.*="([[:alpha:]]+).*"$@\1@p' /etc/os-release`
    OS_RELEASE_VERSION=`sed -rn '/^VERSION_ID=/s@.*="?([0-9]+)\.?.*"?@\1@p' /etc/os-release`
}

check_file(){
    cd  ${SRC_DIR}
    if [ ${OS_ID} == "CentOS" -o ${OS_ID} == "Rocky" ] &> /dev/null;then
        rpm -q wget &> /dev/null || { ${COLOR}"安装wget工具，请稍等..."${END};yum -y install wget &> /dev/null; }
    fi
    if [ ! -e ${MARIADB_FILE} ];then
        ${COLOR}"缺少${MARIADB_FILE}文件"${END}
        ${COLOR}'开始下载MariaDB二进制安装包'${END}
        wget ${MARIADB_URL}${MARIADB_FILE} || { ${COLOR}"MariaDB二进制安装包下载失败"${END}; exit; }
    else
        ${COLOR}"${MARIADB_FILE}文件已准备好"${END}
    fi
}

install_mysql(){
    [ -d /usr/local/mysql ] && { ${COLOR}"MariaDB数据库已存在，安装失败"${END};exit; }
    ${COLOR}"开始安装MariaDB数据库..."${END}
    id mysql &> /dev/null || { useradd -r -s /sbin/nologin -d ${DATA_DIR} mysql ; ${COLOR}"创建mysql用户"${END}; }
    tar xf ${MARIADB_FILE} -C /usr/local/
    MARIADB_DIR=`echo ${MARIADB_FILE}| sed -nr 's/^(.*[0-9]).*/\1/p'`
    ln -s  /usr/local/${MARIADB_DIR} /usr/local/mysql
    chown -R mysql.mysql /usr/local/mysql/
    echo 'PATH=/usr/local/mysql/bin/:$PATH' > /etc/profile.d/mysql.sh
    . /etc/profile.d/mysql.sh
    cat > /etc/my.cnf <<-EOF
[mysqld]
datadir=${DATA_DIR}
socket=${DATA_DIR}/mysql.sock

[mysqld_safe]
log-error=${DATA_DIR}/mysql.log
pid-file=${DATA_DIR}/mysql.pid

[client]
socket=${DATA_DIR}/mysql.sock
EOF
    [ -d ${DATA_DIR} ] || mkdir -p ${DATA_DIR} &> /dev/null
    chown -R  mysql.mysql ${DATA_DIR}
    cd /usr/local/mysql
    ./scripts/mysql_install_db --datadir=${DATA_DIR} --user=mysql
    cp /usr/local/mysql/support-files/systemd/mysqld.service /lib/systemd/system/
    systemctl daemon-reload
    systemctl enable --now mysqld &> /dev/null
    [ $? -ne 0 ] && { ${COLOR}"数据库启动失败，退出!"${END};exit; }
    if [ ${OS_RELEASE_VERSION} == 8 -o ${OS_RELEASE_VERSION} == 9 ] &> /dev/null;then
        ln -s /usr/lib64/libncurses.so.6 /usr/lib64/libncurses.so.5
        ln -s /usr/lib64/libtinfo.so.6 /usr/lib64/libtinfo.so.5
    fi
    if [ ${OS_RELEASE_VERSION} == 20 -o ${OS_RELEASE_VERSION} == 22 ] &> /dev/null;then
        ln -s /usr/lib/x86_64-linux-gnu/libncurses.so.6 /usr/lib/x86_64-linux-gnu/libncurses.so.5
        ln -s /usr/lib/x86_64-linux-gnu/libtinfo.so.6 /usr/lib/x86_64-linux-gnu/libtinfo.so.5
    fi
    ln -s /data/mysql/mysql.sock /tmp/mysql.sock
    ${COLOR}"MariaDB数据库安装完成"${END}

}

mysql_secure(){
    /usr/local/mysql/bin/mysql_secure_installation <<EOF

y
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
