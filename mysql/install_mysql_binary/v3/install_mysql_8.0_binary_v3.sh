#!/bin/bash
#
#**********************************************************************************
#Author:        Raymond
#QQ:            88563128
#MP:            Raymond运维
#Date:          2025-09-30
#FileName:      install_mysql_8.0_binary_v3.sh
#URL:           https://wx.zsxq.com/group/15555885545422
#Description:   The mysql binary script install supports 
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
DATA_DIR=/data/mysql

# mysql 8.0.42 glibc2.28包下载地址："https://cdn.mysql.com//Downloads/MySQL-8.0/mysql-8.0.42-linux-glibc2.28-x86_64.tar.xz"
# mysql 8.0.42 glibc2.17包下载地址："https://cdn.mysql.com//Downloads/MySQL-8.0/mysql-8.0.42-linux-glibc2.17-x86_64.tar.xz"

if [ ${MAIN_NAME} == "CentOS" -a ${MAIN_VERSION_ID} == 7 ];then
    GLIBC_VERSION=2.17
else
    GLIBC_VERSION=2.28
fi
MYSQL_URL=https://cdn.mysql.com//Downloads/MySQL-8.0/
MYSQL_FILE="mysql-8.0.42-linux-glibc${GLIBC_VERSION}-x86_64.tar.xz"

check_file(){
    if [ ${MAIN_NAME} == "Rocky" -o ${MAIN_NAME} == "AlmaLinux" -o ${MAIN_NAME} == "CentOS" -o ${MAIN_NAME} == "Anolis" -o ${MAIN_NAME} == "OpenCloudOS" -o ${MAIN_NAME} == "Kylin" ];then
        rpm -q wget &> /dev/null || { ${COLOR}"安装wget工具，请稍等......"${END};yum install -y wget &> /dev/null; }
    fi
    if [ ! -e ${MYSQL_FILE} ];then
        ${COLOR}"缺少${MYSQL_FILE}文件"${END}
        ${COLOR}'开始下载MySQL二进制安装包，请稍等......'${END}
        wget ${MYSQL_URL}${MYSQL_FILE} || { ${COLOR}"MySQL二进制安装包下载失败。"${END}; exit; }
    else
        ${COLOR}"${MYSQL_FILE}文件已准备好。"${END}
    fi
}

install_mysql(){
    [ -d /usr/local/mysql ] && { ${COLOR}"MySQL数据库已存在，安装失败！"${END};exit; }
    ${COLOR}"开始安装MySQL数据库，请稍等......"${END}
    if [ ${MAIN_NAME} == "openSUSE" ];then
        id mysql &> /dev/null || { groupadd -r mysql && useradd -s /sbin/nologin -r -g mysql mysql; ${COLOR}"成功创建mysql用户!"${END}; }
    else
        id mysql &> /dev/null || { useradd -s /sbin/nologin -r mysql ; ${COLOR}"成功创建mysql用户！"${END}; }
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
    tar xf ${MYSQL_FILE} -C /usr/local/
    MYSQL_DIR=`echo ${MYSQL_FILE}| sed -nr 's/^(.*[0-9]).*/\1/p'`
    ln -s /usr/local/${MYSQL_DIR} /usr/local/mysql
    chown -R mysql:mysql /usr/local/mysql/
    echo 'PATH=/usr/local/mysql/bin/:$PATH' > /etc/profile.d/mysql.sh
    . /etc/profile.d/mysql.sh
    cat > /etc/my.cnf <<-EOF
[mysqld]
datadir=${DATA_DIR}
socket=${DATA_DIR}/mysql.sock
log-error=${DATA_DIR}/mysql.log
pid-file=${DATA_DIR}/mysql.pid

[client]
socket=${DATA_DIR}/mysql.sock
EOF
    [ -d ${DATA_DIR} ] || mkdir -p ${DATA_DIR} &> /dev/null
    chown -R mysql:mysql ${DATA_DIR}
    if [ ${MAIN_NAME} == "Rocky" -o ${MAIN_NAME} == "AlmaLinux" -o ${MAIN_NAME} == "CentOS" -o ${MAIN_NAME} == "openEuler" -o ${MAIN_NAME} == "Anolis" -o ${MAIN_NAME} == "OpenCloudOS" ];then
        yum install -y libaio &> /dev/null
    fi
    if [ ${MAIN_NAME} == "Ubuntu" ];then
        if [ ${MAIN_VERSION_ID} == 24 ];then
            ln -s /usr/lib/x86_64-linux-gnu/libaio.so.1t64.0.2 /usr/lib/x86_64-linux-gnu/libaio.so.1
        fi
        if [ ${MAIN_VERSION_ID} == 18 ];then
            apt update &> /dev/null;apt install -y libaio1 &> /dev/null
        fi
    fi
    if [ ${MAIN_NAME} == "Debian" ];then
        if [ ${MAIN_VERSION_ID} == 11 -o ${MAIN_VERSION_ID} == 12 ];then
            apt update &> /dev/null;apt install -y libaio1 libnuma1 &> /dev/null
        fi
        if [ ${MAIN_VERSION_ID} == 13 ];then
            apt update &> /dev/null;apt install -y libaio1t64 libnuma1 &> /dev/null
            ln -s /usr/lib/x86_64-linux-gnu/libaio.so.1t64.0.2 /usr/lib/x86_64-linux-gnu/libaio.so.1
        fi
        if [ ${MAIN_VERSION_ID} == 12 -o ${MAIN_VERSION_ID} == 13 ];then
            apt update &> /dev/null;apt install -y libncurses6 &> /dev/null
        fi
    fi
    mysqld --initialize-insecure --user=mysql --datadir=${DATA_DIR}
    if [ ${MAIN_NAME} == "Rocky" ];then
        if [ ${MAIN_VERSION_ID} == 9 -o ${MAIN_VERSION_ID} == 10 ];then
            yum install -y chkconfig &> /dev/null
        fi
    fi
    if [ ${MAIN_NAME} == "AlmaLinux" ];then
        if [ ${MAIN_VERSION_ID} == 9 -o ${MAIN_VERSION_ID} == 10 ];then
            yum install -y chkconfig &> /dev/null
        fi
    fi
    if [ ${MAIN_NAME} == "CentOS" ];then
        if [ ${MAIN_VERSION_ID} == 9 -o ${MAIN_VERSION_ID} == 10 ];then
            yum install -y chkconfig &> /dev/null
        fi
    fi
    cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld
    if [ ${MAIN_NAME} == "openSUSE" ];then
       cat > /usr/lib/systemd/system/mysqld.service <<-EOF
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
        ln -s /sbin/chkconfig  /usr/lib/systemd/systemd-sysv-install
		chkconfig --add mysqld  &> /dev/null
        service mysqld start
    else
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
        systemctl daemon-reload && systemctl enable --now mysqld &> /dev/null
    fi
    [ $? -ne 0 ] && { ${COLOR}"数据库启动失败，退出！"${END};exit; }
    ${COLOR}"${PRETTY_NAME}操作系统，MySQL数据库安装完成！"${END}
}

main(){
    check_file
    install_mysql
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
