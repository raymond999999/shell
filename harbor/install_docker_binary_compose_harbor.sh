#!/bin/bash
#
#**************************************************************************************************
#Author:        Raymond
#QQ:            88563128
#Date:          2021-12-15
#FileName:      install_docker_binary_compose_harbor.sh
#URL:           raymond.blog.csdn.net
#Description:   install_docker_binary_compose_harbor for CentOS 7/8 & Ubuntu 18.04/20.04 & Rocky 8
#Copyright (C): 2021 All rights reserved
#**************************************************************************************************
SRC_DIR=/usr/local/src
COLOR="echo -e \\033[01;31m"
END='\033[0m'

URL='https://download.docker.com/linux/static/stable/x86_64/'
DOCKER_FILE=docker-20.10.9.tgz

#docker-compose下载地址:https://github.com/docker/compose/releases/download/1.29.2/docker-compose-Linux-x86_64
DOCKER_COMPOSE_FILE=docker-compose-linux-x86_64

#harbor下载地址:https://github.com/goharbor/harbor/releases/download/v2.3.5/harbor-offline-installer-v2.3.5.tgz
HARBOR_FILE=harbor-offline-installer-v
HARBOR_VERSION=2.3.5
TAR=.tgz
HARBOR_INSTALL_DIR=/apps
NET_NAME=`ip addr |awk -F"[: ]" '/^2: e.*/{print $3}'`
IP=`ip addr show ${NET_NAME}| awk -F" +|/" '/global/{print $3}'`
HARBOR_ADMIN_PASSWORD=123456

os(){
    OS_ID=`sed -rn '/^NAME=/s@.*="([[:alpha:]]+).*"$@\1@p' /etc/os-release`
    OS_RELEASE_VERSION=`sed -rn '/^VERSION_ID=/s@.*="?([0-9]+)\.?.*"?@\1@p' /etc/os-release`
}

check_file (){
    cd ${SRC_DIR}
    if [ ${OS_ID} == "CentOS" -o ${OS_ID} == "Rocky" ] &> /dev/null;then
        rpm -q wget &> /dev/null || yum -y install wget &> /dev/null
    fi
    if [ ! -e ${DOCKER_FILE} ];then
        ${COLOR}"缺少${DOCKER_FILE}文件,如果是离线包,请把文件放到${SRC_DIR}目录下"${END}
        ${COLOR}'开始下载DOCKER二进制源码包'${END}
        wget ${URL}${DOCKER_FILE} || { ${COLOR}"DOCKER二进制安装包下载失败"${END}; exit; }
    elif [ ! -e ${DOCKER_COMPOSE_FILE} ];then
        ${COLOR}"缺少${DOCKER_COMPOSE_FILE}文件,请把文件放到${SRC_DIR}目录下"${END}
        exit
    elif [ ! -e ${HARBOR_FILE}${HARBOR_VERSION}${TAR} ];then
        ${COLOR}"缺少${HARBOR_FILE}${HARBOR_VERSION}${TAR}文件,请把文件放到${SRC_DIR}目录下"${END}
        exit
    else
        ${COLOR}"相关文件已准备好"${END}
    fi
}

