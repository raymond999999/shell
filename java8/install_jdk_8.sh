#!/bin/bash
#
#**********************************************************************************************
#Author:        Raymond
#QQ:            88563128
#Date:          2022-04-05
#FileName:      install_jdk.sh
#URL:           raymond.blog.csdn.net
#Description:   The test script
#Copyright (C): 2022 All rights reserved
#*********************************************************************************************
SRC_DIR=/usr/local/src
COLOR="echo -e \\033[01;31m"
END='\033[0m'

#下载地址:https://www.oracle.com/java/technologies/downloads/#java8
JDK_FILE="jdk-8u321-linux-x64.tar.gz"
INSTALL_DIR=/usr/local

check_file (){
    cd ${SRC_DIR}
    if [ ! -e ${JDK_FILE} ];then
        ${COLOR}"缺少${JDK_FILE}文件"${END}
        exit
    else
        ${COLOR}"相关文件已准备好"${END}
    fi
}

install_jdk(){
    [ -d ${INSTALL_DIR}/jdk ] && { ${COLOR}"JDK已存在，安装失败"${END};exit; }
    [  -d ${INSTALL_DIR} ] || mkdir -p ${INSTALL_DIR} &> /dev/null
    cd ${SRC_DIR}
    tar xf ${JDK_FILE} -C ${INSTALL_DIR}
    ln -s ${INSTALL_DIR}/jdk1.8.* ${INSTALL_DIR}/jdk
    cat >  /etc/profile.d/jdk.sh <<-EOF
export JAVA_HOME=${INSTALL_DIR}/jdk
export JRE_HOME=\$JAVA_HOME/jre
export CLASSPATH=\$JAVA_HOME/lib/:\$JRE_HOME/lib/
export PATH=\$PATH:\$JAVA_HOME/bin
EOF
    .  /etc/profile.d/jdk.sh
    java -version && ${COLOR}"JDK 安装完成"${END} || { ${COLOR}"JDK 安装失败"${END} ; exit; }
}

main(){
    check_file
    install_jdk
}

main
