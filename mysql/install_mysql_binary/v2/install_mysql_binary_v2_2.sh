#!/bin/bash
#
#************************************************************************************************************
#Author:        Raymond
#QQ:            88563128
#Date:          2024-02-19
#FileName:      install_mysql_binary_v2_2.sh
#URL:           raymond.blog.csdn.net
#Description:   install_mysql_binary for CentOS 7 & CentOS Stream 8/9 & Ubuntu 18.04/20.04/22.04 & Rocky 8/9
#Copyright (C): 2024 All rights reserved
#************************************************************************************************************
SRC_DIR=/usr/local/src
COLOR="echo -e \\033[01;31m"
END='\033[0m'

# mysql 8.0.36 glibc2.28包下载地址："https://cdn.mysql.com//Downloads/MySQL-8.0/mysql-8.0.36-linux-glibc2.28-x86_64.tar.xz"
# mysql 8.0.36 glibc2.12包下载地址："https://cdn.mysql.com//Downloads/MySQL-8.0/mysql-8.0.36-linux-glibc2.12-x86_64.tar.xz"
# mysql 8.0.36 glibc2.17包下载地址："https://cdn.mysql.com//Downloads/MySQL-8.0/mysql-8.0.36-linux-glibc2.17-x86_64.tar.xz"
# mysql 5.7.44 glibc2.12包下载地址："https://cdn.mysql.com/archives/mysql-5.7/mysql-5.7.44-linux-glibc2.12-x86_64.tar.gz"

DATA_DIR=/data/mysql
MYSQL_URL=https://cdn.mysql.com//Downloads/MySQL-8.0/
MYSQL_FILE='mysql-8.0.36-linux-glibc2.28-x86_64.tar.xz'

os(){
    OS_ID=`sed -rn '/^NAME=/s@.*="([[:alpha:]]+).*"$@\1@p' /etc/os-release`
    OS_RELEASE_VERSION=`sed -rn '/^VERSION_ID=/s@.*="?([0-9]+)\.?.*"?@\1@p' /etc/os-release`
}

check_file(){
    cd  ${SRC_DIR}
    if [ ${OS_ID} == "CentOS" -o ${OS_ID} == "Rocky" ] &> /dev/null;then
        rpm -q wget &> /dev/null || { ${COLOR}"安装wget工具，请稍等..."${END};yum -y install wget &> /dev/null; }
    fi
    if [ ! -e ${MYSQL_FILE} ];then
        ${COLOR}"缺少${MYSQL_FILE}文件"${END}
        ${COLOR}'开始下载MySQL二进制安装包'${END}
        wget ${MYSQL_URL}${MYSQL_FILE} || { ${COLOR}"MySQL二进制安装包下载失败"${END}; exit; }
    else
        ${COLOR}"${MYSQL_FILE}文件已准备好"${END}
    fi
}

install_mysql(){
    [ -d /usr/local/mysql ] && { ${COLOR}"MySQL数据库已存在，安装失败"${END};exit; }
    ${COLOR}"开始安装MySQL数据库..."${END}
    ${COLOR}'开始安装MySQL依赖包'${END}
    if [ ${OS_ID} == "Rocky" -a ${OS_RELEASE_VERSION} == 9 ];then
        MIRROR=mirrors.sjtug.sjtu.edu.cn
        if [ `grep -R "\[devel\]" /etc/yum.repos.d/*.repo` ];then
            dnf config-manager --set-enabled devel
        else
            cat > /etc/yum.repos.d/devel.repo <<-EOF
[devel]
name=devel
baseurl=https://${MIRROR}/rocky/\$releasever/devel/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-\$releasever
EOF
        fi
    fi
    if [ ${OS_ID} == "CentOS" -a ${OS_RELEASE_VERSION} == 9 ];then
        yum -y install epel-release  &> /dev/null
        MIRROR=mirrors.aliyun.com
        sed -i.bak -e 's|^metalink=|#metalink=|g' -e 's|^#baseurl=https://download.example/pub/epel|baseurl=https://'${MIRROR}'/epel|g' /etc/yum.repos.d/epel*.repo
        dnf config-manager --set-disabled epel-cisco-openh264
        dnf makecache  &> /dev/null
    fi
    if [ ${OS_RELEASE_VERSION} == 8 -o ${OS_RELEASE_VERSION} == 9 ];then
        yum -y install libaio perl-Data-Dumper ncurses-compat-libs &> /dev/null
    elif [[ ${OS_RELEASE_VERSION} == 7 ]];then
        yum -y install libaio perl-Data-Dumper &> /dev/null
    else
        apt update &> /dev/null;apt -y install numactl libaio-dev libtinfo5 &> /dev/null
    fi
    id mysql &> /dev/null || { useradd -s /sbin/nologin -r  mysql ; ${COLOR}"创建mysql用户"${END}; }
    tar xf ${MYSQL_FILE} -C /usr/local/
    MYSQL_DIR=`echo ${MYSQL_FILE}| sed -nr 's/^(.*[0-9]).*/\1/p'`
    ln -s  /usr/local/${MYSQL_DIR} /usr/local/mysql

    chown -R mysql.mysql /usr/local/mysql/
    echo 'PATH=/usr/local/mysql/bin/:$PATH' > /etc/profile.d/mysql.sh
    . /etc/profile.d/mysql.sh
    cat > /etc/my.cnf <<-EOF
[mysqld]
server-id=1
log-bin
datadir=${DATA_DIR}
socket=${DATA_DIR}/mysql.sock
log-error=${DATA_DIR}/mysql.log
pid-file=${DATA_DIR}/mysql.pid

[client]
socket=${DATA_DIR}/mysql.sock
EOF
    [ -d ${DATA_DIR} ] || mkdir -p ${DATA_DIR} &> /dev/null
    chown -R  mysql.mysql ${DATA_DIR}
    mysqld --initialize-insecure --user=mysql --datadir=${DATA_DIR}
    if [ ${OS_ID} == "CentOS" -o ${OS_ID} == "Rocky" ] &> /dev/null;then
        rpm -q chkconfig &> /dev/null || { ${COLOR}"安装chkconfig包，请稍等..."${END};yum -y install chkconfig &> /dev/null; }
    fi
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
    ${COLOR}"MySQL数据库安装完成"${END}
}

main(){
    os
    check_file
    install_mysql
}

main
