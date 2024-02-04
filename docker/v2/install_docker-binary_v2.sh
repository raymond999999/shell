#!/bin/bash
#
#*************************************************************************************************************
#Author:        Raymond
#QQ:            88563128
#Date:          2024-01-17
#FileName:      install_docker-binary_v2.sh
#URL:           raymond.blog.csdn.net
#Description:   install_docker-binary for CentOS 7 & CentOS Stream 8/9 & Ubuntu 18.04/20.04/22.04 & Rocky 8/9
#Copyright (C): 2024 All rights reserved
#*************************************************************************************************************
SRC_DIR=/usr/local/src
COLOR="echo -e \\033[01;31m"
END='\033[0m'
URL='https://mirrors.aliyun.com/docker-ce/linux/static/stable/x86_64/'
DOCKER_FILE=docker-24.0.7.tgz

os(){
    OS_ID=`sed -rn '/^NAME=/s@.*="([[:alpha:]]+).*"$@\1@p' /etc/os-release`
    OS_RELEASE_VERSION=`sed -rn '/^VERSION_ID=/s@.*="?([0-9]+)\.?.*"?@\1@p' /etc/os-release`
}

check_file (){
    cd ${SRC_DIR}
    if [ ${OS_ID} == "CentOS" -o ${OS_ID} == "Rocky" ] &> /dev/null;then
        rpm -q wget &> /dev/null || { ${COLOR}"安装wget工具，请稍等..."${END};yum -y install wget &> /dev/null; }
    fi
    if [ ! -e ${DOCKER_FILE} ];then
        ${COLOR}"缺少${DOCKER_FILE}文件,如果是离线包,请把文件放到${SRC_DIR}目录下"${END}
        ${COLOR}'开始下载Docker二进制安装包'${END}
        wget ${URL}${DOCKER_FILE} || { ${COLOR}"Docker二进制安装包下载失败"${END}; exit; } 
    else
        ${COLOR}"相关文件已准备好"${END}
    fi
}

install(){ 
    [ -f /usr/bin/docker ] && { ${COLOR}"Docker已存在，安装失败"${END};exit; }
    ${COLOR}"开始安装Docker，请稍等..."${END}
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
    cat > /etc/docker/daemon.json <<-EOF
{
    "registry-mirrors": [
        "https://registry.docker-cn.com",
        "https://hub-mirror.c.163.com",
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
    echo 'alias rmi="docker images -qa|xargs docker rmi -f"' >> ~/.bashrc
    echo 'alias rmc="docker ps -qa|xargs docker rm -f"' >> ~/.bashrc
    systemctl daemon-reload
    systemctl enable --now docker &> /dev/null
    systemctl is-active docker &> /dev/null && ${COLOR}"Docker 服务启动成功"${END} || { ${COLOR}"Docker 启动失败"${END};exit; }
    docker version && ${COLOR}"Docker 安装成功"${END} || ${COLOR}"Docker 安装失败"${END}
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
    install
    set_swap_limit
}

main
