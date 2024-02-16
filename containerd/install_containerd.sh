#!/bin/bash
#
#*************************************************************************************************************
#Author:        Raymond
#QQ:            88563128
#Date:          2024-02-15
#FileName:      install_containerd.sh
#URL:           raymond.blog.csdn.net
#Description:   install_containerd for CentOS 7 & CentOS Stream 8/9 & Ubuntu 18.04/20.04/22.04 & Rocky 8/9
#Copyright (C): 2024 All rights reserved
#*************************************************************************************************************
SRC_DIR=/usr/local/src
COLOR="echo -e \\033[01;31m"
END='\033[0m'
CONTAINERD_VERSION=1.6.28
URL='mirrors.aliyun.com'

#crictl下载地址：“https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.29.0/crictl-v1.29.0-linux-amd64.tar.gz”，请提前下载。
CRICTL_FILE=crictl-v1.29.0-linux-amd64.tar.gz
#CNIl下载地址：“https://github.com/containernetworking/plugins/releases/download/v1.4.0/cni-plugins-linux-amd64-v1.4.0.tgz”，请提前下载。
CNI_FILE=cni-plugins-linux-amd64-v1.4.0.tgz
#Netdctl下载地址：“https://github.com/containerd/nerdctl/releases/download/v1.7.3/nerdctl-1.7.3-linux-amd64.tar.gz”，请提前下载。
NETDCTL_FILE=nerdctl-1.7.3-linux-amd64.tar.gz
#Buildkit下载地址：“https://github.com/moby/buildkit/releases/download/v0.12.5/buildkit-v0.12.5.linux-amd64.tar.gz”，请提前下载。
BUILDKIT_FILE=buildkit-v0.12.5.linux-amd64.tar.gz

os(){
    OS_ID=`sed -rn '/^NAME=/s@.*="([[:alpha:]]+).*"$@\1@p' /etc/os-release`
    OS_RELEASE_VERSION=`sed -rn '/^VERSION_ID=/s@.*="?([0-9]+)\.?.*"?@\1@p' /etc/os-release`
}

