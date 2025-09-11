#!/bin/bash
#
#************************************************************************************************************
#Author:        Raymond
#QQ:            88563128
#Date:          2024-02-25
#FileName:      install_mysql_source.sh
#URL:           raymond.blog.csdn.net
#Description:   install_mysql_source for CentOS 7 & CentOS Stream 8/9 & Ubuntu 18.04/20.04/22.04 & Rocky 8/9
#Copyright (C): 2024 All rights reserved
#************************************************************************************************************
SRC_DIR=/usr/local/src
INSTALL_DIR=/apps/mysql
DATA_DIR=/data/mysql
COLOR="echo -e \\033[01;31m"
END='\033[0m'

MYSQL_URL='https://cdn.mysql.com//Downloads/MySQL-8.0/'
MYSQL_FILE='mysql-boost-8.0.36.tar.gz'

#cmake下载地址：”https://github.com/Kitware/CMake/releases/download/v3.29.0-rc1/cmake-3.29.0-rc1.tar.gz“，请提前下载。
CMAKE_FILE=cmake-3.29.0-rc1.tar.gz

CPUS=`lscpu |awk '/^CPU\(s\)/{print $2}'`
MYSQL_ROOT_PASSWORD=123456

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
        ${COLOR}'开始下载MySQL源码包'${END}
        wget ${MYSQL_URL}${MYSQL_FILE} || { ${COLOR}"MySQL源码包下载失败"${END}; exit; }
    else
        ${COLOR}"${MYSQL_FILE}相关文件已准备好"${END}
    fi
    if [ ${OS_ID} == "CentOS" -a ${OS_RELEASE_VERSION} == 7 ];then
        if [ ! -e ${CMAKE_FILE} ];then
            ${COLOR}"缺少${CMAKE_FILE}文件,请把文件放到${SRC_DIR}目录下"${END}
        else
            ${COLOR}"${CMAKE_FILE}相关文件已准备好"${END}
        fi
    fi
}

