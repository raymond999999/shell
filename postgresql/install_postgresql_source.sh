#!/bin/bash
#
#**********************************************************************************
#Author:        Raymond
#QQ:            88563128
#MP:            Raymond运维
#Date:          2025-09-30
#FileName:      install_postgresql_source.sh
#URL:           https://wx.zsxq.com/group/15555885545422
#Description:   The postgresql source script install supports 
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
SRC_DIR=/usr/local/src
INSTALL_DIR=/apps/pgsql
DATA_DIR=/data/pgsql
DB_USER=postgres
POSTGRESQL_VERSION=17.6
POSTGRESQL_URL="https://ftp.postgresql.org/pub/source/v${POSTGRESQL_VERSION}/"
POSTGRESQL_FILE="postgresql-${POSTGRESQL_VERSION}.tar.gz"
DB_USER_PASSWORD=123456

check_file(){
    cd  ${SRC_DIR}
    if [ ${MAIN_NAME} == "Rocky" -o ${MAIN_NAME} == "AlmaLinux" -o ${MAIN_NAME} == "CentOS" -o ${MAIN_NAME} == "Anolis" -o ${MAIN_NAME} == "OpenCloudOS" -o ${MAIN_NAME} == "Kylin" ];then
        rpm -q wget &> /dev/null || { ${COLOR}"安装wget工具，请稍等......"${END};yum -y install wget &> /dev/null; }
    fi
    if [ ! -e ${POSTGRESQL_FILE} ];then
        ${COLOR}"缺少${POSTGRESQL_FILE}文件！"${END}
        ${COLOR}'开始下载PostgreSQL源码包......'${END}
        wget ${POSTGRESQL_URL}${POSTGRESQL_FILE} || { ${COLOR}"PostgreSQL源码包下载失败！"${END}; exit; }
    else
        ${COLOR}"${POSTGRESQL_FILE}文件已准备好！"${END}
    fi
}

