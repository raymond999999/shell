#!/bin/bash
#
#**********************************************************************************
#Author:        Raymond
#QQ:            88563128
#MP:            Raymond运维
#Date:          2025-09-30
#FileName:      install_mariadb_binary_v2.sh
#URL:           https://wx.zsxq.com/group/15555885545422
#Description:   The mariadb binary script install supports 
#               “Rocky Linux 8, 9 and 10, AlmaLinux 8, 9 and 10, CentOS 7, 
#               CentOS Stream 8, 9 and 10, openEuler 22.03 and 24.03 LTS, 
#               AnolisOS 8 and 23, OpenCloudOS 8 and 9, Kylin Server v10 and v11, 
#               UOS Server v20, Ubuntu Server 18.04, 20.04, 22.04 and 24.04 LTS,  
#               Debian 11 , 12 and 13, openSUSE Leap 15“ operating systems.
#Copyright (C): 2025 All rights reserved
#**********************************************************************************
COLOR="echo -e \\033[01;31m"
END='\033[0m'

os(){
    . /etc/os-release
    MAIN_NAME=`sed -rn '/^NAME=/s@.*="([[:alpha:]]+).*"$@\1@p' /etc/os-release`
    if [ ${MAIN_NAME} == "Kylin" ];then
        MAIN_VERSION_ID=`sed -rn '/^VERSION_ID=/s@.*="([[:alpha:]]+)(.*)"$@\2@p' /etc/os-release`
    else
        MAIN_VERSION_ID=`sed -rn '/^VERSION_ID=/s@.*="?([0-9]+)\.?.*"?@\1@p' /etc/os-release`
    fi
}

os
DATA_DIR=/data/mariadb

# mariadb 11.8.3包下载地址："https://mirrors.tuna.tsinghua.edu.cn/mariadb///mariadb-11.8.3/bintar-linux-systemd-x86_64/mariadb-11.8.3-linux-systemd-x86_64.tar.gz"
# mariadb 11.4.8包下载地址："https://mirrors.tuna.tsinghua.edu.cn/mariadb///mariadb-11.4.8/bintar-linux-systemd-x86_64/mariadb-11.4.8-linux-systemd-x86_64.tar.gz"

if [ ${MAIN_NAME} == "CentOS" -a ${MAIN_VERSION_ID} == 7 ];then
    MARIADB_VERSION=11.4.8 
else
    MARIADB_VERSION=11.8.3 
fi
MARIADB_URL="https://mirrors.tuna.tsinghua.edu.cn/mariadb///mariadb-${MARIADB_VERSION}/bintar-linux-systemd-x86_64/"
MARIADB_FILE="mariadb-${MARIADB_VERSION}-linux-systemd-x86_64.tar.gz"

check_file(){
    if [ ${MAIN_NAME} == "Rocky" -o ${MAIN_NAME} == "AlmaLinux" -o ${MAIN_NAME} == "CentOS" -o ${MAIN_NAME} == "Anolis" -o ${MAIN_NAME} == "OpenCloudOS" -o ${MAIN_NAME} == "Kylin" ];then
        rpm -q wget &> /dev/null || { ${COLOR}"安装wget工具，请稍等......"${END};yum install -y wget &> /dev/null; }
    fi
    if [ ! -e ${MARIADB_FILE} ];then
        ${COLOR}"缺少${MARIADB_FILE}文件。"${END}
        ${COLOR}'开始下载MariaDB二进制安装包，请稍等......'${END}
        wget ${MARIADB_URL}${MARIADB_FILE} || { ${COLOR}"MariaDB二进制安装包下载失败。"${END}; exit; }
    else
        ${COLOR}"${MARIADB_FILE}文件已准备好。"${END}
    fi
}