install_docker(){ 
    tar xf ${DOCKER_FILE} 
    mv docker/* /usr/bin/
    cat > /lib/systemd/system/docker.service <<-EOF
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service
Wants=network-online.target

[Service]
Type=notify
# the default is not to use systemd for cgroups because the delegate issues still
# exists and systemd currently does not support the cgroup feature set required
# for containers run by docker
ExecStart=/usr/bin/dockerd -H unix://var/run/docker.sock
ExecReload=/bin/kill -s HUP \$MAINPID
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
# Uncomment TasksMax if your systemd version supports it.
# Only systemd 226 and above support this version.
#TasksMax=infinity
TimeoutStartSec=0
# set delegate yes so that systemd does not reset the cgroups of docker containers
Delegate=yes
# kill only the docker process, not all processes in the cgroup
KillMode=process
# restart the docker process if it exits prematurely
Restart=on-failure
StartLimitBurst=3
StartLimitInterval=60s

[Install]
WantedBy=multi-user.target
EOF
    mkdir -p /etc/docker
    tee /etc/docker/daemon.json <<-'EOF'
{
    "registry-mirrors": [
        "https://hzw5xiv7.mirror.aliyuncs.com",
        "https://docker.mirrors.ustc.edu.cn",
        "http://f1361db2.m.daocloud.io",
        "https://registry.docker-cn.com",
        "https://dockerhub.azk8s.cn",
        "https://reg-mirror.qiniu.com",
        "https://hub-mirror.c.163.com",
        "https://mirror.ccs.tencentyun.com"
    ]
}
EOF
    echo 'alias rmi="docker images -qa|xargs docker rmi -f"' >> ~/.bashrc
    echo 'alias rmc="docker ps -qa|xargs docker rm -f"' >> ~/.bashrc
    systemctl daemon-reload
    systemctl enable --now docker &> /dev/null
    systemctl is-active docker &> /dev/null && ${COLOR}"Docker 服务启动成功"${END} || { ${COLOR}"Docker 启动失败"${END};exit; }
    docker version && ${COLOR}"Docker 安装成功"${END} || ${COLOR}"Docker 安装失败"${END}
}

install_docker_compose(){
    ${COLOR}"开始安装 Docker compose....."${END}
    sleep 1
    mv ${SRC_DIR}/${DOCKER_COMPOSE_FILE} /usr/bin/docker-compose
    chmod +x /usr/bin/docker-compose
    docker-compose --version &&  ${COLOR}"Docker Compose 安装完成"${END} || ${COLOR}"Docker compose 安装失败"${END}
}

install_harbor(){
    ${COLOR}"开始安装 Harbor....."${END}
    sleep 1
    [ -d ${HARBOR_INSTALL_DIR} ] || mkdir ${HARBOR_INSTALL_DIR}
    tar xf ${SRC_DIR}/${HARBOR_FILE}${HARBOR_VERSION}${TAR} -C ${HARBOR_INSTALL_DIR}/
    mv ${HARBOR_INSTALL_DIR}/harbor/harbor.yml.tmpl ${HARBOR_INSTALL_DIR}/harbor/harbor.yml
    sed -ri.bak -e 's/^(hostname:) .*/\1 '${IP}'/' -e 's/^(harbor_admin_password:) .*/\1 '${HARBOR_ADMIN_PASSWORD}'/' -e 's/^(https:)/#\1/' -e 's/  (port: 443)/#  \1/' -e 's@  (certificate: .*)@#  \1@' -e 's@  (private_key: .*)@#  \1@' ${HARBOR_INSTALL_DIR}/harbor/harbor.yml
    if [ ${OS_ID} == "CentOS" -o ${OS_ID} == "Rocky" ] &> /dev/null;then
        yum -y install python3 &> /dev/null || { ${COLOR}"安装软件包失败，请检查网络配置"${END}; exit; }
    else
        apt -y install python3 &> /dev/null || { ${COLOR}"安装软件包失败，请检查网络配置"${END}; exit; }
    fi
    ${HARBOR_INSTALL_DIR}/harbor/install.sh && ${COLOR}"Harbor 安装完成"${END} ||  ${COLOR}"Harbor 安装失败"${END}
    cat > /lib/systemd/system/harbor.service <<-EOF
[Unit]
Description=Harbor
After=docker.service systemd-networkd.service systemd-resolved.service
Requires=docker.service
Documentation=http://github.com/vmware/harbor

[Service]
Type=simple
Restart=on-failure
RestartSec=5
ExecStart=/usr/bin/docker-compose -f /apps/harbor/docker-compose.yml up
ExecStop=/usr/bin/docker-compose -f /apps/harbor/docker-compose.yml down

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload 
    systemctl enable harbor &>/dev/null && ${COLOR}"Harbor已配置为开机自动启动"${END}
}

set_swap_limit(){
    if [ ${OS_ID} == "Ubuntu" ];then
        ${COLOR}'设置Docker的"WARNING: No swap limit support"警告'${END}
        sed -ri '/^GRUB_CMDLINE_LINUX=/s@"$@ swapaccount=1"@' /etc/default/grub
        update-grub &> /dev/null
        ${COLOR}"10秒后，机器会自动重启"${END}
        sleep 10
        reboot
    fi
}

main(){
    os
    check_file
    [ -f /usr/bin/docker ] && ${COLOR}"Docker已安装"${END} || install_docker
    docker-compose --version &> /dev/null && ${COLOR}"Docker Compose已安装"${END} || install_docker_compose
    systemctl is-active harbor &> /dev/null && ${COLOR}"Harbor已安装"${END} || install_harbor
    grep -q "swapaccount=1" /etc/default/grub && ${COLOR}'"WARNING: No swap limit support"警告,已设置'${END} || set_swap_limit
}

main
