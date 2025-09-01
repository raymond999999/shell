#!/bin/bash
#
#**********************************************************************************
#Author:        Raymond
#QQ:            88563128
#MP:            Raymond运维
#Date:          2025-09-01
#FileName:      install_mysql_8.4_source_v2.sh
#URL:           https://wx.zsxq.com/group/15555885545422
#Description:   The mysql source script install supports 
#               “Rocky Linux 8, 9 and 10, Almalinux 8, 9 and 10, CentOS 7, 
#               CentOS Stream 8, 9 and 10, openEuler 22.03 and 24.03 LTS, 
#               AnolisOS 8 and 23, OpencloudOS 8 and 9, Kylin Server v10, 
#               UOS Server v20, Ubuntu Server 18.04, 20.04, 22.04 and 24.04 LTS,  
#               Debian 11 , 12 and 13, openSUSE 15“ operating systems.
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
    if [ ${MAIN_NAME} == "Ubuntu" -o ${MAIN_NAME} == "Debian" ];then
        FULL_NAME="${PRETTY_NAME}"
    elif [ ${MAIN_NAME} == "UOS" ];then
        FULL_NAME="${NAME}"
    else
        FULL_NAME="${NAME} ${VERSION_ID}"
    fi
}

os
SRC_DIR=/usr/local/src
INSTALL_DIR=/apps/mysql
DATA_DIR=/data/mysql

MYSQL_URL='https://cdn.mysql.com//Downloads/MySQL-8.4/'
MYSQL_FILE='mysql-8.4.5.tar.gz'

CMAKE_URL='https://cmake.org/files/v3.31/'
CMAKE_FILE='cmake-3.31.7-linux-x86_64.tar.gz'

GCC_INSTALL_DIR=/usr
GCC_URL='https://mirrors.cloud.tencent.com/gnu/gcc/gcc-11.5.0/'
GCC_FILE='gcc-11.5.0.tar.gz'
GMP_URL='http://gcc.gnu.org/pub/gcc/infrastructure/'
GMP_FILE='gmp-6.1.0.tar.bz2'
MPFR_URL='http://gcc.gnu.org/pub/gcc/infrastructure/'
MPFR_FILE='mpfr-3.1.6.tar.bz2'
MPC_URL='http://gcc.gnu.org/pub/gcc/infrastructure/'
MPC_FILE='mpc-1.0.3.tar.gz'
ISL_URL='http://gcc.gnu.org/pub/gcc/infrastructure/'
ISL_FILE='isl-0.18.tar.bz2'

check_mysql_file(){
    if [ ${MAIN_NAME} == "Rocky" -o ${MAIN_NAME} == "AlmaLinux" -o ${MAIN_NAME} == "CentOS" -o ${MAIN_NAME} == "openEuler" -o ${MAIN_NAME} == "Anolis" -o ${MAIN_NAME} == "OpenCloudOS" -o ${MAIN_NAME} == "Kylin" -o ${MAIN_NAME} == "UOS" ];then
        rpm -q wget &> /dev/null || { ${COLOR}"安装wget工具，请稍等......"${END};yum -y install wget &> /dev/null; }
    fi
    if [ ! -e ${MYSQL_FILE} ];then
        ${COLOR}"缺少${MYSQL_FILE}文件！"${END}
        ${COLOR}'开始下载MySQL源码包......'${END}
        wget ${MYSQL_URL}${MYSQL_FILE} || { ${COLOR}"MySQL源码包下载失败！"${END}; exit; }
    else
        ${COLOR}"${MYSQL_FILE}相关文件已准备好！"${END}
    fi
}

check_cmake_file(){
    if [ ! -e ${CMAKE_FILE} ];then
        ${COLOR}"缺少${CMAKE_FILE}文件!"${END}
        ${COLOR}'开始下载cmake二进制包......'${END}
        wget ${CMAKE_URL}${CMAKE_FILE} || { ${COLOR}"cmake二进制包下载失败！"${END}; exit; }
    else
        ${COLOR}"${CMAKE_FILE}相关文件已准备好！"${END}
    fi
}