check_file(){
    cd ${SRC_DIR}
    if [ ! -e ${CRICTL_FILE} ];then
        ${COLOR}"缺少${CRICTL_FILE}文件,请把文件放到${SRC_DIR}目录下"${END}
        exit
    elif [ ! -e ${CNI_FILE} ];then
        ${COLOR}"缺少${CNI_FILE}文件,请把文件放到${SRC_DIR}目录下"${END}
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

set_kernel(){
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
}

ubuntu_install_docker(){
    dpkg -s containerd &>/dev/null && ${COLOR}"Containerd已安装，退出"${END} && exit
    ${COLOR}"开始安装Containerd依赖包，请稍等..."${END}
    apt update &> /dev/null
    apt -y install apt-transport-https ca-certificates curl software-properties-common &> /dev/null
    curl -fsSL https://${URL}/docker-ce/linux/ubuntu/gpg | sudo apt-key add - &> /dev/null
    add-apt-repository -y "deb [arch=amd64] https://${URL}/docker-ce/linux/ubuntu  $(lsb_release -cs) stable" &> /dev/null 
    apt update &> /dev/null

    ${COLOR}"Containerd有以下版本"${END}
    apt-cache madison containerd.io
    ${COLOR}"10秒后即将安装：Containerd-"${CONTAINERD_VERSION}"版本......"${END}
    ${COLOR}"如果想安装其它Containerd版本，请按Ctrl+c键退出，修改版本再执行"${END}
    sleep 10

    ${COLOR}"开始安装Containerd，请稍等..."${END}
    apt -y install containerd.io=${CONTAINERD_VERSION}-1 &> /dev/null || { ${COLOR}"apt源失败，请检查apt配置"${END};exit; }
}

centos_install_docker(){
    rpm -q containerd &> /dev/null && ${COLOR}"Containerd已安装，退出"${END} && exit
    ${COLOR}"开始安装Containerd依赖包，请稍等..."${END}
    yum -y install yum-utils &> /dev/null
    yum-config-manager --add-repo https://${URL}/docker-ce/linux/centos/docker-ce.repo &> /dev/null
    yum clean all &> /dev/null
	yum makecache &> /dev/null

    ${COLOR}"Containerd有以下版本"${END}
    yum list containerd.io --showduplicates
    ${COLOR}"10秒后即将安装：Containerd-"${CONTAINERD_VERSION}"版本......"${END}
    ${COLOR}"如果想安装其它Containerd版本，请按Ctrl+c键退出，修改版本再执行"${END}
    sleep 10

    ${COLOR}"开始安装Containerd，请稍等..."${END}
    yum -y install containerd.io-${CONTAINERD_VERSION} &> /dev/null || { ${COLOR}"yum源失败，请检查yum配置"${END};exit; }
}

config_containerd(){
    mkdir -p /etc/containerd
    containerd config default | tee /etc/containerd/config.toml &> /dev/null 
    sed -ri -e 's/(.*SystemdCgroup = ).*/\1true/' -e "s#registry.k8s.io#registry.aliyuncs.com/google_containers#g" /etc/containerd/config.toml
    sed -i '/.*registry.mirrors.*/a\        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]\n          endpoint = ["https://registry.docker-cn.com" ,"https://hub-mirror.c.163.com" ,"https://docker.mirrors.ustc.edu.cn"]' /etc/containerd/config.toml
}

set_alias(){
    echo 'alias rmi="nerdctl images -qa|xargs nerdctl rmi -f"' >> ~/.bashrc
    echo 'alias rmc="nerdctl ps -qa|xargs nerdctl rm -f"' >> ~/.bashrc
}

install_crictl_cni(){
    ${COLOR}"开始安装Crictl工具，请稍等..."${END}
    tar xf ${CRICTL_FILE} -C /usr/local/bin
    cat > /etc/crictl.yaml <<-EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF

    ${COLOR}"开始安装CNI插件，请稍等..."${END}
    mkdir -p /opt/cni/bin/
    tar xf ${CNI_FILE} -C /opt/cni/bin/
    mkdir -p /etc/cni/net.d/
    cat > /etc/cni/net.d/10-containerd-net.conflist <<EOF
{
  "cniVersion": "1.0.0",
  "name": "containerd-net",
  "plugins": [
    {
      "type": "bridge",
      "bridge": "cni0",
      "isGateway": true,
      "ipMasq": true,
      "promiscMode": true,
      "ipam": {
        "type": "host-local",
        "ranges": [
          [{
            "subnet": "10.88.0.0/16"
          }],
          [{
            "subnet": "2001:4860:4860::/64"
          }]
        ],
        "routes": [
          { "dst": "0.0.0.0/0" },
          { "dst": "::/0" }
        ]
      }
    },
    {
      "type": "portmap",
      "capabilities": {"portMappings": true}
    }
  ]
}
EOF

    systemctl daemon-reload && systemctl enable --now containerd &> /dev/null
    systemctl restart containerd
    systemctl is-active containerd &> /dev/null && ${COLOR}"Containerd 服务启动成功"${END} || { ${COLOR}"Containerd 启动失败"${END};exit; }
    ctr version &&  ${COLOR}"Containerd 安装成功"${END} || ${COLOR}"Containerd 安装失败"${END}    
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
        ${COLOR}"10秒后，机器会自动重启!"${END}
        sleep 10
        reboot
    fi
}

main(){
    os
    check_file
    set_kernel
    if [ ${OS_ID} == "CentOS" -o ${OS_ID} == "Rocky" ] &> /dev/null;then
        centos_install_docker
    else
        ubuntu_install_docker
    fi
    config_containerd
    set_alias
    install_crictl_cni
    install_netdctl_buildkit
    set_swap_limit
}

main
