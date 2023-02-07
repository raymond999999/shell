#!/bin/bash
#
#**********************************************************************************************
#Author:        Raymond
#QQ:            88563128
#Date:          2022-04-22
#FileName:      install_containerd_binary.sh
#URL:           raymond.blog.csdn.net
#Description:   install_containerd_binary for centos 7/8 & ubuntu 18.04/20.04 & Rocky 8
#Copyright (C): 2021 All rights reserved
#*********************************************************************************************
SRC_DIR=/usr/local/src
COLOR="echo -e \\033[01;31m"
END='\033[0m'
URL='https://mirrors.cloud.tencent.com/docker-ce/linux/static/stable/x86_64/'
DOCKER_FILE=docker-20.10.14.tgz
HARBOR_DOMAIN=harbor.raymonds.cc
USERNAME=admin
PASSWORD=123456

os(){
    OS_ID=`sed -rn '/^NAME=/s@.*="([[:alpha:]]+).*"$@\1@p' /etc/os-release`
}

check_file (){
    cd ${SRC_DIR}
    if [ ${OS_ID} == "CentOS" -o ${OS_ID} == "Rocky" ] &> /dev/null;then
        rpm -q wget &> /dev/null || yum -y install wget &> /dev/null
    fi
    if [ ! -e ${DOCKER_FILE} ];then
        ${COLOR}"缺少${DOCKER_FILE}文件,如果是离线包,请把文件放到${SRC_DIR}目录下"${END}
        ${COLOR}'开始下载DOCKER二进制安装包'${END}
        wget ${URL}${DOCKER_FILE} || { ${COLOR}"DOCKER二进制安装包下载失败"${END}; exit; } 
    else
        ${COLOR}"相关文件已准备好"${END}
    fi
}

install(){ 
    [ -f /usr/bin/containerd ] && { ${COLOR}"Containerd已存在，安装失败"${END};exit; }
    ${COLOR}"开始安装Containerd..."${END}
    tar xf ${DOCKER_FILE} 
    mv docker/* /usr/bin/
    cat > /lib/systemd/system/containerd.service <<-EOF
# Copyright The containerd Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target local-fs.target

[Service]
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/bin/containerd

Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity
LimitNOFILE=infinity
# Comment TasksMax if your systemd version does not supports it.
# Only systemd 226 and above support this version.
TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
EOF
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
    check_file
    install
    set_alias
}

main