check_gcc_file(){
    if [ ! -e ${GCC_FILE} ];then
        ${COLOR}"缺少${GCC_FILE}文件！"${END}
        ${COLOR}'开始下载gcc源码包......'${END}
        wget ${GCC_URL}${GCC_FILE} || { ${COLOR}"gcc源码包下载失败！"${END}; exit; }
    else
        ${COLOR}"${GCC_FILE}相关文件已准备好！"${END}
    fi
}

check_file(){
    cd  ${SRC_DIR}
    check_mysql_file
    if [ ${MAIN_NAME} == "CentOS" -a ${MAIN_VERSION_ID} == 7 ];then
        check_cmake_file
    fi
    if [ ${MAIN_NAME} == "Ubuntu" -a ${MAIN_VERSION_ID} == 18 ];then
        check_cmake_file
    fi
    if [ ${MAIN_NAME} == 'Anolis' -a ${MAIN_VERSION_ID} == 8 ];then
        check_gcc_file
    fi
    if [ ${MAIN_NAME} == 'OpenCloudOS' -a ${MAIN_VERSION_ID} == 8 ];then
        check_gcc_file
    fi
    if [ ${MAIN_NAME} == 'Kylin' -a ${MAIN_VERSION_ID} == 10 ];then
        check_gcc_file
    fi
    if [ ${MAIN_NAME} == 'UOS' -a ${MAIN_VERSION_ID} == 20 ];then
        check_gcc_file
    fi
    if [ ${MAIN_NAME} == 'openSUSE' -a ${MAIN_VERSION_ID} == 15 ];then
        check_gcc_file
    fi
}

install_cmake(){
    ${COLOR}'开始安装cmake，请稍等......'${END}
    tar xf ${CMAKE_FILE} -C /usr/local/
    CMAKE_DIR=`echo ${CMAKE_FILE}| sed -nr 's/^(.*[0-9]).*/\1/p'`
    ln -s /usr/local/${CMAKE_DIR}/bin/cmake /usr/bin/
}

install_gcc(){
    ${COLOR}'开始编译安装gcc，请稍等......'${END}
    tar xf ${GCC_FILE}
    GCC_DIR=`echo ${GCC_FILE}| sed -nr 's/^(.*[0-9]).*/\1/p'`
    cd ${GCC_DIR}
    wget ${GMP_URL}${GMP_FILE} || { ${COLOR}"gmp源码包下载失败！"${END}; exit; }
    wget ${MPFR_URL}${MPFR_FILE} || { ${COLOR}"mpfr源码包下载失败！"${END}; exit; }
    wget ${MPC_URL}${MPC_FILE} || { ${COLOR}"mpc源码包下载失败！"${END}; exit; }
    wget ${ISL_URL}${ISL_FILE} || { ${COLOR}"isl源码包下载失败！"${END}; exit; }
    ./contrib/download_prerequisites
    mkdir build
    cd build
    ../configure --prefix=${GCC_INSTALL_DIR} --disable-multilib 
    make -j $(nproc) && make install
    [ $? -eq 0 ] && ${COLOR}"gcc编译安装成功！"${END} ||  { ${COLOR}"gcc编译安装失败，退出！"${END};exit; }
}

