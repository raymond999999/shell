#!/bin/bash
#
#**********************************************************************************
#Author:        Raymond
#QQ:            88563128
#MP:            Raymond运维
#Date:          2025-09-10
#FileName:      install_mariadb_source_v3.sh
#URL:           https://wx.zsxq.com/group/15555885545422
#Description:   The mariadb source script install supports 
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
INSTALL_DIR=/apps/mariadb
DATA_DIR=/data/mariadb

# mariadb 11.8.3包下载地址："https://mirrors.tuna.tsinghua.edu.cn/mariadb///mariadb-11.8.3/source/mariadb-11.8.3.tar.gz"
# fmt 11.1.4包下载地址："https://gh-proxy.com/https://github.com/fmtlib/fmt/releases/download/11.1.4/fmt-11.1.4.zip"

# mariadb 10.11.14包下载地址："https://mirrors.tuna.tsinghua.edu.cn/mariadb/mariadb-10.11.14/source/mariadb-10.11.14.tar.gz"
# fmt 11.0.2包下载地址："https://gh-proxy.com/https://github.com/fmtlib/fmt/releases/download/11.0.2/fmt-11.0.2.zip"

if [ ${MAIN_NAME} == "CentOS" -a ${MAIN_VERSION_ID} == 7 ];then
    MARIADB_VERSION=10.11.14
    FMT_VERSION=11.0.2
else
    MARIADB_VERSION=11.8.3
    FMT_VERSION=11.1.4
fi
MARIADB_URL="https://mirrors.tuna.tsinghua.edu.cn/mariadb/mariadb-${MARIADB_VERSION}/source/"
MARIADB_FILE="mariadb-${MARIADB_VERSION}.tar.gz"

FMT_URL="https://gh-proxy.com/https://github.com/fmtlib/fmt/releases/download/${FMT_VERSION}/"
FMT_FILE="fmt-${FMT_VERSION}.zip"

CMAKE_URL='https://cmake.org/files/v3.31/'
CMAKE_FILE='cmake-3.31.7-linux-x86_64.tar.gz'

check_mysql_file(){
    if [ ${MAIN_NAME} == "Rocky" -o ${MAIN_NAME} == "AlmaLinux" -o ${MAIN_NAME} == "CentOS" -o ${MAIN_NAME} == "Anolis" -o ${MAIN_NAME} == "OpenCloudOS" -o ${MAIN_NAME} == "Kylin" ];then
        rpm -q wget &> /dev/null || { ${COLOR}"安装wget工具，请稍等......"${END};yum -y install wget &> /dev/null; }
    fi
    if [ ! -e ${MARIADB_FILE} ];then
        ${COLOR}"缺少${MARIADB_FILE}文件！"${END}
        ${COLOR}'开始下载MariaDB源码包......'${END}
        wget ${MARIADB_URL}${MARIADB_FILE} || { ${COLOR}"MariaDB源码包下载失败！"${END}; exit; }
    else
        ${COLOR}"${MARIADB_FILE}文件已准备好！"${END}
    fi
}

