#!/bin/bash
#
#**********************************************************************************************
#Author:        Raymond
#QQ:            88563128
#Date:          2022-04-22
#FileName:      install_containerd.sh
#URL:           raymond.blog.csdn.net
#Description:   install_containerd for centos 7/8 & ubuntu 18.04/20.04 Rocky 8
#Copyright (C): 2021 All rights reserved
#*********************************************************************************************
COLOR="echo -e \\033[01;31m"
END='\033[0m'
DOCKER_VERSION=20.10.14
URL='mirrors.cloud.tencent.com'

os(){
    OS_ID=`sed -rn '/^NAME=/s@.*="([[:alpha:]]+).*"$@\1@p' /etc/os-release`
}

ubuntu_install_docker(){
    dpkg -s docker-ce &>/dev/null && ${COLOR}"Docker已安装，退出"${END} && exit
    ${COLOR}"开始安装DOCKER依赖包"${END}
    apt update &> /dev/null
    apt -y install apt-transport-https ca-certificates curl software-properties-common &> /dev/null
    curl -fsSL https://${URL}/docker-ce/linux/ubuntu/gpg | sudo apt-key add - &> /dev/null
    add-apt-repository  "deb [arch=amd64] https://${URL}/docker-ce/linux/ubuntu  $(lsb_release -cs) stable" &> /dev/null
    apt update &> /dev/null

    ${COLOR}"Docker有以下版本"${END}
    apt-cache madison docker-ce
    ${COLOR}"10秒后即将安装:Docker-"${DOCKER_VERSION}"版本......"${END}
    ${COLOR}"如果想安装其它Docker版本，请按Ctrl+c键退出，修改版本再执行"${END}
    sleep 10

    ${COLOR}"开始安装DOCKER"${END}
    apt -y install docker-ce=5:${DOCKER_VERSION}~3-0~ubuntu-$(lsb_release -cs) docker-ce-cli=5:${DOCKER_VERSION}~3-0~ubuntu-$(lsb_release -cs) &> /dev/null || { ${COLOR}"apt源失败，请检查apt配置"${END};exit; }
}

centos_install_docker(){
    rpm -q docker-ce &> /dev/null && ${COLOR}"Docker已安装，退出"${END} && exit

    ${COLOR}"开始安装DOCKER依赖包"${END}
    yum -y install yum-utils &> /dev/null
    yum-config-manager --add-repo https://${URL}/docker-ce/linux/centos/docker-ce.repo &> /dev/null
    sed -i 's+download.docker.com+'''${URL}'''/docker-ce+' /etc/yum.repos.d/docker-ce.repo
    yum clean all &> /dev/null
    yum makecache &> /dev/null

    ${COLOR}"Docker有以下版本"${END}
    yum list docker-ce.x86_64 --showduplicates
    ${COLOR}"10秒后即将安装:Docker-"${DOCKER_VERSION}"版本......"${END}
    ${COLOR}"如果想安装其它Docker版本，请按Ctrl+c键退出，修改版本再执行"${END}
    sleep 10

    ${COLOR}"开始安装DOCKER"${END}
    yum -y install docker-ce-${DOCKER_VERSION} docker-ce-cli-${DOCKER_VERSION} &> /dev/null || { ${COLOR}"yum源失败，请检查yum配置"${END};exit; }
}

config_containerd(){
    cat > /etc/modules-load.d/containerd.conf <<-EOF
overlay
br_netfilter
EOF
    modprobe -- overlay
    modprobe -- br_netfilter

    cat > /etc/sysctl.d/99-kubernetes-cri.conf <<-EOF
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
    sysctl --system &> /dev/null

    mkdir -p /etc/containerd
    containerd config default | tee /etc/containerd/config.toml &> /dev/null 
    sed -ri 's/(.*SystemdCgroup = ).*/\1true/' /etc/containerd/config.toml
    sed -ri 's@(.*sandbox_image = ).*@\1\"registry.aliyuncs.com/google_containers/pause:3.6\"@' /etc/containerd/config.toml
    sed -i '/.*registry.mirrors.*/a\        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]\n          endpoint = ["https://registry.docker-cn.com" ,"http://hub-mirror.c.163.com" ,"https://docker.mirrors.ustc.edu.cn"]' /etc/containerd/config.toml
    systemctl daemon-reload && systemctl enable --now containerd &> /dev/null
    cat > /etc/crictl.yaml <<-EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF
    systemctl is-active containerd &> /dev/null && ${COLOR}"Containerd 服务启动成功"${END} || { ${COLOR}"Containerd 启动失败"${END};exit; }
    ctr version &&  ${COLOR}"Containerd 安装成功"${END} || ${COLOR}"Containerd 安装失败"${END}
}

set_alias(){
    echo 'alias rmi="ctr images list -q|xargs ctr images rm"' >> ~/.bashrc
}

main(){
    os
    if [ ${OS_ID} == "CentOS" -o ${OS_ID} == "Rocky" ] &> /dev/null;then
        centos_install_docker
    else
        ubuntu_install_docker
    fi
    config_containerd
    set_alias
}

main
