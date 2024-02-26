#!/bin/bash
#
#******************************************************************************************************************
#Author:        Raymond
#QQ:            88563128
#Date:          2024-02-25
#FileName:      install_mariadb_source_v2.sh
#URL:           raymond.blog.csdn.net
#Description:   install_mariadb_source for CentOS 7 & CentOS Stream 8/9 & Ubuntu 18.04/20.04/22.04 & Rocky 8/9
#Copyright (C): 2024 All rights reserved
#******************************************************************************************************************
SRC_DIR=/usr/local/src
INSTALL_DIR=/apps/mysql
DATA_DIR=/data/mysql
COLOR="echo -e \\033[01;31m"
END='\033[0m'

MARIADB_URL='https://mirrors.tuna.tsinghua.edu.cn/mariadb/mariadb-11.3.2/source/'
MARIADB_FILE='mariadb-11.3.2.tar.gz'
MARIADB_VERSION='11.3'

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
    if [ ! -e ${MARIADB_FILE} ];then
        ${COLOR}"缺少${MARIADB_FILE}文件"${END}
        ${COLOR}'开始下载MariaDB源码包'${END}
        wget ${MARIADB_URL}${MARIADB_FILE} || { ${COLOR}"MariaDB源码包下载失败"${END}; exit; }
    else
        ${COLOR}"${MARIADB_FILE}文件已准备好"${END}
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
    [ -d ${INSTALL_DIR} ] && { ${COLOR}"MariaDB数据库已存在，安装失败"${END};exit; }
    ${COLOR}"开始安装MariaDB数据库..."${END}
    ${COLOR}'开始安装MariaDB依赖包'${END}
    if [ ${OS_RELEASE_VERSION} == 8 -o ${OS_RELEASE_VERSION} == 9 ] &> /dev/null;then
        yum -y install bison zlib-devel libcurl-devel libarchive boost-devel gcc gcc-c++ cmake ncurses-devel gnutls-devel libxml2-devel openssl-devel libevent-devel libaio-devel &> /dev/null
    elif [[ ${OS_RELEASE_VERSION} == 7 ]] &> /dev/null;then
        yum -y install bison bison-devel zlib-devel libcurl-devel libarchive-devel boost-devel gcc gcc-c++ ncurses-devel gnutls-devel libxml2-devel openssl-devel libevent-devel libaio-devel pcre2 pcre2-devel &> /dev/null
    else
        apt update &> /dev/null;apt -y install software-properties-common devscripts equivs &> /dev/null
        apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8 &> /dev/null
        add-apt-repository --update --yes --enable-source 'deb [arch=amd64] http://nyc2.mirrors.digitalocean.com/mariadb/repo/'${MARIADB_VERSION}'/ubuntu '$(lsb_release -sc)' main' &> /dev/null
        apt update &> /dev/null
		apt -y build-dep mariadb &> /dev/null
    fi

    id mysql &> /dev/null || { useradd -r -s /sbin/nologin -d ${DATA_DIR} mysql ; ${COLOR}"创建mysql用户"${END}; }
    [ -d ${INSTALL_DIR} ] || mkdir -p ${DATA_DIR} &> /dev/null
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
    tar xf ${MARIADB_FILE}
    MARIADB_DIR=`echo ${MARIADB_FILE}| sed -nr 's/^(.*[0-9]).*/\1/p'`
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
    -DWITH_LIBWRAP=0 \
    -DENABLED_LOCAL_INFILE=1 \
    -DMYSQL_UNIX_ADDR=${DATA_DIR}/mysql.sock \
    -DDEFAULT_CHARSET=utf8 \
    -DDEFAULT_COLLATION=utf8_general_ci
    make -j ${CPUS} && make install
    [ $? -eq 0 ] && ${COLOR}"MariaDB编译安装成功"${END} ||  { ${COLOR}"MariaDB编译安装失败,退出!"${END};exit; }

	echo 'PATH='${INSTALL_DIR}'/bin:$PATH' > /etc/profile.d/mysql.sh
    .  /etc/profile.d/mysql.sh
    chown -R mysql.mysql ${INSTALL_DIR}

    cd ${INSTALL_DIR}
    ./scripts/mysql_install_db --datadir=${DATA_DIR} --user=mysql

    cat > /etc/my.cnf <<-EOF
[mysqld]
basedir=${INSTALL_DIR}
datadir=${DATA_DIR}
port=3306
socket=${DATA_DIR}/mysql.sock 
pid-file=${DATA_DIR}/mysql.pid 

[mysqld_safe]
log-error=${DATA_DIR}/mysql.log 

[mysql]
default-character-set=utf8mb4

[client]
port=3306
socket=${DATA_DIR}/mysql.sock
default-character-set=utf8mb4
EOF

    if [ ${OS_ID} == "CentOS" -o ${OS_ID} == "Rocky" ] &> /dev/null;then
        rpm -q chkconfig &> /dev/null || { ${COLOR}"安装chkconfig包，请稍等..."${END};yum -y install chkconfig &> /dev/null; }
    fi
    cp ${INSTALL_DIR}/support-files/mysql.server  /etc/init.d/mysqld
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

mysql_secure(){
    ${INSTALL_DIR}/bin/mysql_secure_installation <<EOF

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
