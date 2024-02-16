#!/bin/bash
#
#******************************************************************************************************************
#Author:        Raymond
#QQ:            88563128
#Date:          2024-01-26
#FileName:      install_harbor_http_v2_2.sh
#URL:           raymond.blog.csdn.net
#Description:   install_harbor_http for CentOS 7 & CentOS Stream 8/9 & Ubuntu 18.04/20.04/22.04 & Rocky 8/9
#Copyright (C): 2024 All rights reserved
#******************************************************************************************************************
SRC_DIR=/usr/local/src
COLOR="echo -e \\033[01;31m"
END='\033[0m'

DOCKER_VERSION=24.0.7
DOCKER_MAIN_VERSION=`echo ${DOCKER_VERSION} | awk -F'.' '{print $1}'`
URL='mirrors.aliyun.com'

# Docker Compose下载地址：“https://github.com/docker/compose/releases/download/v2.23.3/docker-compose-linux-x86_64”，请提前下载。
DOCKER_COMPOSE_FILE=docker-compose-linux-x86_64

# Harbor下载地址：“https://github.com/goharbor/harbor/releases/download/v2.10.0/harbor-offline-installer-v2.10.0.tgz”，请提前下载。
HARBOR_FILE=harbor-offline-installer-v
HARBOR_VERSION=2.10.0
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
    if [ ! -e ${DOCKER_COMPOSE_FILE} ];then
        ${COLOR}"缺少${DOCKER_COMPOSE_FILE}文件,请把文件放到${SRC_DIR}目录下"${END}
        exit
    elif [ ! -e ${HARBOR_FILE}${HARBOR_VERSION}${TAR} ];then
        ${COLOR}"缺少${HARBOR_FILE}${HARBOR_VERSION}${TAR}文件,请把文件放到${SRC_DIR}目录下"${END}
        exit
    else
        ${COLOR}"相关文件已准备好"${END}
    fi
}

ubuntu_install_docker(){
    ${COLOR}"开始安装Docker依赖包，请稍等..."${END}
    apt update &> /dev/null
    apt -y install apt-transport-https ca-certificates curl software-properties-common &> /dev/null
    curl -fsSL https://${URL}/docker-ce/linux/ubuntu/gpg | sudo apt-key add - &> /dev/null
    add-apt-repository -y "deb [arch=amd64] https://${URL}/docker-ce/linux/ubuntu  $(lsb_release -cs) stable" &> /dev/null 
    apt update &> /dev/null

    ${COLOR}"Docker有以下版本"${END}
    apt-cache madison docker-ce
    ${COLOR}"10秒后即将安装:Docker-"${DOCKER_VERSION}"版本......"${END}
    ${COLOR}"如果想安装其它Docker版本，请按Ctrl+c键退出，修改版本再执行"${END}
    sleep 10

    ${COLOR}"开始安装Docker，请稍等..."${END}
    if [ ${DOCKER_MAIN_VERSION} == "18" -o ${DOCKER_MAIN_VERSION} == "19" -o ${DOCKER_MAIN_VERSION} == "20" ];then
        apt -y install docker-ce=5:${DOCKER_VERSION}~3-0~ubuntu-$(lsb_release -cs) docker-ce-cli=5:${DOCKER_VERSION}~3-0~ubuntu-$(lsb_release -cs) &> /dev/null || { ${COLOR}"apt源失败，请检查apt配置"${END};exit; }
    else
        apt -y install docker-ce=5:${DOCKER_VERSION}-1~ubuntu.$(lsb_release -rs)~$(lsb_release -cs) docker-ce-cli=5:${DOCKER_VERSION}-1~ubuntu.$(lsb_release -rs)~$(lsb_release -cs) &> /dev/null || { ${COLOR}"apt源失败，请检查apt配置"${END};exit; }
    fi
}

centos_install_docker(){
    ${COLOR}"开始安装Docker依赖包，请稍等..."${END}
    yum -y install yum-utils &> /dev/null
    yum-config-manager --add-repo https://${URL}/docker-ce/linux/centos/docker-ce.repo &> /dev/null
    yum clean all &> /dev/null
	yum makecache &> /dev/null

    ${COLOR}"Docker有以下版本"${END}
    yum list docker-ce.x86_64 --showduplicates
    ${COLOR}"10秒后即将安装:Docker-"${DOCKER_VERSION}"版本......"${END}
    ${COLOR}"如果想安装其它Docker版本，请按Ctrl+c键退出，修改版本再执行"${END}
    sleep 10

    ${COLOR}"开始安装Docker，请稍等..."${END}
    yum -y install docker-ce-${DOCKER_VERSION} docker-ce-cli-${DOCKER_VERSION} &> /dev/null || { ${COLOR}"yum源失败，请检查yum配置"${END};exit; }
}

