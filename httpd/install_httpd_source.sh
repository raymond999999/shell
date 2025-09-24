#!/bin/bash
#
#**********************************************************************************
#Author:        Raymond
#QQ:            88563128
#MP:            Raymond运维
#Date:          2025-09-24
#FileName:      install_httpd_source.sh
#URL:           https://wx.zsxq.com/group/15555885545422
#Description:   The mysql source script install supports 
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
INSTALL_DIR=/apps/httpd
APR_URL=https://mirrors.cloud.tencent.com/apache/apr/
APR_FILE=apr-1.7.6.tar.gz
APR_UTIL_URL=https://mirrors.cloud.tencent.com/apache/apr/
APR_UTIL_FILE=apr-util-1.6.3.tar.gz
HTTPD_URL=https://mirrors.cloud.tencent.com/apache/httpd/
HTTPD_FILE=httpd-2.4.65.tar.gz
MPM=event

check_file(){
    cd  ${SRC_DIR}
    if [ ${MAIN_NAME} == "Rocky" -o ${MAIN_NAME} == "AlmaLinux" -o ${MAIN_NAME} == "CentOS" -o ${MAIN_NAME} == "Anolis" -o ${MAIN_NAME} == "OpenCloudOS" -o ${MAIN_NAME} == "Kylin" ];then
        rpm -q wget &> /dev/null || { ${COLOR}"安装wget工具，请稍等......"${END};yum -y install wget &> /dev/null; }
    fi
    if [ ! -e ${APR_FILE} ];then
        ${COLOR}"缺少${APR_FILE}文件！"${END}
        ${COLOR}"开始下载${APR_FILE}源码包......"${END}
        wget ${APR_URL}${APR_FILE} || { ${COLOR}"下载${APR_FILE}源码包下载失败！"${END}; exit; }
    else
        ${COLOR}"${APR_FILE}文件已准备好！"${END}
    fi
    if [ ! -e ${APR_UTIL_FILE} ];then
        ${COLOR}"缺少${APR_UTIL_FILE}文件！"${END}
        ${COLOR}"开始下载${APR_UTIL_FILE}源码包......"${END}
        wget ${APR_UTIL_URL}${APR_UTIL_FILE} || { ${COLOR}"下载${APR_UTIL_FILE}源码包下载失败！"${END}; exit; }
    else
        ${COLOR}"${APR_UTIL_FILE}文件已准备好！"${END}
    fi
    if [ ! -e ${HTTPD_FILE} ];then
        ${COLOR}"缺少${HTTPD_FILE}文件！"${END}
        ${COLOR}"开始下载${HTTPD_FILE}源码包......"${END} 
        wget ${HTTPD_URL}${HTTPD_FILE} || { ${COLOR}"下载${HTTPD_FILE}源码包下载失败！"${END}; exit; }
    else
        ${COLOR}"${HTTPD_FILE}文件已准备好！"${END}
    fi
}

install_httpd(){
    [ -d ${INSTALL_DIR} ] && { ${COLOR}"Httpd已存在，安装失败！"${END};exit; }
    ${COLOR}"开始安装Httpd......"${END}
    ${COLOR}"开始安装Httpd依赖包，请稍等......"${END}
    if [ ${MAIN_NAME} == "openSUSE" ];then
        zypper install -y gcc pcre2-devel openssl-devel make libexpat-devel &> /dev/null
    elif [ ${MAIN_NAME} == "Ubuntu" -o ${MAIN_NAME} == "Debian" ];then
        apt update &> /dev/null;apt install -y gcc libpcre2-dev libssl-dev make libexpat1-dev
    else
        yum install -y gcc pcre2-devel openssl-devel make expat-devel &> /dev/null
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
    tar xf ${APR_FILE} && tar xf ${APR_UTIL_FILE} && tar xf ${HTTPD_FILE}
    APR_FILE_DIR=`echo ${APR_FILE}_| sed -nr 's/^(.*[0-9]).*/\1/p'`
    APR_UTIL_FILE_DIR=`echo ${APR_UTIL_FILE}_| sed -nr 's/^(.*[0-9]).*/\1/p'`
    HTTPD_FILE_DIR=`echo ${HTTPD_FILE}_| sed -nr 's/^(.*[0-9]).*/\1/p'`
    mv ${APR_FILE_DIR} ${HTTPD_FILE_DIR}/srclib/apr
    mv ${APR_UTIL_FILE_DIR} ${HTTPD_FILE_DIR}/srclib/apr-util
    cd ${HTTPD_FILE_DIR}
    ./configure --prefix=${INSTALL_DIR} --enable-so --enable-ssl --enable-cgi --enable-rewrite --with-zlib --with-pcre --with-included-apr --enable-modules=most --enable-mpms-shared=all --with-mpm=${MPM}
    make -j $(nproc) && make install
    [ $? -eq 0 ] && $COLOR"Httpd编译安装成功！"$END ||  { $COLOR"Httpd编译安装失败,退出!"$END;exit; }
    if [ ${MAIN_NAME} == "openSUSE" ];then
        id apache &> /dev/null || { groupadd -r apache && useradd -s /sbin/nologin -r -g apache apache; ${COLOR}"成功创建apache用户!"${END}; }
    else
        id apache &> /dev/null || { useradd -s /sbin/nologin -r apache ; ${COLOR}"成功创建apache用户！"${END}; }
    fi
    sed -i 's/daemon/apache/' ${INSTALL_DIR}/conf/httpd.conf
    echo "PATH=${INSTALL_DIR}/bin:$PATH" > /etc/profile.d/httpd.sh
    . /etc/profile.d/httpd.sh
    if [ ${MAIN_NAME} == "Ubuntu" -o ${MAIN_NAME} == "Debian" ];then
        cat > /lib/systemd/system/httpd.service <<-EOF
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target
Documentation=man:httpd(8)
Documentation=man:apachectl(8)

[Service]
Type=forking
ExecStart=${INSTALL_DIR}/bin/apachectl start
ExecReload=${INSTALL_DIR}/bin/apachectl graceful
ExecStop=${INSTALL_DIR}/bin/apachectl stop
KillSignal=SIGCONT
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
    else
        cat > /usr/lib/systemd/system/httpd.service <<-EOF
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target
Documentation=man:httpd(8)
Documentation=man:apachectl(8)

[Service]
Type=forking
ExecStart=${INSTALL_DIR}/bin/apachectl start
ExecReload=${INSTALL_DIR}/bin/apachectl graceful
ExecStop=${INSTALL_DIR}/bin/apachectl stop
KillSignal=SIGCONT
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
    fi
    systemctl daemon-reload && systemctl enable --now httpd &> /dev/null
    systemctl is-active httpd &> /dev/null ||  { ${COLOR}"Httpd启动失败,退出!"${END} ; exit; }
    ${COLOR}"${FULL_NAME}操作系统，Httpd安装完成！"${END}
}

main(){
    check_file
    install_httpd
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
    ${COLOR}"此脚本不支持${FULL_NAME}操作系统！"${END}
fi
