#!/bin/bash
#
#******************************************************************************************************************
#Author:        Raymond
#QQ:            88563128
#Date:          2024-02-15
#FileName:      install_containerd_binary.sh
#URL:           raymond.blog.csdn.net
#Description:   install_containerd_binary CentOS 7 & CentOS Stream 8/9 & Ubuntu 18.04/20.04/22.04 & Rocky 8/9
#Copyright (C): 2024 All rights reserved
#******************************************************************************************************************
SRC_DIR=/usr/local/src
COLOR="echo -e \\033[01;31m"
END='\033[0m'

#Containerd下载地址：“https://github.com/containerd/containerd/releases/download/v1.7.12/cri-containerd-cni-1.7.12-linux-amd64.tar.gz”，请提前下载。
CONTAINERD_FILE=cri-containerd-cni-1.7.12-linux-amd64.tar.gz

#Netdctl下载地址：“https://github.com/containerd/nerdctl/releases/download/v1.7.3/nerdctl-1.7.3-linux-amd64.tar.gz”，请提前下载。
NETDCTL_FILE=nerdctl-1.7.3-linux-amd64.tar.gz
#Buildkit下载地址：“https://github.com/moby/buildkit/releases/download/v0.12.5/buildkit-v0.12.5.linux-amd64.tar.gz”，请提前下载。
BUILDKIT_FILE=buildkit-v0.12.5.linux-amd64.tar.gz

os(){
    OS_ID=`sed -rn '/^NAME=/s@.*="([[:alpha:]]+).*"$@\1@p' /etc/os-release`
    OS_RELEASE_VERSION=`sed -rn '/^VERSION_ID=/s@.*="?([0-9]+)\.?.*"?@\1@p' /etc/os-release`
}

check_file (){
    cd ${SRC_DIR}
    if [ ! -e ${CONTAINERD_FILE} ];then
        ${COLOR}"缺少${CONTAINERD_FILE}文件,请把文件放到${SRC_DIR}目录下"${END}
        exit
    elif [ ! -e ${NETDCTL_FILE} ];then
        ${COLOR}"缺少${NETDCTL_FILE}文件,请把文件放到${SRC_DIR}目录下"${END}
        exit
    elif [ ! -e ${BUILDKIT_FILE} ];then
        ${COLOR}"缺少${BUILDKIT_FILE}文件,请把文件放到${SRC_DIR}目录下"${END}
        exit
    else
        ${COLOR}"相关文件已准备好"${END}
    fi
}

install_containerd(){ 
    [ -f /usr/local/bin/containerd ] && { ${COLOR}"Containerd已存在，安装失败"${END};exit; }
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

    ${COLOR}"开始安装Containerd..."${END}
    tar xf ${CONTAINERD_FILE} -C /

    mkdir -p /etc/containerd
    containerd config default | tee /etc/containerd/config.toml &> /dev/null 
    sed -ri -e 's/(.*SystemdCgroup = ).*/\1true/' -e "s#registry.k8s.io#registry.aliyuncs.com/google_containers#g" /etc/containerd/config.toml
    sed -i '/.*registry.mirrors.*/a\        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]\n          endpoint = ["https://registry.docker-cn.com" ,"https://hub-mirror.c.163.com" ,"https://docker.mirrors.ustc.edu.cn"]' /etc/containerd/config.toml
    cat > /etc/crictl.yaml <<-EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF
    systemctl daemon-reload && systemctl enable --now containerd &> /dev/null
    systemctl is-active containerd &> /dev/null && ${COLOR}"Containerd 服务启动成功"${END} || { ${COLOR}"Containerd 启动失败"${END};exit; }
    ctr version &&  ${COLOR}"Containerd 安装成功"${END} || ${COLOR}"Containerd 安装失败"${END}
}

set_alias(){
    echo 'alias rmi="nerdctl images -qa|xargs nerdctl rmi -f"' >> ~/.bashrc
    echo 'alias rmc="nerdctl ps -qa|xargs nerdctl rm -f"' >> ~/.bashrc
}

install_netdctl_buildkit(){
    ${COLOR}"开始安装Netdctl..."${END}
    tar xf ${NETDCTL_FILE} -C /usr/local/bin/
    mkdir -p /etc/nerdctl/
    cat > /etc/nerdctl/nerdctl.toml <<EOF
namespace      = "default"
insecure_registry = true
EOF

    ${COLOR}"开始安装Buildkit..."${END}
    tar xf ${BUILDKIT_FILE} -C /usr/local/
    cat > /usr/lib/systemd/system/buildkit.socket <<-EOF
[Unit]
Description=BuildKit
Documentation=https://github.com/moby/buildkit

[Socket]
ListenStream=%t/buildkit/buildkitd.sock
SocketMode=0660

[Install]
WantedBy=sockets.target
EOF
    cat > /usr/lib/systemd/system/buildkit.service <<-EOF
[Unit]
Description=BuildKit
Requires=buildkit.socket
After=buildkit.socket
Documentation=https://github.com/moby/buildkit

[Service]
Type=notify
ExecStart=/usr/local/bin/buildkitd --addr fd://

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload && systemctl enable --now buildkit &> /dev/null
    systemctl is-active buildkit &> /dev/null && ${COLOR}"Buildkit 服务启动成功"${END} || { ${COLOR}"Buildkit 启动失败"${END};exit; }
    buildctl --version &&  ${COLOR}"Buildkit 安装成功"${END} || ${COLOR}"Buildkit 安装失败"${END}
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
    install_containerd
    set_alias
    install_netdctl_buildkit
    set_swap_limit
}

main