check_fmt_file(){
    if [ ! -e ${FMT_FILE} ];then
        ${COLOR}"缺少${FMT_FILE}文件!"${END}
        ${COLOR}'开始下载fmt包......'${END}
        wget ${FMT_URL}${FMT_FILE} || { ${COLOR}"fmt包下载失败！"${END}; exit; }
    else
        ${COLOR}"${FMT_FILE}相关文件已准备好！"${END}
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

check_file(){
    cd  ${SRC_DIR}
    check_mysql_file
    check_fmt_file
    if [ ${MAIN_NAME} == "CentOS" -a ${MAIN_VERSION_ID} == 7 ];then
        check_cmake_file
    fi
    if [ ${MAIN_NAME} == "Ubuntu" -a ${MAIN_VERSION_ID} == 18 ];then
        check_cmake_file
    fi
}

install_cmake(){
    ${COLOR}'开始安装cmake，请稍等......'${END}
    tar xf ${CMAKE_FILE} -C /usr/local/
    CMAKE_DIR=`echo ${CMAKE_FILE}| sed -nr 's/^(.*[0-9]).*/\1/p'`
    ln -s /usr/local/${CMAKE_DIR}/bin/cmake /usr/bin/
}

install_mariadb(){
    [ -d ${INSTALL_DIR} ] && { ${COLOR}"MariaDB数据库已存在，安装失败！"${END};exit; }
    ${COLOR}"开始安装MariaDB数据库......"${END}
    if [ ${MAIN_NAME} == "openSUSE" ];then
        id mysql &> /dev/null || { groupadd -r mysql && useradd -s /sbin/nologin -d ${DATA_DIR} -r -g mysql mysql; ${COLOR}"成功创建mysql用户!"${END}; }
    else
        id mysql &> /dev/null || { useradd -r -s /sbin/nologin -d ${DATA_DIR} mysql ; ${COLOR}"成功创建mysql用户！"${END}; }
    fi
    [ -d ${DATA_DIR} ] || mkdir -p ${DATA_DIR} &> /dev/null
    chown -R mysql:mysql ${DATA_DIR}
    ${COLOR}'开始安装MariaDB依赖包，请稍等......'${END}
    if [ ${MAIN_NAME} == "Rocky" ];then
        if [ ${MAIN_VERSION_ID} == 8 ];then
            yum install -y cmake gcc gcc-c++ openssl-devel ncurses-devel systemd-devel &> /dev/null
        else
            yum install -y cmake gcc gcc-c++ openssl-devel ncurses-devel pcre2-devel systemd-devel &> /dev/null
        fi
    fi
    if [ ${MAIN_NAME} == "AlmaLinux" ];then
        if [ ${MAIN_VERSION_ID} == 8 ];then
            yum install -y cmake gcc gcc-c++ openssl-devel ncurses-devel systemd-devel &> /dev/null
        else
            yum install -y cmake gcc gcc-c++ openssl-devel ncurses-devel pcre2-devel systemd-devel &> /dev/null
        fi
    fi

    if [ ${MAIN_NAME} == "CentOS" ];then
        if [ ${MAIN_VERSION_ID} == 7 ];then
            yum install -y gcc gcc-c++ openssl-devel ncurses-devel pcre2-devel systemd-devel &> /dev/null
        elif [ ${MAIN_VERSION_ID} == 8 ];then
            yum install -y cmake gcc gcc-c++ openssl-devel ncurses-devel systemd-devel &> /dev/null
        else
            yum install -y cmake openssl-devel ncurses-devel pcre2-devel systemd-devel &> /dev/null
        fi
    fi
    if [ ${MAIN_NAME} == "openEuler" ];then
        if [ ${MAIN_VERSION_ID} == 22 ];then
            yum install -y cmake make gcc gcc-c++ openssl-devel ncurses-devel systemd-devel &> /dev/null
        else
            yum install -y cmake make gcc gcc-c++ openssl-devel ncurses-devel pcre2-devel systemd-devel &> /dev/null
        fi
    fi
    if [ ${MAIN_NAME} == "Anolis" ];then
        if [ ${MAIN_VERSION_ID} == 8 ];then
            yum install -y cmake gcc gcc-c++ openssl-devel ncurses-devel systemd-devel &> /dev/null
        else
            yum install -y cmake gcc gcc-c++ openssl-devel ncurses-devel pcre2-devel systemd-devel &> /dev/null
        fi
    fi
    if [ ${MAIN_NAME} == 'OpenCloudOS' ];then
        if [ ${MAIN_VERSION_ID} == 8 ];then
            yum install -y cmake gcc gcc-c++ openssl-devel ncurses-devel systemd-devel &> /dev/null
        else
            yum install -y cmake gcc gcc-c++ openssl-devel ncurses-devel pcre2-devel systemd-devel &> /dev/null
        fi
    fi
    if [ ${MAIN_NAME} == "Kylin" ];then
        if [ ${MAIN_VERSION_ID} == 10 ];then
            yum install -y cmake make gcc gcc-c++ openssl-devel ncurses-devel systemd-devel &> /dev/null
        fi
    fi
    if [ ${MAIN_NAME} == "UOS" ];then
        if [ ${MAIN_VERSION_ID} == 20 ];then
            yum install -y cmake ncurses-devel systemd-devel &> /dev/null
        fi
    fi
    if [ ${MAIN_NAME} == "openSUSE" ];then
        if [ ${MAIN_VERSION_ID} == 15 ];then
            zypper install -y cmake gcc gcc-c++ libopenssl-devel ncurses-devel pcre2-devel systemd-devel &> /dev/null
        fi
    fi
    if [ ${MAIN_NAME} == "Ubuntu" ];then
        if [ ${MAIN_VERSION_ID} == 18 ];then
            apt update && apt install -y g++ libssl-dev libncurses5-dev libpcre2-dev libsystemd-dev
        else
            apt update && apt install -y cmake g++ libssl-dev libncurses5-dev libpcre2-dev libsystemd-dev
        fi
    fi
    if [ ${MAIN_NAME} == 'Debian' ];then
        if [ ${MAIN_VERSION_ID} == 11 -o ${MAIN_VERSION_ID} == 12 -o ${MAIN_VERSION_ID} == 13 ];then
            apt update && apt install -y cmake g++ libssl-dev libncurses5-dev libpcre2-dev libsystemd-dev
        fi
    fi
    if [ ${MAIN_NAME} == "CentOS" -a ${MAIN_VERSION_ID} == 7 ];then
        install_cmake
    fi
    if [ ${MAIN_NAME} == 'Ubuntu' -a ${MAIN_VERSION_ID} == 18 ];then
        install_cmake
    fi
    ${COLOR}'开始编译安装MariaDB，请稍等......'${END}
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
    tar xf ${MARIADB_FILE}
    MARIADB_DIR=`echo ${MARIADB_FILE}| sed -nr 's/^(.*[0-9]).*/\1/p'`
    mkdir -p /usr/local/src/${MARIADB_DIR}/extra/libfmt/src/
    mv ${FMT_FILE} /usr/local/src/${MARIADB_DIR}/extra/libfmt/src/
    cd ${MARIADB_DIR}
    cmake . \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
    -DMYSQL_DATADIR=${DATA_DIR}/ \
    -DSYSCONFDIR=/etc/ \
    -DMYSQL_USER=mysql \
    -DWITH_INNOBASE_STORAGE_ENGINE=1 \
    -DWITH_ARCHIVE_STORAGE_ENGINE=1 \
    -DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
    -DWITH_PARTITION_STORAGE_ENGINE=1 \
    -DWITHOUT_MROONGA_STORAGE_ENGINE=1 \
    -DWITH_DEBUG=0 \
    -DWITH_READLINE=1 \
    -DWITH_SSL=system \
    -DWITH_ZLIB=system \
    -DWITH_PCRE=system \
    -DWITH_BOOST=system \
    -DWITH_LIBWRAP=0 \
    -DENABLED_LOCAL_INFILE=1 \
    -DMYSQL_UNIX_ADDR=${DATA_DIR}/mariadb.sock \
    -DDEFAULT_CHARSET=utf8mb4 \
    -DDEFAULT_COLLATION=utf8mb4_general_ci \
    -DWITH_SYSTEMD=yes
    make -j $(nproc) && make install
    [ $? -eq 0 ] && ${COLOR}"MariaDB编译安装成功"${END} ||  { ${COLOR}"MariaDB编译安装失败,退出!"${END};exit; }
	echo 'PATH='${INSTALL_DIR}'/bin:$PATH' > /etc/profile.d/mariadb.sh
    .  /etc/profile.d/mariadb.sh
    chown -R mysql:mysql ${INSTALL_DIR}
    cd ${INSTALL_DIR}
    ./scripts/mysql_install_db --datadir=${DATA_DIR} --user=mysql
    cat > /etc/my.cnf <<-EOF
[mariadb]
basedir=${INSTALL_DIR}/
datadir=${DATA_DIR}
port=3306
socket=${DATA_DIR}/mariadb.sock
pid-file=${DATA_DIR}/mariadb.pid 
log-error=${DATA_DIR}/mariadb.log

[client]
port=3306
socket=${DATA_DIR}/mariadb.sock
EOF
    if [ ${MAIN_NAME} == "Ubuntu" -o ${MAIN_NAME} == "Debian" ];then
        cp ${INSTALL_DIR}/support-files/systemd/mariadb.service /lib/systemd/system/
    else
        cp ${INSTALL_DIR}/support-files/systemd/mariadb.service /usr/lib/systemd/system/
    fi 
    systemctl daemon-reload && systemctl enable --now mariadb &> /dev/null
    [ $? -ne 0 ] && { ${COLOR}"数据库启动失败，退出！"${END};exit; }
}

mariadb_secure(){
    ${INSTALL_DIR}/bin/mariadb-secure-installation <<EOF

y
n
y
y
y
y
EOF
    ${COLOR}"${FULL_NAME}操作系统，MariaDB数据库安装完成！"${END}
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