install_postgresql(){
    [ -d ${INSTALL_DIR} ] && { ${COLOR}"PostgreSQL数据库已存在，安装失败！"${END};exit; }
    ${COLOR}"开始安装PostgreSQL数据库......"${END}
    ${COLOR}'开始安装PostgreSQL依赖包，请稍等......'${END}
    if [ ${MAIN_NAME} == "Rocky" -o ${MAIN_NAME} == "AlmaLinux" -o ${MAIN_NAME} == "CentOS" -o ${MAIN_NAME} == "OpenCloudOS" ];then
        yum install -y gcc libicu-devel bison flex perl readline-devel zlib-devel openssl-devel libxml2-devel systemd-devel docbook-dtds docbook-style-xsl libxslt &> /dev/null
    fi
    if [ ${MAIN_NAME} == "openEuler" ];then
        yum install -y gcc libicu-devel bison flex readline-devel zlib-devel openssl-devel libxml2-devel systemd-devel docbook-dtds docbook-style-xsl libxslt &> /dev/null
    fi
    if [ ${MAIN_NAME} == "Anolis" ];then
        if [ ${MAIN_VERSION_ID} == 8 ];then
            yum install -y gcc libicu-devel bison flex readline-devel zlib-devel openssl-devel libxml2-devel systemd-devel make docbook-dtds docbook-style-xsl libxslt &> /dev/null
        else
            yum install -y gcc libicu-devel bison flex readline-devel zlib-devel openssl-devel libxml2-devel systemd-devel perl-FindBin perl-core docbook-dtds docbook-style-xsl libxslt &> /dev/null
        fi
    fi
    if [ ${MAIN_NAME} == "Kylin" ];then
        yum install -y gcc libicu-devel bison flex perl readline-devel zlib-devel openssl-devel libxml2-devel systemd-devel docbook-dtds docbook-style-xsl libxslt &> /dev/null
    fi
    if [ ${MAIN_NAME} == "UOS" ];then
        if [ ${MAIN_VERSION_ID} == 20 ];then
            yum install -y libicu-devel bison flex perl readline-devel systemd-devel docbook-dtds docbook-style-xsl libxslt &> /dev/null
        fi
    fi
    if [ ${MAIN_NAME} == "openSUSE" ];then
        if [ ${MAIN_VERSION_ID} == 15 ];then
            zypper install -y gcc libicu-devel bison flex readline-devel zlib-devel openssl-devel libxml2-devel systemd-devel make docbook-xsl-stylesheets &> /dev/null
        fi
    fi
    if [ ${MAIN_NAME} == "Ubuntu" ];then
        if [ ${MAIN_VERSION_ID} == 18 ];then
            apt update && apt install -y gcc pkg-config libicu-dev bison flex libreadline-dev libssl-dev libxml2-dev libsystemd-dev make docbook-xml docbook-xsl libxml2-utils xsltproc fop
        else
            apt update && apt install -y gcc pkg-config libicu-dev bison flex libreadline-dev zlib1g-dev libssl-dev libxml2-dev libsystemd-dev make docbook-xml docbook-xsl libxml2-utils xsltproc fop
        fi
    fi
    if [ ${MAIN_NAME} == 'Debian' ];then
        apt update && apt install -y gcc pkg-config libicu-dev bison flex libreadline-dev zlib1g-dev libssl-dev libxml2-dev libsystemd-dev make docbook-xml docbook-xsl libxml2-utils xsltproc fop
    fi
    ${COLOR}'开始编译安装PostgreSQL，请稍等......'${END}
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
    tar xf ${POSTGRESQL_FILE}
    POSTGRESQL_DIR=`echo ${POSTGRESQL_FILE}| sed -nr 's/^(.*[0-9]).*/\1/p'`
    cd ${POSTGRESQL_DIR}
    ./configure --prefix=${INSTALL_DIR} --with-openssl --with-libxml --with-systemd
    make -j $(nproc) world
    make install-world
    [ $? -eq 0 ] && ${COLOR}"PostgreSQL编译安装成功!"${END} ||  { ${COLOR}"PostgreSQL编译安装失败,退出!"${END};exit; }
    if [ ${MAIN_NAME} == "openSUSE" ];then
        id ${DB_USER} &> /dev/null || { groupadd ${DB_USER} && useradd -s /bin/bash -m -d /home/${DB_USER} -g ${DB_USER} ${DB_USER}; ${COLOR}"成功创建${DB_USER}用户!"${END}; }
    else
        id ${DB_USER} &> /dev/null || { useradd -s /bin/bash -m -d /home/${DB_USER} ${DB_USER} ; ${COLOR}"成功创建${DB_USER}用户！"${END}; }
    fi
    echo ${DB_USER}:${DB_USER_PASSWORD}|chpasswd
    [ -d ${DATA_DIR} ] || mkdir -p ${DATA_DIR}/
    chown -R ${DB_USER}:${DB_USER} ${DATA_DIR}/   
    cat > /etc/profile.d/pgsql.sh <<EOF
export PGHOME=${INSTALL_DIR}
export PATH=${INSTALL_DIR}/bin/:\$PATH
export PGDATA=${DATA_DIR}
export PGUSER=${DB_USER}
export MANPATH=${INSTALL_DIR}/share/man

alias pgstart="pg_ctl -D ${DATA_DIR} start"
alias pgstop="pg_ctl -D ${DATA_DIR} stop"
alias pgrestart="pg_ctl -D ${DATA_DIR} restart"
alias pgstatus="pg_ctl -D ${DATA_DIR} status"
EOF
    su - ${DB_USER} -c "${INSTALL_DIR}/bin/initdb -D ${DATA_DIR}"
    if [ ${MAIN_NAME} == "Ubuntu" -o ${MAIN_NAME} == "Debian" ];then
        cat > /lib/systemd/system/postgresql.service <<EOF
[Unit]
Description=PostgreSQL database server
After=network.target

[Service]
User=${DB_USER}
Group=${DB_USER}
ExecStart=${INSTALL_DIR}/bin/postgres -D ${DATA_DIR}
ExecReload=/bin/kill -HUP \$MAINPID

[Install]
WantedBy=multi-user.target
EOF
    else
        cat > /usr/lib/systemd/system/postgresql.service <<EOF
[Unit]
Description=PostgreSQL database server
After=network.target

[Service]
User=${DB_USER}
Group=${DB_USER}
ExecStart=${INSTALL_DIR}/bin/postgres -D ${DATA_DIR}
ExecReload=/bin/kill -HUP \$MAINPID

[Install]
WantedBy=multi-user.target
EOF
    fi
    systemctl daemon-reload && systemctl enable --now postgresql &> /dev/null
    [ $? -ne 0 ] && { ${COLOR}"数据库启动失败，退出！"${END};exit; }
    ${COLOR}"${PRETTY_NAME}操作系统，PostgreSQL数据库安装完成！"${END}
}

main(){
    check_file
    install_postgresql
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
    ${COLOR}"此脚本不支持${PRETTY_NAME}操作系统！"${END}
fi