install_mariadb(){
    [ -d /usr/local/mysql ] && { ${COLOR}"MariaDB数据库已存在，安装失败!"${END};exit; }
    ${COLOR}"开始安装MariaDB数据库，请稍等......"${END}
    if [ ${MAIN_NAME} == "openSUSE" ];then
        id mysql &> /dev/null || { groupadd -r mysql && useradd -s /sbin/nologin -d ${DATA_DIR} -r -g mysql mysql; ${COLOR}"成功创建mysql用户!"${END}; }
    else
        id mysql &> /dev/null || { useradd -r -s /sbin/nologin -d ${DATA_DIR} mysql ; ${COLOR}"成功创建mysql用户！"${END}; }
    fi
    if [ ${MAIN_NAME} == "openEuler" ];then
        if [ ${MAIN_VERSION_ID} == 22 -o ${MAIN_VERSION_ID} == 24 ];then
            yum install -y tar &> /dev/null
        fi
    fi
    if [ ${MAIN_NAME} == "Anolis" ];then
        if [ ${MAIN_VERSION_ID} == 23 ];then
            yum install -y tar &> /dev/null
        fi
    fi
    if [ ${MAIN_NAME} == "OpenCloudOS" ];then
        if [ ${MAIN_VERSION_ID} == 9 ];then
            yum install -y tar &> /dev/null
        fi
    fi
    tar xf ${MARIADB_FILE} -C /usr/local/
    MARIADB_DIR=`echo ${MARIADB_FILE}| sed -nr 's/^(.*[0-9]).*/\1/p'`
    ln -s  /usr/local/${MARIADB_DIR} /usr/local/mysql
    chown -R mysql:mysql /usr/local/mysql/
    echo 'PATH=/usr/local/mysql/bin/:$PATH' > /etc/profile.d/mariadb.sh
    . /etc/profile.d/mariadb.sh
    cat > /etc/my.cnf <<-EOF
[mariadb]
datadir=${DATA_DIR}
socket=${DATA_DIR}/mariadb.sock
log-error=${DATA_DIR}/mariadb.log
pid-file=${DATA_DIR}/mariadb.pid

[client]
socket=${DATA_DIR}/mariadb.sock
EOF
    [ -d ${DATA_DIR} ] || mkdir -p ${DATA_DIR} &> /dev/null
    chown -R mysql:mysql ${DATA_DIR}
    if [ ${MAIN_NAME} == "Rocky" ];then
        if [ ${MAIN_VERSION_ID} == 10 ];then
            yum install -y libxcrypt-compat &> /dev/null
        fi
    fi
    if [ ${MAIN_NAME} == "AlmaLinux" ];then
        if [ ${MAIN_VERSION_ID} == 10 ];then
            yum install -y libxcrypt-compat &> /dev/null
        fi
    fi
    if [ ${MAIN_NAME} == "CentOS" ];then
        if [ ${MAIN_VERSION_ID} == 10 ];then
            yum install -y libxcrypt-compat &> /dev/null
        fi
    fi
    cd /usr/local/mysql
    ./scripts/mysql_install_db --datadir=${DATA_DIR} --user=mysql
    if [ ${MAIN_NAME} == "Ubuntu" -o ${MAIN_NAME} == "Debian" ];then
        cp /usr/local/mysql/support-files/systemd/mariadb.service /lib/systemd/system/
    else
        cp /usr/local/mysql/support-files/systemd/mariadb.service /usr/lib/systemd/system/
    fi 
    systemctl daemon-reload && systemctl enable --now mariadb &> /dev/null
    [ $? -ne 0 ] && { ${COLOR}"数据库启动失败，退出！"${END};exit; }
}

mariadb_secure(){
    ln -s ${DATA_DIR}/mariadb.sock /tmp/mysql.sock
    /usr/local/mysql/bin/mariadb-secure-installation <<EOF

y
n
y
y
y
y
EOF
    ${COLOR}"${PRETTY_NAME}操作系统，MariaDB数据库安装完成！"${END}
}

main(){
    check_file
    install_mariadb
    mariadb_secure
}

if [ ${MAIN_NAME} == "Rocky" ];then
    if [ ${MAIN_VERSION_ID} == 8 -o ${MAIN_VERSION_ID} == 9 -o ${MAIN_VERSION_ID} == 10 ];then
        main
    fi
elif [ ${MAIN_NAME} == "AlmaLinux" ];then
    if [ ${MAIN_VERSION_ID} == 8 -o ${MAIN_VERSION_ID} == 9 -o ${MAIN_VERSION_ID} == 10 ];then
        main
    fi
elif [ ${MAIN_NAME} == "CentOS" ];then
    if [ ${MAIN_VERSION_ID} == 7 -o ${MAIN_VERSION_ID} == 8 -o ${MAIN_VERSION_ID} == 9 -o ${MAIN_VERSION_ID} == 10 ];then
        main
    fi
elif [ ${MAIN_NAME} == "openEuler" ];then
    if [ ${MAIN_VERSION_ID} == 22 -o ${MAIN_VERSION_ID} == 24 ];then
        main
    fi
elif [ ${MAIN_NAME} == "Anolis" ];then
    if [ ${MAIN_VERSION_ID} == 8 -o ${MAIN_VERSION_ID} == 23 ];then
        main
    fi
elif [ ${MAIN_NAME} == 'OpenCloudOS' ];then
    if [ ${MAIN_VERSION_ID} == 8 -o ${MAIN_VERSION_ID} == 9 ];then
        main
    fi
elif [ ${MAIN_NAME} == "Kylin" ];then
    if [ ${MAIN_VERSION_ID} == 10 -o ${MAIN_VERSION_ID} == 11 ];then
        main
    fi
elif [ ${MAIN_NAME} == "UOS" ];then
    if [ ${MAIN_VERSION_ID} == 20 ];then
        main
    fi
elif [ ${MAIN_NAME} == "openSUSE" ];then
    if [ ${MAIN_VERSION_ID} == 15 ];then
        main
    fi
elif [ ${MAIN_NAME} == "Ubuntu" ];then
    if [ ${MAIN_VERSION_ID} == 18 -o ${MAIN_VERSION_ID} == 20 -o ${MAIN_VERSION_ID} == 22 -o ${MAIN_VERSION_ID} == 24 ];then
        main
    fi
elif [ ${MAIN_NAME} == 'Debian' ];then
    if [ ${MAIN_VERSION_ID} == 11 -o ${MAIN_VERSION_ID} == 12 -o ${MAIN_VERSION_ID} == 13 ];then
        main
    fi
else
    ${COLOR}"此脚本不支持${PRETTY_NAME}操作系统！"${END}
fi