install_mysql(){
    [ -d ${INSTALL_DIR} ] && { ${COLOR}"MySQL数据库已存在，安装失败"${END};exit; }
    ${COLOR}"开始安装MySQL数据库..."${END}
    ${COLOR}'开始安装MySQL依赖包'${END}
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
        MIRROR=mirrors.aliyun.com
        if [ `grep -R "\[crb\]" /etc/yum.repos.d/*.repo` ];then
            dnf config-manager --set-enabled crb
        else
            cat > /etc/yum.repos.d/crb.repo <<-EOF
[crb]
name=crb
baseurl=https://${MIRROR}/centos-stream/\$releasever-stream/CRB/\$basearch/os
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        fi
    fi
    if [ ${OS_ID} == "CentOS" -o ${OS_ID} == "Rocky" ] &> /dev/null;then
        if [ ${OS_RELEASE_VERSION} == 7 ];then
            yum -y install gcc gcc-c++ ncurses ncurses-devel libaio-devel openssl openssl-devel &> /dev/null
            yum -y install centos-release-scl &> /dev/null
            yum -y install devtoolset-11-gcc devtoolset-11-gcc-c++ devtoolset-11-binutils &> /dev/null
		else
            yum -y install gcc gcc-c++ cmake ncurses ncurses-devel bison openssl-devel rpcgen gcc-toolset-12-gcc gcc-toolset-12-gcc-c++ gcc-toolset-12-binutils gcc-toolset-12-annobin-annocheck gcc-toolset-12-annobin-plugin-gcc libtirpc-devel &> /dev/null
        fi
	else
        apt -y install build-essential cmake bison libncurses5-dev libssl-dev pkg-config
    fi
    id mysql &> /dev/null || { useradd -r -s /sbin/nologin -d ${DATA_DIR} mysql ; ${COLOR}"创建mysql用户"${END}; }
    [ -d ${DATA_DIR} ] || mkdir -p ${DATA_DIR}
    chown -R mysql.mysql ${DATA_DIR}

    if [ ${OS_ID} == "CentOS" -a ${OS_RELEASE_VERSION} == 7 ];then
        tar xf ${CMAKE_FILE}
        CMAKE_DIR=`echo ${CMAKE_FILE}| sed -nr 's/^(.*[0-9]).*/\1/p'`
        cd ${CMAKE_DIR}
        ./configure
        make -j ${CPUS} && make install
        ln -s /usr/local/bin/cmake /usr/bin/
    fi

    cd  ${SRC_DIR}
    tar xf ${MYSQL_FILE}
    MYSQL_DIR=`echo ${MYSQL_FILE}| sed -nr 's/^(.*[0-9]).*/\1/p' | cut -d"-" -f 1,3`
    cd ${MYSQL_DIR}

    cmake \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
    -DMYSQL_UNIX_ADDR=${DATA_DIR}/mysql.sock \
    -DSYSCONFDIR=/etc \
    -DSYSTEMD_PID_DIR=${INSTALL_DIR} \
    -DDEFAULT_CHARSET=utf8  \
    -DDEFAULT_COLLATION=utf8_general_ci \
    -DWITH_INNOBASE_STORAGE_ENGINE=1 \
    -DWITH_ARCHIVE_STORAGE_ENGINE=1 \
    -DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
    -DWITH_PERFSCHEMA_STORAGE_ENGINE=1 \
    -DMYSQL_DATADIR=${DATA_DIR}\
    -DWITH_BOOST=/usr/local/src/${MYSQL_DIR}/boost/boost_1_77_0/ \
    -DFORCE_INSOURCE_BUILD=1 \
    -DWITH_SYSTEMD=1
    make -j ${CPUS} && make install
    [ $? -eq 0 ] && ${COLOR}"MariaDB编译安装成功"${END} ||  { ${COLOR}"MariaDB编译安装失败,退出!"${END};exit; }

	echo 'PATH='${INSTALL_DIR}'/bin:$PATH' > /etc/profile.d/mysql.sh
    .  /etc/profile.d/mysql.sh
	chown -R mysql.mysql ${INSTALL_DIR}

    mysqld --initialize-insecure --user=mysql --basedir=${INSTALL_DIR} --datadir=${DATA_DIR}

    cat > /etc/my.cnf <<EOF
[mysqld]
user=mysql
basedir=${INSTALL_DIR}
datadir=${DATA_DIR}
port=3306
socket=${DATA_DIR}l/mysql.sock 
pid-file=${DATA_DIR}/mysql.pid 

[mysqld_safe]
log-error=${DATA_DIR}/mysql.log 

[client]
port=3306
socket=${DATA_DIR}/mysql.sock
EOF
    if [ ${OS_ID} == "CentOS" -o ${OS_ID} == "Rocky" ] &> /dev/null;then
        cp ${INSTALL_DIR}/usr/lib/systemd/system/mysqld.service /lib/systemd/system/
    else
        cat > /lib/systemd/system//mysqld.service  <<EOF
# Copyright (c) 2015, 2023, Oracle and/or its affiliates.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License, version 2.0,
# as published by the Free Software Foundation.
#
# This program is also distributed with certain software (including
# but not limited to OpenSSL) that is licensed under separate terms,
# as designated in a particular file or component or in included license
# documentation.  The authors of MySQL hereby grant you an additional
# permission to link the program and your derivative works with the
# separately licensed software that they have included with MySQL.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License, version 2.0, for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA
#
# systemd service file for MySQL forking server
#

[Unit]
Description=MySQL Server
Documentation=man:mysqld(8)
Documentation=http://dev.mysql.com/doc/refman/en/using-systemd.html
After=network-online.target
Wants=network-online.target
After=syslog.target

[Install]
WantedBy=multi-user.target

[Service]
User=mysql
Group=mysql

Type=notify

# Disable service start and stop timeout logic of systemd for mysqld service.
TimeoutSec=0

# Execute pre and post scripts as root
# hence, + prefix is used

# Needed to create system tables
ExecStartPre=+${INSTALL_DIR}/bin/mysqld_pre_systemd

# Start main service
ExecStart=${INSTALL_DIR}/bin/mysqld $MYSQLD_OPTS

# Use this to switch malloc implementation
EnvironmentFile=-/etc/sysconfig/mysql

# Sets open_files_limit
LimitNOFILE = 10000

Restart=on-failure

RestartPreventExitStatus=1

# Set enviroment variable MYSQLD_PARENT_PID. This is required for restart.
Environment=MYSQLD_PARENT_PID=1

PrivateTmp=false
EOF
    fi
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
