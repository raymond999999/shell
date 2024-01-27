#!/bin/bash
#
#********************************************************************************************************
#Author:        Raymond
#QQ:            88563128
#Date:          2024-01-13
#FileName:      install_docker_v2.sh
#URL:           raymond.blog.csdn.net
#Description:   install_docker for CentOS 7 & CentOS Stream 8/9 & Ubuntu 18.04/20.04/22.04 & Rocky 8/9
#Copyright (C): 2024 All rights reserved
#********************************************************************************************************
COLOR="echo -e \\033[01;31m"
END='\033[0m'
DOCKER_VERSION=24.0.7
DOCKER_MAIN_VERSION=`echo ${DOCKER_VERSION} | awk -F'.' '{print $1}'`
URL='mirrors.aliyun.com'

os(){
    OS_ID=`sed -rn '/^NAME=/s@.*="([[:alpha:]]+).*"$@\1@p' /etc/os-release`
    OS_RELEASE_VERSION=`sed -rn '/^VERSION_ID=/s@.*="?([0-9]+)\.?.*"?@\1@p' /etc/os-release`
}

ubuntu_install_docker(){
    dpkg -s docker-ce &>/dev/null && ${COLOR}"Docker已安装，退出"${END} && exit
    ${COLOR}"开始安装Docker依赖包，请稍等..."${END}
    apt update &> /dev/null
    apt -y install apt-transport-https ca-certificates curl software-properties-common &> /dev/null
    curl -fsSL https://${URL}/docker-ce/linux/ubuntu/gpg | sudo apt-key add - &> /dev/null
    add-apt-repository -y "deb [arch=amd64] https://${URL}/docker-ce/linux/ubuntu  $(lsb_release -cs) stable" &> /dev/null 
    apt update &> /dev/null

    ${COLOR}"Docker有以下版本"${END}
    apt-cache madison docker-ce
    ${COLOR}"10秒后即将安装：Docker-"${DOCKER_VERSION}"版本......"${END}
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
    rpm -q docker-ce &> /dev/null && ${COLOR}"Docker已安装，退出"${END} && exit
	
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
        "http://hub-mirror.c.163.com",
        "https://docker.mirrors.ustc.edu.cn"
    ],
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
    systemctl enable --now docker &> /dev/null
    systemctl is-active docker &> /dev/null && ${COLOR}"Docker 服务启动成功"${END} || { ${COLOR}"Docker 启动失败"${END};exit; }
    docker version &&  ${COLOR}"Docker 安装成功"${END} || ${COLOR}"Docker 安装失败"${END}
}

set_alias(){
    echo 'alias rmi="docker images -qa|xargs docker rmi -f"' >> ~/.bashrc
    echo 'alias rmc="docker ps -qa|xargs docker rm -f"' >> ~/.bashrc
}

set_swap_limit(){
    if [ ${OS_RELEASE_VERSION} == "18" -o ${OS_RELEASE_VERSION} == "20" ];then
        grep -q "swapaccount=1" /etc/default/grub && { ${COLOR}'"WARNING: No swap limit support"警告,已设置'${END};exit; }
        ${COLOR}'设置Docker的"WARNING: No swap limit support"警告'${END}
        sed -ri '/^GRUB_CMDLINE_LINUX=/s@"$@ swapaccount=1"@' /etc/default/grub
        update-grub &> /dev/null
        ${COLOR}"10秒后，机器会自动重启!"${END}
        sleep 10
        reboot
    fi
}

main(){
    os
    if [ ${OS_ID} == "CentOS" -o ${OS_ID} == "Rocky" ] &> /dev/null;then
        centos_install_docker
    else
        ubuntu_install_docker
    fi
    mirror_accelerator
    set_alias
    set_swap_limit
}

main