mirror_accelerator(){
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json <<-EOF
{
    "registry-mirrors": [
        "https://registry.docker-cn.com",
        "https://hub-mirror.c.163.com",
        "https://docker.mirrors.ustc.edu.cn"
    ],
    "insecure-registries": ["${IP}"],
    "data-root": "/data/docker",
    "exec-opts": ["native.cgroupdriver=systemd"],
    "max-concurrent-downloads": 10,
    "max-concurrent-uploads": 5,
    "log-opts": {
        "max-size": "300m",
        "max-file": "2"  
    },
    "live-restore": true
}
EOF
    systemctl daemon-reload
    systemctl enable --now docker
    systemctl is-active docker &> /dev/null && ${COLOR}"Docker 服务启动成功"${END} || { ${COLOR}"Docker 启动失败"${END};exit; }
    docker version &&  ${COLOR}"Docker 安装成功"${END} || ${COLOR}"Docker 安装失败"${END}
}

set_alias(){
    echo 'alias rmi="docker images -qa|xargs docker rmi -f"' >> ~/.bashrc
    echo 'alias rmc="docker ps -qa|xargs docker rm -f"' >> ~/.bashrc
}

install_docker_compose(){
    ${COLOR}"开始安装Docker Compose，请稍等..."${END}
    mv ${SRC_DIR}/${DOCKER_COMPOSE_FILE} /usr/bin/docker-compose
    chmod +x /usr/bin/docker-compose
    docker-compose --version &&  ${COLOR}"Docker Compose 安装完成"${END} || ${COLOR}"Docker compose 安装失败"${END}
}

install_harbor(){
    ${COLOR}"开始安装Harbor，请稍等..."${END}
    [ -d ${HARBOR_INSTALL_DIR} ] || mkdir ${HARBOR_INSTALL_DIR}
    tar xf ${SRC_DIR}/${HARBOR_FILE}${HARBOR_VERSION}${TAR} -C ${HARBOR_INSTALL_DIR}/
    mv ${HARBOR_INSTALL_DIR}/harbor/harbor.yml.tmpl ${HARBOR_INSTALL_DIR}/harbor/harbor.yml
    sed -ri.bak -e 's/^(hostname:) .*/\1 '${IP}'/' -e 's/^(https:)/#\1/' -e 's/  (port: 443)/#  \1/' -e 's@  (certificate: .*)@#  \1@' -e 's@  (private_key: .*)@#  \1@' -e 's/^(harbor_admin_password:) .*/\1 '${HARBOR_ADMIN_PASSWORD}'/' ${HARBOR_INSTALL_DIR}/harbor/harbor.yml
    if [ ${OS_ID} == "CentOS" -o ${OS_ID} == "Rocky" ] &> /dev/null;then
        rpm -q python3 &> /dev/null || { ${COLOR}"安装python3，请稍等..."${END};yum -y install python3 &> /dev/null; }
    else
        dpkg -s python3 &>/dev/null || { ${COLOR}"安装python3，请稍等..."${END};apt -y install python3 &> /dev/null; }
    fi
    ${HARBOR_INSTALL_DIR}/harbor/install.sh --with-trivy && ${COLOR}"Harbor 安装完成"${END} ||  ${COLOR}"Harbor 安装失败"${END}
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
ExecStart=/usr/bin/docker-compose -f ${HARBOR_INSTALL_DIR}/harbor/docker-compose.yml up
ExecStop=/usr/bin/docker-compose -f ${HARBOR_INSTALL_DIR}/harbor/docker-compose.yml down

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload 
    systemctl enable harbor &>/dev/null && ${COLOR}"Harbor已配置为开机自动启动"${END}
}

set_swap_limit(){
    if [ ${OS_RELEASE_VERSION} == "18" -o ${OS_RELEASE_VERSION} == "20" ];then
        grep -q "swapaccount=1" /etc/default/grub && { ${COLOR}'"WARNING: No swap limit support"警告,已设置'${END};exit; }
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
    if [ ${OS_ID} == "CentOS" -o ${OS_ID} == "Rocky" ] &> /dev/null;then
        rpm -q docker-ce &> /dev/null && ${COLOR}"Docker已安装"${END} || centos_install_docker
    else
        dpkg -s docker-ce &>/dev/null && ${COLOR}"Docker已安装"${END} || ubuntu_install_docker
    fi
    [ -f /etc/docker/daemon.json ] &>/dev/null && ${COLOR}"Docker镜像加速器已设置"${END} || mirror_accelerator
    grep -Eqoi "(.*rmi=|.*rmc=)" ~/.bashrc && ${COLOR}"Docker别名已设置"${END} || set_alias
    [ -f /usr/bin/docker-compose ] && ${COLOR}"Docker Compose已安装"${END} || install_docker_compose
    systemctl is-active harbor &> /dev/null && ${COLOR}"Harbor已安装"${END} || install_harbor
    set_swap_limit
}

main