install_mysql(){
    [ -d ${INSTALL_DIR} ] && { ${COLOR}"MySQL数据库已存在，安装失败！"${END};exit; }
    ${COLOR}"开始安装MySQL数据库......"${END}
    if [ ${MAIN_NAME} == "openSUSE" ];then
        id mysql &> /dev/null || { groupadd -r mysql && useradd -s /sbin/nologin -d  ${DATA_DIR} -r -g mysql mysql ; ${COLOR}"成功创建mysql用户！"${END}; }
    else
        id mysql &> /dev/null || { useradd -r -s /sbin/nologin -d ${DATA_DIR} mysql ; ${COLOR}"成功创建mysql用户！"${END}; }
    fi
    [ -d ${INSTALL_DIR} ] || mkdir -p ${DATA_DIR} &> /dev/null
    chown -R mysql:mysql ${DATA_DIR}
    ${COLOR}'开始安装MySQL依赖包，请稍等......'${END}
    if [ ${MAIN_NAME} == "Rocky" ];then
        if [ ${MAIN_VERSION_ID} == 8 ];then
            dnf config-manager --set-enabled powertools
        else
            dnf config-manager --set-enabled devel
        fi
    fi
    if [ ${MAIN_NAME} == "AlmaLinux" ];then
        if [ ${MAIN_VERSION_ID} == 8  ];then
            dnf config-manager --set-enabled powertools
        else
            dnf config-manager --set-enabled crb
        fi
    fi
    if [ ${MAIN_NAME} == "CentOS" ];then
       if [ ${MAIN_VERSION_ID} == 8  ];then
            dnf config-manager --set-enabled powertools
        else
            dnf config-manager --set-enabled crb
        fi
    fi
    if [ ${MAIN_NAME} == "OpenCloudOS" -a ${MAIN_VERSION_ID} == 8 ];then
        dnf config-manager --set-enabled PowerTools
    fi
    if [ ${MAIN_NAME} == "Rocky" ];then
        if [ ${MAIN_VERSION_ID} == 10 ];then
            yum install -y cmake gcc gcc-c++ openssl-devel ncurses-devel libtirpc-devel rpcgen boost-devel bison &> /dev/null
        fi
    fi
    if [ ${MAIN_NAME} == "Rocky" ];then
        if [ ${MAIN_VERSION_ID} == 8 -o ${MAIN_VERSION_ID} == 9 ];then
            yum install -y cmake gcc-toolset-12-gcc gcc-toolset-12-gcc-c++ gcc-toolset-12-binutils gcc-toolset-12-annobin-annocheck gcc-toolset-12-annobin-plugin-gcc gcc gcc-c++ openssl-devel ncurses-devel libtirpc-devel rpcgen &> /dev/null
        fi
    fi
    if [ ${MAIN_NAME} == "AlmaLinux" ];then
        if [ ${MAIN_VERSION_ID} == 10 ];then
            yum install -y cmake gcc gcc-c++ openssl-devel ncurses-devel libtirpc-devel rpcgen boost-devel bison &> /dev/null
        fi
    fi
    if [ ${MAIN_NAME} == "AlmaLinux" ];then
        if [ ${MAIN_VERSION_ID} == 8 -o ${MAIN_VERSION_ID} == 9 ];then
            yum install -y cmake gcc-toolset-12-gcc gcc-toolset-12-gcc-c++ gcc-toolset-12-binutils gcc-toolset-12-annobin-annocheck gcc-toolset-12-annobin-plugin-gcc gcc gcc-c++ openssl-devel ncurses-devel libtirpc-devel rpcgen &> /dev/null
        fi
    fi
    if [ ${MAIN_NAME} == "CentOS" ];then
        if [ ${MAIN_VERSION_ID} == 10 ];then
            yum install -y cmake openssl-devel ncurses-devel libtirpc-devel rpcgen boost-devel bison &> /dev/null
        fi
    fi
    if [ ${MAIN_NAME} == "CentOS" ];then
        if [ ${MAIN_VERSION_ID} == 8 -o ${MAIN_VERSION_ID} == 9 ];then
            yum install -y cmake gcc-toolset-12-gcc gcc-toolset-12-gcc-c++ gcc-toolset-12-binutils gcc-toolset-12-annobin-annocheck gcc-toolset-12-annobin-plugin-gcc gcc gcc-c++ openssl-devel ncurses-devel libtirpc-devel rpcgen &> /dev/null
        fi
    fi
    if [ ${MAIN_NAME} == "CentOS" -a ${MAIN_VERSION_ID} == 7 ];then
        yum install -y centos-release-scl &> /dev/null
        MIRROR=mirrors.tencent.com
        OS_RELEASE_FULL_VERSION=`cat /etc/centos-release | sed -rn 's/^(CentOS Linux release )(.*)( \(Core\))/\2/p'`
        sed -i.bak -e 's|^mirrorlist=|#mirrorlist=|g' -e 's|^# baseurl=|baseurl=|g' -e 's|^#baseurl=|baseurl=|g' -e 's|http://mirror.centos.org/centos|https://'${MIRROR}'/centos-vault|g' -e "s/7/${OS_RELEASE_FULL_VERSION}/g"  /etc/yum.repos.d/CentOS-SCLo-*.repo
        yum install -y devtoolset-11-gcc devtoolset-11-gcc-c++ devtoolset-11-binutil gcc gcc-++ openssl-devel ncurses-devel &> /dev/null
    fi
    if [ ${MAIN_NAME} == "openEuler" ];then
        if [ ${MAIN_VERSION_ID} == 22 -o ${MAIN_VERSION_ID} == 24 ];then
            yum install -y cmake make gcc gcc-c++ openssl-devel ncurses-devel libtirpc-devel rpcgen &> /dev/null
        fi
    fi
    if [ ${MAIN_NAME} == "Anolis" ];then
        if [ ${MAIN_VERSION_ID} == 23 ];then
            yum install -y cmake gcc gcc-c++ openssl-devel ncurses-devel libtirpc-devel rpcgen &> /dev/null
        fi
    fi
    if [ ${MAIN_NAME} == "Anolis" -a ${MAIN_VERSION_ID} == 8 ];then
        yum install -y cmake gcc gcc-c++ bzip2 openssl-devel ncurses-devel libtirpc-devel rpcgen &> /dev/null
    fi
    if [ ${MAIN_NAME} == 'OpenCloudOS' ];then
        if [ ${MAIN_VERSION_ID} == 9 ];then
            yum install -y cmake gcc gcc-c++ systemd-devel openssl-devel ncurses-devel libtirpc-devel rpcgen &> /dev/null
        fi
    fi
    if [ ${MAIN_NAME} == "OpenCloudOS" -a ${MAIN_VERSION_ID} == 8 ];then
        yum install -y cmake gcc gcc-c++ bzip2 openssl-devel ncurses-devel libtirpc-devel rpcgen &> /dev/null
    fi
    if [ ${MAIN_NAME} == "Kylin" ];then
        if [ ${MAIN_VERSION_ID} == 10 ];then
            yum install -y cmake make gcc gcc-c++ openssl-devel ncurses-devel libtirpc-devel rpcgen &> /dev/null
        fi
    fi
    if [ ${MAIN_NAME} == "UOS" ];then
        if [ ${MAIN_VERSION_ID} == 20 ];then
            yum install -y cmake ncurses-devel libtirpc-devel rpcgen &> /dev/null
        fi
    fi
    if [ ${MAIN_NAME} == "openSUSE" ];then
        if [ ${MAIN_VERSION_ID} == 15 ];then
            zypper install -y cmake gcc gcc-c++ libopenssl-devel ncurses-devel libtirpc-devel rpcgen &> /dev/null
        fi
    fi
    if [ ${MAIN_NAME} == "Ubuntu" ];then
        if [ ${MAIN_VERSION_ID} == 24 ];then
            apt update && apt install -y cmake g++ libssl-dev libncurses5-dev pkg-config libtirpc-dev
        fi
    fi
    if [ ${MAIN_NAME} == "Ubuntu" -a ${MAIN_VERSION_ID} == 22 ];then
        apt update && apt install -y cmake g++ libssl-dev libncurses5-dev pkg-config
    fi
    if [ ${MAIN_NAME} == "Ubuntu" -a ${MAIN_VERSION_ID} == 20 ];then
        add-apt-repository ppa:ubuntu-toolchain-r/test
        sed -i.bak 's@http://ppa.launchpad.net@https://launchpad.proxy.ustclug.org@g' /etc/apt/sources.list.d/ubuntu-toolchain-r-ubuntu-test-bionic.list
        apt update && apt install -y cmake gcc-11 g++-11 libssl-dev libncurses5-dev pkg-config
        update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 60 --slave /usr/bin/g++ g++ /usr/bin/g++-11
    fi
    if [ ${MAIN_NAME} == "Ubuntu" -a ${MAIN_VERSION_ID} == 18 ];then
        add-apt-repository ppa:ubuntu-toolchain-r/test
        sed -i.bak 's@http://ppa.launchpad.net@https://launchpad.proxy.ustclug.org@g' /etc/apt/sources.list.d/ubuntu-toolchain-r-ubuntu-test-bionic.list
        apt update && apt install -y gcc-11 g++-11 libssl-dev libncurses5-dev pkg-config
        update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 60 --slave /usr/bin/g++ g++ /usr/bin/g++-11
    fi
    if [ ${MAIN_NAME} == 'Debian' ];then
        if [ ${MAIN_VERSION_ID} == 11 -o ${MAIN_VERSION_ID} == 12 ];then
            apt update && apt install -y cmake g++ libssl-dev libncurses5-dev pkg-config
        fi
    fi
    if [ ${MAIN_NAME} == 'Debian' ];then
        if [ ${MAIN_VERSION_ID} == 13 ];then
            apt update && apt install -y cmake g++ libssl-dev libncurses5-dev pkg-config libtirpc-dev
        fi
    fi
    if [ ${MAIN_NAME} == "CentOS" -a ${MAIN_VERSION_ID} == 7 ];then
        install_cmake
    fi
    if [ ${MAIN_NAME} == 'Ubuntu' -a ${MAIN_VERSION_ID} == 18 ];then
        install_cmake
    fi
    if [ ${MAIN_NAME} == 'Anolis' -a ${MAIN_VERSION_ID} == 8 ];then
        install_gcc
    fi
    if [ ${MAIN_NAME} == 'OpenCloudOS' -a ${MAIN_VERSION_ID} == 8 ];then
        install_gcc
    fi
    if [ ${MAIN_NAME} == 'Kylin' ];then
        if [ ${MAIN_VERSION_ID} == 10 ];then
            install_gcc
        fi
    fi
    if [ ${MAIN_NAME} == 'UOS' ];then
        if [ ${MAIN_VERSION_ID} == 20 ];then
            install_gcc
        fi
    fi
    if [ ${MAIN_NAME} == 'openSUSE' ];then
        if [ ${MAIN_VERSION_ID} == 15 ];then
            install_gcc
        fi
    fi
    ${COLOR}'开始编译安装MySQL，请稍等......'${END}
    cd  ${SRC_DIR}
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
    tar xf ${MYSQL_FILE}
    MYSQL_DIR=`echo ${MYSQL_FILE}| sed -nr 's/^(.*[0-9]).*/\1/p'`
    cd ${MYSQL_DIR}
    if [ ${MAIN_NAME} == "CentOS" -a ${MAIN_VERSION_ID} == 9 ];then
        cmake \
        -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
        -DCMAKE_CXX_FLAGS="-I/usr/include/tirpc/rpc" \
        -DMYSQL_UNIX_ADDR=${DATA_DIR}/mysql.sock \
        -DSYSCONFDIR=/etc \
        -DSYSTEMD_PID_DIR=${INSTALL_DIR} \
        -DDEFAULT_CHARSET=utf8mb4 \
        -DDEFAULT_COLLATION=utf8mb4_general_ci \
        -DWITH_INNOBASE_STORAGE_ENGINE=1 \
        -DWITH_ARCHIVE_STORAGE_ENGINE=1 \
        -DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
        -DWITH_PERFSCHEMA_STORAGE_ENGINE=1 \
        -DMYSQL_DATADIR=${DATA_DIR}\
        -DFORCE_INSOURCE_BUILD=1 \
        -DWITH_SYSTEMD=1
    elif [ ${MAIN_NAME} == "Debian" -a ${MAIN_VERSION_ID} == 13 ];then
        cmake \
        -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
        -DMYSQL_UNIX_ADDR=${DATA_DIR}/mysql.sock \
        -DSYSCONFDIR=/etc \
        -DSYSTEMD_PID_DIR=${INSTALL_DIR} \
        -DDEFAULT_CHARSET=utf8mb4 \
        -DDEFAULT_COLLATION=utf8mb4_general_ci \
        -DWITH_INNOBASE_STORAGE_ENGINE=1 \
        -DWITH_ARCHIVE_STORAGE_ENGINE=1 \
        -DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
        -DWITH_PERFSCHEMA_STORAGE_ENGINE=1 \
        -DMYSQL_DATADIR=${DATA_DIR}\
        -DWITH_BOOST=/usr/local/src/${MYSQL_DIR}/boost/boost_1_77_0/ \
        -DFORCE_INSOURCE_BUILD=1
    else
        cmake \
        -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
        -DMYSQL_UNIX_ADDR=${DATA_DIR}/mysql.sock \
        -DSYSCONFDIR=/etc \
        -DSYSTEMD_PID_DIR=${INSTALL_DIR} \
        -DDEFAULT_CHARSET=utf8mb4 \
        -DDEFAULT_COLLATION=utf8mb4_general_ci \
        -DWITH_INNOBASE_STORAGE_ENGINE=1 \
        -DWITH_ARCHIVE_STORAGE_ENGINE=1 \
        -DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
        -DWITH_PERFSCHEMA_STORAGE_ENGINE=1 \
        -DMYSQL_DATADIR=${DATA_DIR}\
        -DFORCE_INSOURCE_BUILD=1 \
        -DWITH_SYSTEMD=1
    fi
    make -j $(nproc) && make install
    [ $? -eq 0 ] && ${COLOR}"MySQL编译安装成功！"${END} ||  { ${COLOR}"MySQL编译安装失败，退出！"${END};exit; }
    echo 'PATH='${INSTALL_DIR}'/bin:$PATH' > /etc/profile.d/mysql.sh
    . /etc/profile.d/mysql.sh
	chown -R mysql:mysql ${INSTALL_DIR}
    mysqld --initialize-insecure --user=mysql --basedir=${INSTALL_DIR} --datadir=${DATA_DIR}
    cat > /etc/my.cnf <<EOF
[mysqld]
user=mysql
basedir=${INSTALL_DIR}
datadir=${DATA_DIR}
port=3306
socket=${DATA_DIR}/mysql.sock 
log-error=${DATA_DIR}/mysql.log
pid-file=${DATA_DIR}/mysql.pid 

[client]
port=3306
socket=${DATA_DIR}/mysql.sock
EOF
    if [ ${MAIN_NAME} == "Rocky" -o ${MAIN_NAME} == "AlmaLinux" -o ${MAIN_NAME} == "CentOS" -o ${MAIN_NAME} == "openEuler" -o ${MAIN_NAME} == "Anolis" -o ${MAIN_NAME} == "OpenCloudOS" -o ${MAIN_NAME} == "Kylin" -o ${MAIN_NAME} == "UOS" -o ${MAIN_NAME} == "openSUSE" ];then
        cp ${INSTALL_DIR}/usr/lib/systemd/system/mysqld.service /usr/lib/systemd/system/
    elif [ ${MAIN_NAME} == "Ubuntu" ];then
        if [ ${MAIN_VERSION_ID} == 24 ];then	
            cp ${INSTALL_DIR}/usr/lib/systemd/system/mysqld.service /lib/systemd/system/
        fi
    elif [ ${MAIN_NAME} == "Debian" ];then
        if [ ${MAIN_VERSION_ID} == 13 ];then	
            cat > /lib/systemd/system/mysqld.service  <<EOF
[Unit]
Description=MySQL Server
After=network.target

[Service]
User=mysql
Group=mysql
ExecStart=${INSTALL_DIR}/bin/mysqld --defaults-file=/etc/my.cnf
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
        fi
    else
       cat > /lib/systemd/system//mysqld.service  <<EOF
# Copyright (c) 2015, 2025, Oracle and/or its affiliates.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License, version 2.0,
# as published by the Free Software Foundation.
#
# This program is designed to work with certain software (including
# but not limited to OpenSSL) that is licensed under separate terms,
# as designated in a particular file or component or in included license
# documentation.  The authors of MySQL hereby grant you an additional
# permission to link the program and your derivative works with the
# separately licensed software that they have either included with
# the program or referenced in the documentation.
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
    systemctl daemon-reload && systemctl enable --now mysqld &> /dev/null
    [ $? -ne 0 ] && { ${COLOR}"数据库启动失败，退出！"${END};exit; }
    ${COLOR}"${FULL_NAME}操作系统，MySQL数据库安装完成！"${END}
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
    if [ ${MAIN_VERSION_ID} == 10 ];then
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
    ${COLOR}"此脚本不支持${FULL_NAME}操作系统！"${END}
fi
