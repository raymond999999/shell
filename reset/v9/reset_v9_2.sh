#!/bin/bash
#
#**********************************************************************************
#Author:        Raymond
#QQ:            88563128
#Date:          2024-11-23
#FileName:      reset_v9_2.sh
#MIRROR:        raymond.blog.csdn.net
#Description:   The reset linux system initialization script supports 
#               “Rocky Linux 8 and 9, Almalinux 8 and 9, CentOS 7, 
#               CentOS Stream 8 and 9, Ubuntu 18.04, 20.04, 22.04 and 24.04, 
#               Debian 12“ operating systems.
#Copyright (C): 2024 All rights reserved
#**********************************************************************************
COLOR="echo -e \\033[01;31m"
END='\033[0m'

os(){
    OS_ID=`sed -rn '/^NAME=/s@.*="([[:alpha:]]+).*"$@\1@p' /etc/os-release`
    OS_NAME=`sed -rn '/^NAME=/s@.*="([[:alpha:]]+) (.*)"$@\2@p' /etc/os-release`
    OS_RELEASE=`sed -rn '/^VERSION_ID=/s@.*="?([0-9.]+)"?@\1@p' /etc/os-release`
    OS_RELEASE_VERSION=`sed -rn '/^VERSION_ID=/s@.*="?([0-9]+)\.?.*"?@\1@p' /etc/os-release`
}

set_rocky_almalinux_centos_eth(){
    if [ ${OS_RELEASE_VERSION} == "7" -o ${OS_RELEASE_VERSION} == "8" ];then
        ETHNAME=`ip addr | awk -F"[ :]" '/^2/{print $3}'`
        if grep -Eqi "(net\.ifnames|biosdevname)" /etc/default/grub;then
            ${COLOR}"${OS_ID} ${OS_RELEASE} 网卡名配置文件已修改,不用修改!"${END}
        else
            sed -ri.bak '/^GRUB_CMDLINE_LINUX=/s@"$@ net.ifnames=0 biosdevname=0"@' /etc/default/grub
            grub2-mkconfig -o /boot/grub2/grub.cfg >& /dev/null

            mv /etc/sysconfig/network-scripts/ifcfg-${ETHNAME} /etc/sysconfig/network-scripts/ifcfg-eth0
            ${COLOR}"${OS_ID} ${OS_RELEASE} 网卡名已修改成功，10秒后，机器会自动重启!"${END}
            sleep 10 && shutdown -r now
        fi   
    else
        ${COLOR}"${OS_ID} ${OS_RELEASE} 不能修改网卡名!"${END} 
    fi
}

set_ubuntu_debian_eth(){
    if grep -Eqi "(net\.ifnames|biosdevname)" /etc/default/grub;then
        ${COLOR}"${OS_ID} ${OS_RELEASE} 网卡名配置文件已修改,不用修改!"${END}
    else
        sed -ri.bak '/^GRUB_CMDLINE_LINUX=/s@"$@net.ifnames=0 biosdevname=0"@' /etc/default/grub
        grub-mkconfig -o /boot/grub/grub.cfg >& /dev/null
        ${COLOR}"${OS_ID} ${OS_RELEASE} 网卡名已修改成功,请重新启动系统后才能生效!"${END}
    fi
}

set_eth(){
    if [ ${OS_ID} == "Rocky" -o ${OS_ID} == "AlmaLinux" -o ${OS_ID} == "CentOS" ];then
        set_rocky_almalinux_centos_eth
    else
        set_ubuntu_debian_eth
    fi
}

check_ip(){
    local IP=$1
    VALID_CHECK=$(echo ${IP}|awk -F. '$1<=255&&$2<=255&&$3<=255&&$4<=255{print "yes"}')
    if echo ${IP}|grep -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$" >/dev/null; then
        if [ ${VALID_CHECK} == "yes" ]; then
            echo "IP ${IP}  available!"
            return 0
        else
            echo "IP ${IP} not available!"
            return 1
        fi
    else
        echo "IP format error!"
        return 1
    fi
}

set_rocky_almalinux_centos_network(){
    ETHNAME=`ip addr | awk -F"[ :]" '/^2/{print $3}'`
    CONNECTION_NAME=`nmcli dev | awk 'NR==2{print $4,$5,$6}'`	
    while true; do
        read -p "请输入IP地址: " IP
        check_ip ${IP}
        [ $? -eq 0 ] && break
    done
    read -p "请输入子网掩码位数: " PREFIX
    while true; do
        read -p "请输入网关地址: " GATEWAY
        check_ip ${GATEWAY}
        [ $? -eq 0 ] && break
    done
    while true; do
        read -p "请输入主DNS地址（例如：阿里：223.5.5.5，腾讯：119.29.29.29，公共：114.114.114.114，google：8.8.8.8等）: " PRIMARY_DNS
        check_ip ${PRIMARY_DNS}
        [ $? -eq 0 ] && break
    done
    while true; do
        read -p "请输入备用DNS地址（例如：阿里：223.6.6.6，腾讯：119.28.28.28，公共：114.114.115.115，google：8.8.4.4等）: " BACKUP_DNS
        check_ip ${BACKUP_DNS}
        [ $? -eq 0 ] && break
    done
    if [ ${OS_RELEASE_VERSION} == "7" -o ${OS_RELEASE_VERSION} == "8" ];then
        nmcli connection modify "${CONNECTION_NAME}" con-name ${ETHNAME}
        cat > /etc/sysconfig/network-scripts/ifcfg-eth0 <<-EOF
NAME=${ETHNAME}
DEVICE=${ETHNAME}
ONBOOT=yes
BOOTPROTO=none
TYPE=Ethernet
IPADDR=${IP}
PREFIX=${PREFIX}
GATEWAY=${GATEWAY}
DNS1=${PRIMARY_DNS}
DNS2=${BACKUP_DNS}
EOF
        ${COLOR}"${OS_ID} ${OS_RELEASE} 网络已设置成功，10秒后，机器会自动重启!"${END}
	    sleep 10 && shutdown -r now
    else
        ${COLOR}"${OS_ID} ${OS_RELEASE} 网络已设置成功，请使用新IP重新登录!"${END}
        cat > /etc/NetworkManager/system-connections/${ETHNAME}.nmconnection <<-EOF
[connection]
id=${ETHNAME}
type=ethernet
interface-name=${ETHNAME}

[ethernet]

[ipv4]
address1=${IP}/${PREFIX},${GATEWAY}
dns=${PRIMARY_DNS};${BACKUP_DNS};
method=manual

[ipv6]
addr-gen-mode=default
method=auto

[proxy]
EOF
    fi
    nmcli con reload && nmcli dev up ${ETHNAME} >& /dev/null
}

set_ubuntu_network(){
    while true; do
        read -p "请输入IP地址: " IP
        check_ip ${IP}
        [ $? -eq 0 ] && break
    done
    read -p "请输入子网掩码位数: " PREFIX
    while true; do
        read -p "请输入网关地址: " GATEWAY
        check_ip ${GATEWAY}
        [ $? -eq 0 ] && break
    done
    while true; do
        read -p "请输入主DNS地址（例如：阿里：223.5.5.5，腾讯：119.29.29.29，公共：114.114.114.114，google：8.8.8.8等）: " PRIMARY_DNS
        check_ip ${PRIMARY_DNS}
        [ $? -eq 0 ] && break
    done
    while true; do
        read -p "请输入备用DNS地址（例如：阿里：223.6.6.6，腾讯：119.28.28.28，公共：114.114.115.115，google：8.8.4.4等）: " BACKUP_DNS
        check_ip ${BACKUP_DNS}
        [ $? -eq 0 ] && break
    done
    if [ ${OS_RELEASE_VERSION} == "18" ];then
        cat > /etc/netplan/01-netcfg.yaml <<-EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      dhcp6: no
      addresses: [${IP}/${PREFIX}] 
      gateway4: ${GATEWAY}
      nameservers:
        addresses: [${PRIMARY_DNS}, ${BACKUP_DNS}]
EOF
    elif [ ${OS_RELEASE_VERSION} == "20" ];then
        cat > /etc/netplan/00-installer-config.yaml <<-EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      dhcp6: no
      addresses: [${IP}/${PREFIX}] 
      gateway4: ${GATEWAY}
      nameservers:
        addresses: [${PRIMARY_DNS}, ${BACKUP_DNS}]
EOF
    elif [ ${OS_RELEASE_VERSION} == "22" ];then
        cat > /etc/netplan/00-installer-config.yaml <<-EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      dhcp6: no
      addresses: [${IP}/${PREFIX}]
      routes:
        - to: default
          via: ${GATEWAY}
      nameservers:
        addresses: [${PRIMARY_DNS}, ${BACKUP_DNS}]
EOF
    else
        cat > /etc/netplan/50-cloud-init.yaml <<-EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      dhcp6: no
      addresses: [${IP}/${PREFIX}]
      routes:
        - to: default
          via: ${GATEWAY}
      nameservers:
        addresses: [${PRIMARY_DNS}, ${BACKUP_DNS}]
EOF
    fi    
    ${COLOR}"${OS_ID} ${OS_RELEASE} 网络已设置成功,请重新启动系统后生效!"${END}
}   

set_debian_network(){
    ETHNAME=`ip addr | awk -F"[ :]" '/^2/{print $3}'`
    while true; do
        read -p "请输入IP地址: " IP
        check_ip ${IP}
        [ $? -eq 0 ] && break
    done
    read -p "请输入子网掩码位数: " PREFIX
    while true; do
        read -p "请输入网关地址: " GATEWAY
        check_ip ${GATEWAY}
        [ $? -eq 0 ] && break
    done
    while true; do
        read -p "请输入主DNS地址（例如：阿里：223.5.5.5，腾讯：119.29.29.29，公共：114.114.114.114，google：8.8.8.8等）: " PRIMARY_DNS
        check_ip ${PRIMARY_DNS}
        [ $? -eq 0 ] && break
    done
    while true; do
        read -p "请输入备用DNS地址（例如：阿里：223.6.6.6，腾讯：119.28.28.28，公共：114.114.115.115，google：8.8.4.4等）: " BACKUP_DNS
        check_ip ${BACKUP_DNS}
        [ $? -eq 0 ] && break
    done
    sed -ri -e "s/allow-hotplug ${ETHNAME}/auto eth0/g" -e "s/(iface) ${ETHNAME} (inet) dhcp/\1 eth0 \2 static/g" /etc/network/interfaces
    cat >> /etc/network/interfaces <<-EOF
address ${IP}/${PREFIX}
gateway ${GATEWAY}
dns-nameservers ${PRIMARY_DNS} ${BACKUP_DNS}
EOF
    ${COLOR}"${OS_ID} ${OS_RELEASE}  网络已设置成功,请重新启动系统后生效!"${END}
}

set_network(){
    if [ ${OS_ID} == "Rocky" -o ${OS_ID} == "AlmaLinux" -o ${OS_ID} == "CentOS" ];then
        set_rocky_almalinux_centos_network
    elif [ ${OS_ID} == "Ubuntu" ];then
        set_ubuntu_network
    else
        set_debian_network
    fi
}

set_dual_rocky_almalinux_centos_network(){
    ETHNAME=`ip addr | awk -F"[ :]" '/^2/{print $3}'`
    ETHNAME2=`ip addr | awk -F"[ :]" '/^3/{print $3}'`
    CONNECTION_NAME1=`nmcli dev | awk 'NR==2{print $4,$5,$6}'`
    CONNECTION_NAME2=`nmcli dev | awk 'NR==3{print $4,$5,$6}'`
    while true; do
        read -p "请输入第一块网卡IP地址: " IP
        check_ip ${IP}
        [ $? -eq 0 ] && break
    done
    read -p "请输入子网掩码位数: " PREFIX
    while true; do
        read -p "请输入网关地址: " GATEWAY
        check_ip ${GATEWAY}
        [ $? -eq 0 ] && break
    done
    while true; do
        read -p "请输入主DNS地址（例如：阿里：223.5.5.5，腾讯：119.29.29.29，公共：114.114.114.114，google：8.8.8.8等）: " PRIMARY_DNS
        check_ip ${PRIMARY_DNS}
        [ $? -eq 0 ] && break
    done
    while true; do
        read -p "请输入备用DNS地址（例如：阿里：223.6.6.6，腾讯：119.28.28.28，公共：114.114.115.115，google：8.8.4.4等）: " BACKUP_DNS
        check_ip ${BACKUP_DNS}
        [ $? -eq 0 ] && break
    done
    while true; do
        read -p "请输入第二块网卡IP地址: " IP2
        check_ip ${IP2}
        [ $? -eq 0 ] && break
    done
    read -p "请输入子网掩码位数: " PREFIX2
    if [ ${OS_RELEASE_VERSION} == "7" -o ${OS_RELEASE_VERSION} == "8" ];then
        nmcli connection modify "${CONNECTION_NAME}" con-name ${ETHNAME}
        cat > /etc/sysconfig/network-scripts/ifcfg-${ETHNAME} <<-EOF
NAME=${ETHNAME}
DEVICE=${ETHNAME}
ONBOOT=yes
BOOTPROTO=none
TYPE=Ethernet
IPADDR=${IP}
PREFIX=${PREFIX}
GATEWAY=${GATEWAY}
DNS1=${PRIMARY_DNS}
DNS2=${BACKUP_DNS}
EOF
        nmcli connection modify "${CONNECTION_NAME2}" con-name ${ETHNAME2}
        cat > /etc/sysconfig/network-scripts/ifcfg-${ETHNAME2} <<-EOF
NAME=${ETHNAME2}
DEVICE=${ETHNAME2}
ONBOOT=yes
BOOTPROTO=none
TYPE=Ethernet
IPADDR=${IP2}
PREFIX=${PREFIX2}
EOF
        ${COLOR}"${OS_ID} ${OS_RELEASE} 网络已设置成功，10秒后，机器会自动重启!"${END}
	    sleep 10 && shutdown -r now
    else
        ${COLOR}"${OS_ID} ${OS_RELEASE} 网络已设置成功，请使用新IP重新登录!"${END}
        cat > /etc/NetworkManager/system-connections/${ETHNAME}.nmconnection <<-EOF
[connection]
id=${ETHNAME}
type=ethernet
interface-name=${ETHNAME}

[ethernet]

[ipv4]
address1=${IP}/${PREFIX},${GATEWAY}
dns=${PRIMARY_DNS};${BACKUP_DNS};
method=manual

[ipv6]
addr-gen-mode=default
method=auto

[proxy]
EOF
        nmcli connection modify "${CONNECTION_NAME2}" con-name ${ETHNAME2}
        cat > /etc/NetworkManager/system-connections/${ETHNAME2}.nmconnection <<-EOF
[connection]
id=${ETHNAME2}
type=ethernet
interface-name=${ETHNAME2}

[ethernet]

[ipv4]
address1=${IP2}/${PREFIX2}
method=manual

[ipv6]
addr-gen-mode=default
method=auto

[proxy]
EOF
        chmod 600 /etc/NetworkManager/system-connections/${ETHNAME2}.nmconnection
    fi
    nmcli con reload && nmcli dev up ${ETHNAME} ${ETHNAME2} >& /dev/null
}

set_dual_ubuntu_network(){
    while true; do
        read -p "请输入第一块网卡IP地址: " IP
        check_ip ${IP}
        [ $? -eq 0 ] && break
    done
    read -p "请输入子网掩码位数: " PREFIX
    while true; do
        read -p "请输入网关地址: " GATEWAY
        check_ip ${GATEWAY}
        [ $? -eq 0 ] && break
    done
    while true; do
        read -p "请输入主DNS地址（例如：阿里：223.5.5.5，腾讯：119.29.29.29，公共：114.114.114.114，google：8.8.8.8等）: " PRIMARY_DNS
        check_ip ${PRIMARY_DNS}
        [ $? -eq 0 ] && break
    done
    while true; do
        read -p "请输入备用DNS地址（例如：阿里：223.6.6.6，腾讯：119.28.28.28，公共：114.114.115.115，google：8.8.4.4等）: " BACKUP_DNS
        check_ip ${BACKUP_DNS}
        [ $? -eq 0 ] && break
    done
    while true; do
        read -p "请输入第二块网卡IP地址: " IP2
        check_ip ${IP2}
        [ $? -eq 0 ] && break
    done
    read -p "请输入子网掩码位数: " PREFIX2
    if [ ${OS_RELEASE_VERSION} == "18" ];then
        cat > /etc/netplan/01-netcfg.yaml <<-EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      dhcp6: no
      addresses: [${IP}/${PREFIX}] 
      gateway4: ${GATEWAY}
      nameservers:
        addresses: [${PRIMARY_DNS}, ${BACKUP_DNS}]
    eth1:
      dhcp4: no
      dhcp6: no
      addresses: [${IP2}/${PREFIX2}] 
EOF
    elif [ ${OS_RELEASE_VERSION} == "20" ];then
        cat > /etc/netplan/00-installer-config.yaml <<-EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      dhcp6: no
      addresses: [${IP}/${PREFIX}] 
      gateway4: ${GATEWAY}
      nameservers:
        addresses: [${PRIMARY_DNS}, ${BACKUP_DNS}]
    eth1:
      dhcp4: no
      dhcp6: no
      addresses: [${IP2}/${PREFIX2}] 
EOF
    elif [ ${OS_RELEASE_VERSION} == "22" ];then
        cat > /etc/netplan/00-installer-config.yaml <<-EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      dhcp6: no
      addresses: [${IP}/${PREFIX}] 
      routes:
        - to: default
          via: ${GATEWAY}
      nameservers:
        addresses: [${PRIMARY_DNS}, ${BACKUP_DNS}]
    eth1:
      dhcp4: no
      dhcp6: no
      addresses: [${IP2}/${PREFIX2}] 
EOF
    else
        cat > /etc/netplan/50-cloud-init.yaml <<-EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      dhcp6: no
      addresses: [${IP}/${PREFIX}] 
      routes:
        - to: default
          via: ${GATEWAY}
      nameservers:
        addresses: [${PRIMARY_DNS}, ${BACKUP_DNS}]
    eth1:
      dhcp4: no
      dhcp6: no
      addresses: [${IP2}/${PREFIX2}] 
EOF
    fi
    ${COLOR}"${OS_ID} ${OS_RELEASE} 网络已设置成功,请重新启动系统后生效!"${END}
}

set_dual_debian_network(){
    ETHNAME=`ip addr | awk -F"[ :]" '/^2/{print $3}'`
    while true; do
        read -p "请输入第一块网卡IP地址: " IP
        check_ip ${IP}
        [ $? -eq 0 ] && break
    done
    read -p "请输入子网掩码位数: " PREFIX
    while true; do
        read -p "请输入网关地址: " GATEWAY
        check_ip ${GATEWAY}
        [ $? -eq 0 ] && break
    done
    while true; do
        read -p "请输入主DNS地址（例如：阿里：223.5.5.5，腾讯：119.29.29.29，公共：114.114.114.114，google：8.8.8.8等）: " PRIMARY_DNS
        check_ip ${PRIMARY_DNS}
        [ $? -eq 0 ] && break
    done
    while true; do
        read -p "请输入备用DNS地址（例如：阿里：223.6.6.6，腾讯：119.28.28.28，公共：114.114.115.115，google：8.8.4.4等）: " BACKUP_DNS
        check_ip ${BACKUP_DNS}
        [ $? -eq 0 ] && break
    done
    while true; do
        read -p "请输入第二块网卡IP地址: " IP2
        check_ip ${IP2}
        [ $? -eq 0 ] && break
    done
    read -p "请输入子网掩码位数: " PREFIX2
    sed -ri -e "s/allow-hotplug ${ETHNAME}/auto eth0/g" -e "s/(iface) ${ETHNAME} (inet) dhcp/\1 eth0 \2 static/g" /etc/network/interfaces
    cat >> /etc/network/interfaces <<-EOF
address ${IP}/${PREFIX}
gateway ${GATEWAY}
dns-nameservers ${PRIMARY_DNS} ${BACKUP_DNS}

auto eth1
iface eth1 inet static
address ${IP2}/${PREFIX2}
EOF
    ${COLOR}"${OS_ID} ${OS_RELEASE} 网络已设置成功,请重新启动系统后生效!"${END}
}

set_dual_network(){
    if [ ${OS_ID} == "Rocky" -o ${OS_ID} == "AlmaLinux" -o ${OS_ID} == "CentOS" ];then
        set_dual_rocky_almalinux_centos_network
    elif [ ${OS_ID} == "Ubuntu" ];then
        set_dual_ubuntu_network
    else
        set_dual_debian_network
    fi
}

set_hostname(){
    read -p "请输入主机名: " HOST
    hostnamectl set-hostname ${HOST}
    ${COLOR}"${OS_ID} ${OS_RELEASE} 主机名设置成功,请重新登录生效!"${END}
}

aliyun(){
    MIRROR=mirrors.aliyun.com
}

huawei(){
    MIRROR=repo.huaweicloud.com
}

tencent(){
    MIRROR=mirrors.tencent.com
}

tuna(){
    MIRROR=mirrors.tuna.tsinghua.edu.cn
}

netease(){
    MIRROR=mirrors.163.com
}

sohu(){
    MIRROR=mirrors.sohu.com
}

nju(){
    MIRROR=mirrors.nju.edu.cn
}

ustc(){
    MIRROR=mirrors.ustc.edu.cn
}

sjtu(){
    MIRROR=mirrors.sjtug.sjtu.edu.cn
}

xjtu(){
    MIRROR=mirrors.xjtu.edu.cn
}

bfsu(){
    MIRROR=mirrors.bfsu.edu.cn
}

bjtu(){
    MIRROR=mirror.bjtu.edu.cn
}

pku(){
    MIRROR=mirrors.pku.edu.cn
}

archive_fedora(){
    MIRROR=archives.fedoraproject.org
}

set_yum_rocky_9(){
    [ -d /etc/yum.repos.d/backup ] || { mkdir /etc/yum.repos.d/backup; mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup; }
    MIRROR_URL=`echo ${MIRROR} | awk -F"." '{print $2}'`
    if [ ${MIRROR_URL} == "aliyun" -o ${MIRROR_URL} == "xjtu" ];then
        cat > /etc/yum.repos.d/base.repo <<-EOF
[BaseOS]
name=BaseOS
baseurl=https://${MIRROR}/rockylinux/\$releasever/BaseOS/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-\$releasever

[AppStream]
name=AppStream
baseurl=https://${MIRROR}/rockylinux/\$releasever/AppStream/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-\$releasever

[extras]
name=extras
baseurl=https://${MIRROR}/rockylinux/\$releasever/extras/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-\$releasever
EOF
    elif [ ${MIRROR_URL} == "sohu" ];then
        cat > /etc/yum.repos.d/base.repo <<-EOF
[BaseOS]
name=BaseOS
baseurl=https://${MIRROR}/Rocky/\$releasever/BaseOS/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-\$releasever

[AppStream]
name=AppStream
baseurl=https://${MIRROR}/Rocky/\$releasever/AppStream/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-\$releasever

[extras]
name=extras
baseurl=https://${MIRROR}/Rocky/\$releasever/extras/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-\$releasever
EOF
    else
        cat > /etc/yum.repos.d/base.repo <<-EOF
[BaseOS]
name=BaseOS
baseurl=https://${MIRROR}/rocky/\$releasever/BaseOS/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-\$releasever

[AppStream]
name=AppStream
baseurl=https://${MIRROR}/rocky/\$releasever/AppStream/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-\$releasever

[extras]
name=extras
baseurl=https://${MIRROR}/rocky/\$releasever/extras/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-\$releasever
EOF
    fi
    ${COLOR}"更新镜像源中,请稍等..."${END}
    dnf clean all &> /dev/null
    dnf makecache &> /dev/null
    ${COLOR}"${OS_ID} ${OS_RELEASE} YUM源设置完成!"${END}
}

rocky_9_base_menu(){
    while true;do
        echo -e "\E[$[RANDOM%7+31];1m"
        cat <<-EOF
1)阿里镜像源
2)腾讯镜像源
3)网易镜像源
4)搜狐镜像源
5)南京大学镜像源
6)中科大镜像源
7)上海交通大学镜像源
8)西安交通大学镜像源
9)北京大学镜像源
10)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-10): " NUM
        case ${NUM} in
        1)
            aliyun
            set_yum_rocky_9
            ;;
        2)
            tencent
            set_yum_rocky_9
            ;;
        3)
            netease
            set_yum_rocky_9
            ;;
        4)
            sohu
            set_yum_rocky_9
            ;;
        5)
            nju
            set_yum_rocky_9
            ;;
        6)
            ustc
            set_yum_rocky_9
            ;;
        7)
            sjtu
            set_yum_rocky_9
            ;;
        8)
            xjtu
            set_yum_rocky_9
            ;;
        9)
            pku
            set_yum_rocky_9
            ;;
        10)
            break
            ;;
        *)
            ${COLOR}"输入错误,请输入正确的数字(1-10)!"${END}
            ;;
        esac
    done
}

set_devel_rocky_9(){
    MIRROR_MIRROR=`echo ${MIRROR} | awk -F"." '{print $2}'`
    if [ ${MIRROR_MIRROR} == "aliyun" -o ${MIRROR_MIRROR} == "xjtu" ];then
        cat > /etc/yum.repos.d/devel.repo <<-EOF
[devel]
name=devel
baseurl=https://${MIRROR}/rockylinux/\$releasever/devel/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-\$releasever
EOF
    elif [ ${MIRROR_MIRROR} == "sohu" ];then
        cat > /etc/yum.repos.d/devel.repo <<-EOF
[devel]
name=devel
baseurl=https://${MIRROR}/Rocky/\$releasever/devel/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-\$releasever
EOF
    else
        cat > /etc/yum.repos.d/devel.repo <<-EOF
[devel]
name=devel
baseurl=https://${MIRROR}/rocky/\$releasever/devel/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-\$releasever
EOF
    fi
    ${COLOR}"更新镜像源中,请稍等..."${END}
    dnf clean all &> /dev/null
    dnf makecache &> /dev/null
    ${COLOR}"${OS_ID} ${OS_RELEASE} devel源设置完成!"${END}
}

rocky_9_devel_menu(){
    while true;do
        echo -e "\E[$[RANDOM%7+31];1m"
        cat <<-EOF
1)阿里镜像源
2)腾讯镜像源
3)网易镜像源
4)搜狐镜像源
5)南京大学镜像源
6)中科大镜像源
7)上海交通大学镜像源
8)西安交通大学镜像源
9)北京大学镜像源
10)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-10): " NUM
        case ${NUM} in
        1)
            aliyun
            set_devel_rocky_9
            ;;
        2)
            tencent
            set_devel_rocky_9
            ;;
        3)
            netease
            set_devel_rocky_9
            ;;
        4)
            sohu
            set_devel_rocky_9
            ;;
        5)
            nju
            set_devel_rocky_9
            ;;
        6)
            ustc
            set_devel_rocky_9
            ;;
        7)
            sjtu
            set_devel_rocky_9
            ;;
        8)
            xjtu
            set_devel_rocky_9
            ;;
        9)
            pku
            set_devel_rocky_9
            ;;
        10)
            break
            ;;
        *)
            ${COLOR}"输入错误,请输入正确的数字(1-10)!"${END}
            ;;
        esac
    done
}

set_yum_almalinux_9(){
    [ -d /etc/yum.repos.d/backup ] || { mkdir /etc/yum.repos.d/backup; mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup; }
    cat > /etc/yum.repos.d/base.repo <<-EOF
[BaseOS]
name=BaseOS
baseurl=https://${MIRROR}/almalinux/\$releasever/BaseOS/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9

[AppStream]
name=AppStream
baseurl=https://${MIRROR}/almalinux/\$releasever/AppStream/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9

[extras]
name=extras
baseurl=https://${MIRROR}/almalinux/\$releasever/extras/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9
EOF
    ${COLOR}"更新镜像源中,请稍等..."${END}
    dnf clean all &> /dev/null
    dnf makecache &> /dev/null
    ${COLOR}"${OS_ID} ${OS_RELEASE} YUM源设置完成!"${END}
}

almalinux_9_base_menu(){
    while true;do
        echo -e "\E[$[RANDOM%7+31];1m"
        cat <<-EOF
1)阿里镜像源
2)腾讯镜像源
3)南京大学镜像源
4)上海交通大学镜像源
5)北京大学镜像源
6)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-6): " NUM
        case ${NUM} in
        1)
            aliyun
            set_yum_almalinux_9
            ;;
        2)
            tencent
            set_yum_almalinux_9
            ;;
        3)
            nju
            set_yum_almalinux_9
            ;;
        4)
            sjtu
            set_yum_almalinux_9
            ;;
        5)
            pku
            set_yum_almalinux_9
            ;;
        6)
            break
            ;;
        *)
            ${COLOR}"输入错误,请输入正确的数字(1-6)!"${END}
            ;;
        esac
    done
}

set_crb_almalinux_9(){
    cat > /etc/yum.repos.d/crb.repo <<-EOF
[crb]
name=crb
baseurl=https://${MIRROR}/almalinux/\$releasever/CRB/\$basearch/os
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9
EOF
    ${COLOR}"更新镜像源中,请稍等..."${END}
    dnf clean all &> /dev/null
    dnf makecache &> /dev/null
    ${COLOR}"${OS_ID} ${OS_RELEASE} crb源设置完成!"${END}
}

almalinux_9_crb_menu(){
    while true;do
        echo -e "\E[$[RANDOM%7+31];1m"
        cat <<-EOF
1)阿里镜像源
2)腾讯镜像源
3)南京大学镜像源
4)上海交通大学镜像源
5)北京大学镜像源
6)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-6): " NUM
        case ${NUM} in
        1)
            aliyun
            set_crb_almalinux_9
            ;;
        2)
            tencent
            set_crb_almalinux_9
            ;;
        3)
            nju
            set_crb_almalinux_9
            ;;
        4)
            sjtu
            set_crb_almalinux_9
            ;;
        5)
            pku
            set_crb_almalinux_9
            ;;
        6)
            break
            ;;
        *)
            ${COLOR}"输入错误,请输入正确的数字(1-6)!"${END}
            ;;
        esac
    done
}

set_devel_almalinux_9(){
    cat > /etc/yum.repos.d/devel.repo <<-EOF
[devel]
name=devel
baseurl=https://${MIRROR}/almalinux/\$releasever/devel/\$basearch/os
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9
EOF
    ${COLOR}"更新镜像源中,请稍等..."${END}
    dnf clean all &> /dev/null
    dnf makecache &> /dev/null
    ${COLOR}"${OS_ID} ${OS_RELEASE} devel源设置完成!"${END}
}

almalinux_9_devel_menu(){
    while true;do
        echo -e "\E[$[RANDOM%7+31];1m"
        cat <<-EOF
1)阿里镜像源
2)腾讯镜像源
3)南京大学镜像源
4)上海交通大学镜像源
5)北京大学镜像源
6)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-6): " NUM
        case ${NUM} in
        1)
            aliyun
            set_devel_almalinux_9
            ;;
        2)
            tencent
            set_devel_almalinux_9
            ;;
        3)
            nju
            set_devel_almalinux_9
            ;;
        4)
            sjtu
            set_devel_almalinux_9
            ;;
        5)
            pku
            set_devel_almalinux_9
            ;;
        6)
            break
            ;;
        *)
            ${COLOR}"输入错误,请输入正确的数字(1-6)!"${END}
            ;;
        esac
    done
}

set_yum_rocky_8(){
    [ -d /etc/yum.repos.d/backup ] || { mkdir /etc/yum.repos.d/backup; mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup; }
    MIRROR_URL=`echo ${MIRROR} | awk -F"." '{print $2}'`
    if [ ${MIRROR_URL} == "aliyun" -o ${MIRROR_URL} == "xjtu" ];then
        cat > /etc/yum.repos.d/base.repo <<-EOF
[BaseOS]
name=BaseOS
baseurl=https://${MIRROR}/rockylinux/\$releasever/BaseOS/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial

[AppStream]
name=AppStream
baseurl=https://${MIRROR}/rockylinux/\$releasever/AppStream/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial

[extras]
name=extras
baseurl=https://${MIRROR}/rockylinux/\$releasever/extras/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial
EOF
    elif [ ${MIRROR_URL} == "sohu" ];then
        cat > /etc/yum.repos.d/base.repo <<-EOF
[BaseOS]
name=BaseOS
baseurl=https://${MIRROR}/Rocky/\$releasever/BaseOS/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial

[AppStream]
name=AppStream
baseurl=https://${MIRROR}/Rocky/\$releasever/AppStream/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial

[extras]
name=extras
baseurl=https://${MIRROR}/Rocky/\$releasever/extras/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial
EOF
    else
        cat > /etc/yum.repos.d/base.repo <<-EOF
[BaseOS]
name=BaseOS
baseurl=https://${MIRROR}/rocky/\$releasever/BaseOS/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial

[AppStream]
name=AppStream
baseurl=https://${MIRROR}/rocky/\$releasever/AppStream/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial

[extras]
name=extras
baseurl=https://${MIRROR}/rocky/\$releasever/extras/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial
EOF
    fi
    ${COLOR}"更新镜像源中,请稍等..."${END}
    dnf clean all &> /dev/null
    dnf makecache &> /dev/null
    ${COLOR}"${OS_ID} ${OS_RELEASE} YUM源设置完成!"${END}
}

rocky_8_base_menu(){
    while true;do
        echo -e "\E[$[RANDOM%7+31];1m"
        cat <<-EOF
1)阿里镜像源
2)腾讯镜像源
3)网易镜像源
4)搜狐镜像源
5)南京大学镜像源
6)中科大镜像源
7)上海交通大学镜像源
8)西安交通大学镜像源
9)北京大学镜像源
10)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-10): " NUM
        case ${NUM} in
        1)
            aliyun
            set_yum_rocky_8
            ;;
        2)
            tencent
            set_yum_rocky_8
            ;;
        3)
            netease
            set_yum_rocky_8
            ;;
        4)
            sohu
            set_yum_rocky_8
            ;;
        5)
            nju
            set_yum_rocky_8
            ;;
        6)
            ustc
            set_yum_rocky_8
            ;;
        7)
            sjtu
            set_yum_rocky_8
            ;;
        8)
            xjtu
            set_yum_rocky_8
            ;;
        9)
            pku
            set_yum_rocky_8
            ;;
        10)
            break
            ;;
        *)
            ${COLOR}"输入错误,请输入正确的数字(1-10)!"${END}
            ;;
        esac
    done
}

set_powertools_rocky_8(){
    MIRROR_URL=`echo ${MIRROR} | awk -F"." '{print $2}'`
    if [ ${MIRROR_URL} == "aliyun" -o ${MIRROR_URL} == "xjtu" ];then
        cat > /etc/yum.repos.d/powertools.repo <<-EOF
[PowerTools]
name=PowerTools
baseurl=https://${MIRROR}/rockylinux/\$releasever/PowerTools/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial
EOF
    elif [ ${MIRROR_URL} == "sohu" ];then
        cat > /etc/yum.repos.d/powertools.repo <<-EOF
[PowerTools]
name=PowerTools
baseurl=https://${MIRROR}/Rocky/\$releasever/PowerTools/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial
EOF
    else
        cat > /etc/yum.repos.d/powertools.repo <<-EOF
[PowerTools]
name=PowerTools
baseurl=https://${MIRROR}/rocky/\$releasever/PowerTools/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial
EOF
    fi
    ${COLOR}"更新镜像源中,请稍等..."${END}
    dnf clean all &> /dev/null
    dnf makecache &> /dev/null
    ${COLOR}"${OS_ID} ${OS_RELEASE} PowerTools源设置完成!"${END}
}

rocky_8_powertools_menu(){
    while true;do
        echo -e "\E[$[RANDOM%7+31];1m"
        cat <<-EOF
1)阿里镜像源
2)腾讯镜像源
3)网易镜像源
4)搜狐镜像源
5)南京大学镜像源
6)中科大镜像源
7)上海交通大学镜像源
8)西安交通大学镜像源
9)北京大学镜像源
10)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-10): " NUM
        case ${NUM} in
        1)
            aliyun
            set_powertools_rocky_8
            ;;
        2)
            tencent
            set_powertools_rocky_8
            ;;
        3)
            netease
            set_powertools_rocky_8
            ;;
        4)
            sohu
            set_powertools_rocky_8
            ;;
        5)
            nju
            set_powertools_rocky_8
            ;;
        6)
            ustc
            set_powertools_rocky_8
            ;;
        7)
            sjtu
            set_powertools_rocky_8
            ;;
        8)
            xjtu
            set_powertools_rocky_8
            ;;
        9)
            pku
            set_powertools_rocky_8
            ;;
        10)
            break
            ;;
        *)
            ${COLOR}"输入错误,请输入正确的数字(1-10)!"${END}
            ;;
        esac
    done
}

set_yum_almalinux_8(){
    [ -d /etc/yum.repos.d/backup ] || { mkdir /etc/yum.repos.d/backup; mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup; }
    cat > /etc/yum.repos.d/base.repo <<-EOF
[BaseOS]
name=BaseOS
baseurl=https://${MIRROR}/almalinux/\$releasever/BaseOS/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux

[AppStream]
name=AppStream
baseurl=https://${MIRROR}/almalinux/\$releasever/AppStream/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux

[extras]
name=extras
baseurl=https://${MIRROR}/almalinux/\$releasever/extras/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux
EOF
    ${COLOR}"更新镜像源中,请稍等..."${END}
    dnf clean all &> /dev/null
    dnf makecache &> /dev/null
    ${COLOR}"${OS_ID} ${OS_RELEASE} YUM源设置完成!"${END}
}

almalinux_8_base_menu(){
    while true;do
        echo -e "\E[$[RANDOM%7+31];1m"
        cat <<-EOF
1)阿里镜像源
2)腾讯镜像源
3)南京大学镜像源
4)上海交通大学镜像源
5)北京大学镜像源
6)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-6): " NUM
        case ${NUM} in
        1)
            aliyun
            set_yum_almalinux_8
            ;;
        2)
            tencent
            set_yum_almalinux_8
            ;;
        3)
            nju
            set_yum_almalinux_8
            ;;
        4)
            sjtu
            set_yum_almalinux_8
            ;;
        5)
            pku
            set_yum_almalinux_8
            ;;
        6)
            break
            ;;
        *)
            ${COLOR}"输入错误,请输入正确的数字(1-6)!"${END}
            ;;
        esac
    done
}

set_powertools_almalinux_8(){
    cat > /etc/yum.repos.d/powertools.repo <<-EOF
[powertools]
name=powertools
baseurl=https://${MIRROR}/almalinux/\$releasever/PowerTools/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux
EOF
    ${COLOR}"更新镜像源中,请稍等..."${END}
    dnf clean all &> /dev/null
    dnf makecache &> /dev/null
    ${COLOR}"${OS_ID} ${OS_RELEASE} PowerTools源设置完成!"${END}
}

almalinux_8_powertools_menu(){
    while true;do
        echo -e "\E[$[RANDOM%7+31];1m"
        cat <<-EOF
1)阿里镜像源
2)腾讯镜像源
3)南京大学镜像源
4)上海交通大学镜像源
5)北京大学镜像源
6)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-6): " NUM
        case ${NUM} in
        1)
            aliyun
            set_powertools_almalinux_8
            ;;
        2)
            tencent
            set_powertools_almalinux_8
            ;;
        3)
            nju
            set_powertools_almalinux_8
            ;;
        4)
            sjtu
            set_powertools_almalinux_8
            ;;
        5)
            pku
            set_powertools_almalinux_8
            ;;
        6)
            break
            ;;
        *)
            ${COLOR}"输入错误,请输入正确的数字(1-6)!"${END}
            ;;
        esac
    done
}

set_yum_centos_stream_9(){
    [ -d /etc/yum.repos.d/backup ] || { mkdir /etc/yum.repos.d/backup; mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup; }
    cat > /etc/yum.repos.d/base.repo <<-EOF
[BaseOS]
name=BaseOS
baseurl=https://${MIRROR}/centos-stream/\$stream/BaseOS/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[AppStream]
name=AppStream
baseurl=https://${MIRROR}/centos-stream/\$stream/AppStream/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[extras-common]
name=extras-common
baseurl=https://${MIRROR}/centos-stream/SIGs/\$stream/extras/\$basearch/extras-common/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
    ${COLOR}"更新镜像源中,请稍等..."${END}
    dnf clean all &> /dev/null
    dnf makecache &> /dev/null
    ${COLOR}"${OS_ID} ${OS_RELEASE} YUM源设置完成!"${END}
}

centos_stream_9_base_menu(){
    while true;do
        echo -e "\E[$[RANDOM%7+31];1m"
        cat <<-EOF
1)阿里镜像源
2)华为镜像源
3)腾讯镜像源
4)清华镜像源
5)南京大学镜像源
6)中科大镜像源
7)北京外国语大学镜像源
8)北京大学镜像源
9)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-9): " NUM
        case ${NUM} in
        1)
            aliyun
            set_yum_centos_stream_9
            ;;
        2)
            huawei
            set_yum_centos_stream_9
            ;;
        3)
            tencent
            set_yum_centos_stream_9
            ;;
        4)
            tuna
            set_yum_centos_stream_9
            ;;
        5)
            nju
            set_yum_centos_stream_9
            ;;
        6)
            ustc
            set_yum_centos_stream_9
            ;;
        7)
            bfsu
            set_yum_centos_stream_9
            ;;
        8)
            pku
            set_yum_centos_stream_9
            ;;
        9)
            break
            ;;
        *)
            ${COLOR}"输入错误,请输入正确的数字(1-9)!"${END}
            ;;
        esac
    done
}

set_crb_centos_stream_9(){
    cat > /etc/yum.repos.d/crb.repo <<-EOF
[crb]
name=crb
baseurl=https://${MIRROR}/centos-stream/\$releasever-stream/CRB/\$basearch/os
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
    ${COLOR}"更新镜像源中,请稍等..."${END}
    dnf clean all &> /dev/null
    dnf makecache &> /dev/null
    ${COLOR}"${OS_ID} ${OS_RELEASE} crb源设置完成!"${END}
}

centos_stream_9_crb_menu(){
    while true;do
        echo -e "\E[$[RANDOM%7+31];1m"
        cat <<-EOF
1)阿里镜像源
2)华为镜像源
3)腾讯镜像源
4)清华镜像源
5)南京大学镜像源
6)中科大镜像源
7)北京外国语大学镜像源
8)北京大学镜像源
9)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-9): " NUM
        case ${NUM} in
        1)
            aliyun
            set_crb_centos_stream_9
            ;;
        2)
            huawei
            set_crb_centos_stream_9
            ;;
        3)
            tencent
            set_crb_centos_stream_9
            ;;
        4)
            tuna
            set_crb_centos_stream_9
            ;;
        5)
            nju
            set_crb_centos_stream_9
            ;;
        6)
            ustc
            set_crb_centos_stream_9
            ;;
        6)
            bfsu
            set_crb_centos_stream_9
            ;;			
        8)
            pku
            set_crb_centos_stream_9
            ;;
        9)
            break
            ;;
        *)
            ${COLOR}"输入错误,请输入正确的数字(1-9)!"${END}
            ;;
        esac
    done
}

set_yum_centos_stream_8(){
    [ -d /etc/yum.repos.d/backup ] || { mkdir /etc/yum.repos.d/backup; mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup; }
    cat > /etc/yum.repos.d/base.repo <<-EOF
[BaseOS]
name=BaseOS
baseurl=https://${MIRROR}/centos-vault/\$stream/BaseOS/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[AppStream]
name=AppStream
baseurl=https://${MIRROR}/centos-vault/\$stream/AppStream/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[extras]
name=extras
baseurl=https://${MIRROR}/centos-vault/\$stream/extras/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
    ${COLOR}"更新镜像源中,请稍等..."${END}
    dnf clean all &> /dev/null
    dnf makecache &> /dev/null
    ${COLOR}"${OS_ID} ${OS_RELEASE} YUM源设置完成!"${END}
}

centos_stream_8_base_menu(){
    while true;do
        echo -e "\E[$[RANDOM%7+31];1m"
        cat <<-EOF
1)阿里镜像源
2)华为镜像源
3)腾讯镜像源
4)清华镜像源
5)南京大学镜像源
6)中科大镜像源
7)北京外国语大学镜像源
8)北京大学镜像源
9)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-9): " NUM
        case ${NUM} in
        1)
            aliyun
            set_yum_centos_stream_8
            ;;
        2)
            huawei
            set_yum_centos_stream_8
            ;;
        3)
            tencent
            set_yum_centos_stream_8
            ;;
        4)
            tuna
            set_yum_centos_stream_8
            ;;
        5)
            nju
            set_yum_centos_stream_8
            ;;
        6)
            ustc
            set_yum_centos_stream_8
            ;;
        6)
            bfsu
            set_yum_centos_stream_8
            ;;			
        8)
            pku
            set_yum_centos_stream_8
            ;;
        9)
            break
            ;;
        *)
            ${COLOR}"输入错误,请输入正确的数字(1-9)!"${END}
            ;;
        esac
    done
}

set_powertools_centos_stream_8(){
    cat > /etc/yum.repos.d/powertools.repo <<-EOF
[PowerTools]
name=PowerTools
baseurl=https://${MIRROR}/centos-vault/\$stream/PowerTools/\$basearch/os/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
    ${COLOR}"更新镜像源中,请稍等..."${END}
    dnf clean all &> /dev/null
    dnf makecache &> /dev/null
    ${COLOR}"${OS_ID} ${OS_RELEASE} PowerTools源设置完成!"${END}
}

centos_stream_8_powertools_menu(){
    while true;do
        echo -e "\E[$[RANDOM%7+31];1m"
        cat <<-EOF
1)阿里镜像源
2)华为镜像源
3)腾讯镜像源
4)清华镜像源
5)南京大学镜像源
6)中科大镜像源
7)北京外国语大学镜像源
8)北京大学镜像源
9)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-9): " NUM
        case ${NUM} in
        1)
            aliyun
            set_powertools_centos_stream_8
            ;;
        2)
            huawei
            set_powertools_centos_stream_8
            ;;
        3)
            tencent
            set_powertools_centos_stream_8
            ;;
        4)
            tuna
            set_powertools_centos_stream_8
            ;;
        5)
            nju
            set_powertools_centos_stream_8
            ;;
        6)
            ustc
            set_powertools_centos_stream_8
            ;;
        7)
            bfsu
            set_powertools_centos_stream_8
            ;;
        8)
            pku
            set_powertools_centos_stream_8
            ;;
        9)
            break
            ;;
        *)
            ${COLOR}"输入错误,请输入正确的数字(1-9)!"${END}
            ;;
        esac
    done
}

set_epel_rocky_almalinux_centos_8_9(){
    MIRROR_URL=`echo ${MIRROR} | awk -F"." '{print $2}'`
    if [ ${MIRROR_URL} == "sohu" ];then
        cat > /etc/yum.repos.d/epel.repo <<-EOF
[epel]
name=epel
baseurl=https://${MIRROR}/fedora-epel/\$releasever/Everything/\$basearch/
gpgcheck=1
gpgkey=https://${MIRROR}/fedora-epel/RPM-GPG-KEY-EPEL-\$releasever
EOF
    elif [ ${MIRROR_URL} == "sjtu" ];then
        cat > /etc/yum.repos.d/epel.repo <<-EOF
[epel]
name=epel
baseurl=https://${MIRROR}/fedora/epel/\$releasever/Everything/\$basearch/
gpgcheck=1
gpgkey=https://${MIRROR}/fedora/epel/RPM-GPG-KEY-EPEL-\$releasever
EOF
    else
        cat > /etc/yum.repos.d/epel.repo <<-EOF
[epel]
name=epel
baseurl=https://${MIRROR}/epel/\$releasever/Everything/\$basearch/
gpgcheck=1
gpgkey=https://${MIRROR}/epel/RPM-GPG-KEY-EPEL-\$releasever
EOF
    fi
    ${COLOR}"更新镜像源中,请稍等..."${END}
    dnf clean all &> /dev/null
    dnf makecache &> /dev/null
    ${COLOR}"${OS_ID} ${OS_RELEASE} EPEL源设置完成!"${END}
}

rocky_almalinux_centos_8_9_epel_menu(){
    while true;do
        echo -e "\E[$[RANDOM%7+31];1m"
        cat <<-EOF
1)阿里镜像源
2)华为镜像源
3)腾讯镜像源
4)清华镜像源
5)搜狐镜像源
6)南京大学镜像源
7)中科大镜像源
8)上海交通大学镜像源
9)西安交通大学镜像源
9)北京外国语大学镜像源
11)北京大学镜像源
12)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-12): " NUM
        case ${NUM} in
        1)
            aliyun
            set_epel_rocky_almalinux_centos_8_9
            ;;
        2)
            huawei
            set_epel_rocky_almalinux_centos_8_9
            ;;
        3)
            tencent
            set_epel_rocky_almalinux_centos_8_9
            ;;
        4)
            tuna
            set_epel_rocky_almalinux_centos_8_9
            ;;
        5)
            sohu
            set_epel_rocky_almalinux_centos_8_9
            ;;
        6)
            nju
            set_epel_rocky_almalinux_centos_8_9
            ;;
        7)
            ustc
            set_epel_rocky_almalinux_centos_8_9
            ;;
        8)
            sjtu
            set_epel_rocky_almalinux_centos_8_9
            ;;
        9)
            xjtu
            set_epel_rocky_almalinux_centos_8_9
            ;;
        10)
            bfsu
            set_epel_rocky_almalinux_centos_8_9
            ;;
        11)
            pku
            set_epel_rocky_almalinux_centos_8_9
            ;;

        12)
            break
            ;;
        *)
            ${COLOR}"输入错误,请输入正确的数字(1-12)!"${END}
            ;;
        esac
    done
}

set_yum_centos_7(){    
    [ -d /etc/yum.repos.d/backup ] || { mkdir /etc/yum.repos.d/backup; mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup; }
    OS_RELEASE_FULL_VERSION=`cat /etc/centos-release | sed -rn 's/^(CentOS Linux release )(.*)( \(Core\))/\2/p'`
    cat > /etc/yum.repos.d/base.repo <<-EOF
[base]
name=base
baseurl=https://${MIRROR}/centos-vault/${OS_RELEASE_FULL_VERSION}/os/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-\$releasever

[extras]
name=extras
baseurl=https://${MIRROR}/centos-vault/${OS_RELEASE_FULL_VERSION}/extras/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-\$releasever

[updates]
name=updates
baseurl=https://${MIRROR}/centos-vault/${OS_RELEASE_FULL_VERSION}/updates/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-\$releasever
EOF
    ${COLOR}"更新镜像源中,请稍等..."${END}
    yum clean all &> /dev/null
    yum makecache &> /dev/null
    ${COLOR}"${OS_ID} ${OS_RELEASE} YUM源设置完成!"${END}
}

centos_7_base_menu(){
    while true;do
        echo -e "\E[$[RANDOM%7+31];1m"
        cat <<-EOF
1)阿里镜像源
2)华为镜像源
3)腾讯镜像源
4)清华镜像源
5)南京大学镜像源
6)中科大镜像源
7)北京外国语大学镜像源
8)北京大学镜像源
9)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-9): " NUM
        case ${NUM} in
        1)
            aliyun
            set_yum_centos_7
            ;;
        2)
            huawei
            set_yum_centos_7
            ;;
        3)
            tencent
            set_yum_centos_7
            ;;
        4)
            tuna
            set_yum_centos_7
            ;;
        5)
            nju
            set_yum_centos_7
            ;;
        6)
            ustc
            set_yum_centos_7
            ;;
        7)
            bfsu
            set_yum_centos_7
            ;;
        8)
            pku
            set_yum_centos_7
            ;;
        9)
            break
            ;;
        *)
            ${COLOR}"输入错误,请输入正确的数字(1-9)!"${END}
            ;;
        esac
    done
}

set_epel_centos_7(){
    MIRROR_URL=`echo ${MIRROR} | awk -F"." '{print $2}'`
    if [ ${MIRROR_URL} == "aliyun" -o ${MIRROR_URL} == "tencent" ];then
        cat > /etc/yum.repos.d/epel.repo <<-EOF
[epel]
name=epel
baseurl=https://${MIRROR}/epel-archive/\$releasever/\$basearch/
gpgcheck=1
gpgkey=https://${MIRROR}/epel-archive/RPM-GPG-KEY-EPEL-\$releasever
EOF
    else
        cat > /etc/yum.repos.d/epel.repo <<-EOF
[epel]
name=epel
baseurl=https://${MIRROR}/pub/archive/epel/\$releasever/\$basearch/
gpgcheck=1
gpgkey=https://${MIRROR}/pub/archive/epel/RPM-GPG-KEY-EPEL-\$releasever
EOF
    fi
    ${COLOR}"更新镜像源中,请稍等..."${END}
    yum clean all &> /dev/null
    yum makecache &> /dev/null
    ${COLOR}"${OS_ID} ${OS_RELEASE} EPEL源设置完成!"${END}
}

centos_7_epel_menu(){
    while true;do
        echo -e "\E[$[RANDOM%7+31];1m"
        cat <<-EOF
1)阿里镜像源
2)腾讯镜像源
3)fedora镜像源
4)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-4): " NUM
        case ${NUM} in
        1)
            aliyun
            set_epel_centos_7
            ;;
        2)
            tencent
            set_epel_centos_7
            ;;
        3)
            archive_fedora
            set_epel_centos_7
            ;;
        4)
            break
            ;;
        *)
            ${COLOR}"输入错误,请输入正确的数字(1-4)!"${END}
            ;;
        esac
    done
}

rocky_menu(){
    while true;do
        echo -e "\E[$[RANDOM%7+31];1m"
        cat <<-EOF
1)base仓库
2)epel仓库
3)Rocky 9 devel仓库
4)Rocky 8 PowerTools仓库
5)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-5): " NUM
        case ${NUM} in
        1)
            if [ ${OS_RELEASE_VERSION} == "8" ];then
                rocky_8_base_menu
            else
                rocky_9_base_menu
            fi
            ;;
        2)
            rocky_almalinux_centos_8_9_epel_menu
            ;;
        3)
            if [ ${OS_RELEASE_VERSION} == "9" ];then
                rocky_9_devel_menu
            else
                ${COLOR}"${OS_ID} ${OS_RELEASE} 没有devel源，不用设置!"${END}
            fi
            ;;
        4)
            if [ ${OS_RELEASE_VERSION} == "8" ];then
                rocky_8_powertools_menu
            else
                ${COLOR}"${OS_ID} ${OS_RELEASE} 没有powertools源，不用设置!"${END}
            fi
            ;;
        5)
            break
            ;;
        *)
            ${COLOR}"输入错误,请输入正确的数字(1-5)!"${END}
            ;;
        esac
    done
}

almalinux_menu(){
    while true;do
        echo -e "\E[$[RANDOM%7+31];1m"
        cat <<-EOF
1)base仓库
2)epel仓库
3)AlmaLinux 9 crb仓库
4)AlmaLinux 9 devel仓库
5)AlmaLinux 8 PowerTools仓库
6)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-6): " NUM
        case ${NUM} in
        1)
            if [ ${OS_RELEASE_VERSION} == "8" ];then
                almalinux_8_base_menu
            else
                almalinux_9_base_menu
            fi
            ;;
        2)
            rocky_almalinux_centos_8_9_epel_menu
            ;;
        3)
            if [ ${OS_RELEASE_VERSION} == "9" ];then
                almalinux_9_crb_menu
            else
                ${COLOR}"${OS_ID} ${OS_RELEASE} 没有crb源，不用设置!"${END}
            fi
            ;;
        4)
            if [ ${OS_RELEASE_VERSION} == "9" ];then
                almalinux_9_devel_menu
            else
                ${COLOR}"${OS_ID} ${OS_RELEASE} 没有devel源，不用设置!"${END}
            fi
            ;;
        5)
            if [ ${OS_RELEASE_VERSION} == "8" ];then
                almalinux_8_powertools_menu
            else
                ${COLOR}"${OS_ID} ${OS_RELEASE} 没有powertools源，不用设置!"${END}
            fi
            ;;
        6)
            break
            ;;
        *)
            ${COLOR}"输入错误,请输入正确的数字(1-6)!"${END}
            ;;
        esac
    done
}

centos_menu(){
    while true;do
        echo -e "\E[$[RANDOM%7+31];1m"
        cat <<-EOF
1)base仓库
2)epel仓库
3)CentOS Stream 9 crb仓库
4)CentOS Stream 8 PowerTools仓库
5)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-5): " NUM
        case ${NUM} in
        1)
            if [ ${OS_NAME} == "Stream" ];then
                if [ ${OS_RELEASE_VERSION} == "8" ];then
                    centos_stream_8_base_menu
                else
                    centos_stream_9_base_menu
                fi
            else
                centos_7_base_menu
            fi
            ;;
        2)
            if [ ${OS_RELEASE_VERSION} == "7" ];then
                centos_7_epel_menu
            else
                rocky_almalinux_centos_8_9_epel_menu
            fi
            ;;
        3)
            if [ ${OS_RELEASE_VERSION} == "9" ];then
                centos_stream_9_crb_menu
            else
                ${COLOR}"${OS_ID} ${OS_RELEASE} 没有crb源，不用设置!"${END}
            fi
            ;;
        4)
            if [ ${OS_RELEASE_VERSION} == "8" ];then
                centos_stream_8_powertools_menu
            else
                ${COLOR}"${OS_ID} ${OS_RELEASE} 没有powertools源，不用设置!"${END}
            fi
            ;;
        5)
            break
            ;;
        *)
            ${COLOR}"输入错误,请输入正确的数字(1-5)!"${END}
            ;;
        esac
    done
}

set_ubuntu_apt(){
    if [ ${OS_RELEASE_VERSION} == "18" -o ${OS_RELEASE_VERSION} == "20" -o ${OS_RELEASE_VERSION} == "22" ];then
        mv /etc/apt/sources.list /etc/apt/sources.list.bak
        cat > /etc/apt/sources.list <<-EOF
deb http://${MIRROR}/ubuntu/ $(lsb_release -cs) main restricted universe multiverse
deb-src http://${MIRROR}/ubuntu/ $(lsb_release -cs) main restricted universe multiverse

deb http://${MIRROR}/ubuntu/ $(lsb_release -cs)-security main restricted universe multiverse
deb-src http://${MIRROR}/ubuntu/ $(lsb_release -cs)-security main restricted universe multiverse

deb http://${MIRROR}/ubuntu/ $(lsb_release -cs)-updates main restricted universe multiverse
deb-src http://${MIRROR}/ubuntu/ $(lsb_release -cs)-updates main restricted universe multiverse

deb http://${MIRROR}/ubuntu/ $(lsb_release -cs)-proposed main restricted universe multiverse
deb-src http://${MIRROR}/ubuntu/ $(lsb_release -cs)-proposed main restricted universe multiverse

deb http://${MIRROR}/ubuntu/ $(lsb_release -cs)-backports main restricted universe multiverse
deb-src http://${MIRROR}/ubuntu/ $(lsb_release -cs)-backports main restricted universe multiverse
EOF
    else
        mv /etc/apt/sources.list.d/ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources.bak
        cat > /etc/apt/sources.list.d/ubuntu.sources <<-EOF
Types: deb
URIs: https://${MIRROR}/ubuntu
Suites: $(lsb_release -cs) $(lsb_release -cs)-updates $(lsb_release -cs)-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: https://${MIRROR}/ubuntu
Suites: $(lsb_release -cs)-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF
    fi
    ${COLOR}"更新镜像源中,请稍等..."${END}
    apt update &> /dev/null
    ${COLOR}"${OS_ID} ${OS_RELEASE} APT源设置完成!"${END}
}

apt_menu(){
    while true;do
        echo -e "\E[$[RANDOM%7+31];1m"
        cat <<-EOF
1)阿里镜像源
2)华为镜像源
3)腾讯镜像源
4)清华镜像源
5)网易镜像源
6)搜狐镜像源
7)南京大学镜像源
8)中科大镜像源
9)上海交通大学镜像源
10)西安交通大学镜像源
11)北京外国语大学镜像源
12)北京交通大学镜像源
13)北京大学镜像源
14)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-14): " NUM
        case ${NUM} in
        1)
            aliyun
            set_ubuntu_apt
            ;;
        2)
            huawei
            set_ubuntu_apt
            ;;
        3)
            tencent
            set_ubuntu_apt
            ;;
        4)
            tuna
            set_ubuntu_apt
            ;;
        5)
            netease
            set_ubuntu_apt
            ;;
        6)
            sohu
            set_ubuntu_apt
            ;;
        7)
            nju
            set_ubuntu_apt
            ;;
        8)
            ustc
            set_ubuntu_apt
            ;;
        9)
            sjtu
            set_ubuntu_apt
            ;;
        10)
            xjtu
            set_ubuntu_apt
            ;;
        11)
            bfsu
            set_ubuntu_apt
            ;;
        12)
            bjtu
            set_ubuntu_apt
            ;;
        13)
            pku
            set_ubuntu_apt
            ;;

        14)
            break
            ;;
        *)
            ${COLOR}"输入错误,请输入正确的数字(1-14)!"${END}
            ;;
        esac
    done
}

set_debian_apt(){
    mv /etc/apt/sources.list /etc/apt/sources.list.bak
    cat > /etc/apt/sources.list <<-EOF
deb https://${MIRROR}/debian/ $(lsb_release -cs) main contrib non-free non-free-firmware
# deb-src https://${MIRROR}/debian/ $(lsb_release -cs) main contrib non-free non-free-firmware

deb https://${MIRROR}/debian/ $(lsb_release -cs)-updates main contrib non-free non-free-firmware
# deb-src https://${MIRROR}/debian/ $(lsb_release -cs)-updates main contrib non-free non-free-firmware

deb https://${MIRROR}/debian/ $(lsb_release -cs)-backports main contrib non-free non-free-firmware
# deb-src https://${MIRROR}/debian/ $(lsb_release -cs)-backports main contrib non-free non-free-firmware

deb https://${MIRROR}/debian-security $(lsb_release -cs)-security main contrib non-free non-free-firmware
# deb-src https://${MIRROR}/debian-security $(lsb_release -cs)-security main contrib non-free non-free-firmware
EOF
    ${COLOR}"更新镜像源中,请稍等..."${END}
    apt update &> /dev/null
    ${COLOR}"${OS_ID} ${OS_RELEASE} APT源设置完成!"${END}
}

debian_menu(){
    while true;do
        echo -e "\E[$[RANDOM%7+31];1m"
        cat <<-EOF
1)阿里镜像源
2)华为镜像源
3)腾讯镜像源
4)清华镜像源
5)网易镜像源
6)搜狐镜像源
7)南京大学镜像源
8)中科大镜像源
9)上海交通大学镜像源
10)西安交通大学镜像源
11)北京外国语大学镜像源
12)北京交通大学镜像源
13)北京大学镜像源
14)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-14): " NUM
        case ${NUM} in
        1)
            aliyun
            set_debian_apt
            ;;
        2)
            huawei
            set_debian_apt
            ;;
        3)
            tencent
            set_debian_apt
            ;;
        4)
            tuna
            set_debian_apt
            ;;
        5)
            netease
            set_debian_apt
            ;;
        6)
            sohu
            set_debian_apt
            ;;
        7)
            nju
            set_debian_apt
            ;;
        8)
            ustc
            set_debian_apt
            ;;
        9)
            sjtu
            set_debian_apt
            ;;
        10)
            xjtu
            set_debian_apt
            ;;
        11)
            bfsu
            set_debian_apt
            ;;
        12)
            bjtu
            set_debian_apt
            ;;
        13)
            pku
            set_debian_apt
            ;;
        14)
            break
            ;;
        *)
            ${COLOR}"输入错误,请输入正确的数字(1-14)!"${END}
            ;;
        esac
    done
}

set_mirror_repository(){
    if [ ${OS_ID} == "Rocky" ];then
        rocky_menu
    elif [ ${OS_ID} == "AlmaLinux" ];then
        almalinux_menu
    elif [ ${OS_ID} == "CentOS" ];then
        centos_menu
    elif [ ${OS_ID} == "Ubuntu" ];then
        apt_menu
    else
        debian_menu
    fi
}

rocky_almalinux_centos_minimal_install(){
    ${COLOR}'开始安装“Minimal安装建议安装软件包”,请稍等......'${END}
    yum -y install gcc make autoconf gcc-c++ glibc glibc-devel pcre pcre-devel openssl openssl-devel systemd-devel zlib-devel vim lrzsz tree tmux lsof tcpdump wget net-tools iotop bc bzip2 zip unzip nfs-utils man-pages &> /dev/null
    ${COLOR}"${OS_ID} ${OS_RELEASE} Minimal安装建议安装软件包已安装完成!"${END}
}

ubuntu_debian_minimal_install(){
    ${COLOR}'开始安装“Minimal安装建议安装软件包”,请稍等......'${END}
    apt -y install iproute2 ntpdate tcpdump telnet traceroute nfs-kernel-server nfs-common lrzsz tree openssl libssl-dev libpcre3 libpcre3-dev zlib1g-dev gcc openssh-server iotop unzip zip
    ${COLOR}"${OS_ID} ${OS_RELEASE} Minimal安装建议安装软件包已安装完成!"${END}
}

minimal_install(){
    if [ ${OS_ID} == "Rocky" -o ${OS_ID} == "AlmaLinux" -o ${OS_ID} == "CentOS" ];then
        rocky_almalinux_centos_minimal_install
    else
        ubuntu_debian_minimal_install
    fi
}

disable_firewalls(){
    if [ ${OS_ID} == "Rocky" -o ${OS_ID} == "AlmaLinux" -o ${OS_ID} == "CentOS" ];then
        rpm -q firewalld &> /dev/null && { systemctl disable --now firewalld &> /dev/null; ${COLOR}"${OS_ID} ${OS_RELEASE} Firewall防火墙已关闭!"${END}; } || ${COLOR}"${OS_ID} ${OS_RELEASE} iptables防火墙已关闭!"${END}
    elif [ ${OS_ID} == "Ubuntu" ];then
        dpkg -s ufw &> /dev/null && { systemctl disable --now ufw &> /dev/null; ${COLOR}"${OS_ID} ${OS_RELEASE} ufw防火墙已关闭!"${END}; } || ${COLOR}"${OS_ID} ${OS_RELEASE}  没有ufw防火墙服务,不用关闭！"${END}
    else
        ${COLOR}"${OS_ID} ${OS_RELEASE}  没有安装防火墙服务,不用关闭！"${END}
    fi
}

disable_selinux(){
    if [ ${OS_ID} == "Rocky" -o ${OS_ID} == "AlmaLinux" -o ${OS_ID} == "CentOS" ];then
        if [ `getenforce` == "Enforcing" ];then
            sed -ri.bak 's/^(SELINUX=).*/\1disabled/' /etc/selinux/config
            setenforce 0
            ${COLOR}"${OS_ID} ${OS_RELEASE} SELinux已禁用,请重新启动系统后才能永久生效!"${END}
        else
            ${COLOR}"${OS_ID} ${OS_RELEASE} SELinux已被禁用,不用设置!"${END}
        fi
    else
        ${COLOR}"${OS_ID} ${OS_RELEASE} SELinux默认没有安装,不用设置!"${END}
    fi
}

set_swap(){
    sed -ri 's/.*swap.*/#&/' /etc/fstab
    if [ ${OS_ID} == "Ubuntu" ];then
        if [ ${OS_RELEASE_VERSION} == 20 -o ${OS_RELEASE_VERSION} == 22 -o ${OS_RELEASE_VERSION} == 24 ];then
            SD_NAME=`lsblk|awk -F"[ └─]" '/SWAP/{printf $3}'`
            systemctl mask dev-${SD_NAME}.swap &> /dev/null
        fi
    fi
    swapoff -a
    ${COLOR}"${OS_ID} ${OS_RELEASE} 禁用swap成功!"${END}
}

set_localtime(){
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    echo 'Asia/Shanghai' >/etc/timezone
    if [ ${OS_ID} == "Ubuntu" ];then
        cat >> /etc/default/locale <<-EOF
LC_TIME=en_DK.UTF-8
EOF
    fi
    ${COLOR}"${OS_ID} ${OS_RELEASE} 系统时区已设置成功,请重启系统后生效!"${END}
}

set_limits(){
    cat >> /etc/security/limits.conf <<-EOF
root     soft   core     unlimited
root     hard   core     unlimited
root     soft   nproc    1000000
root     hard   nproc    1000000
root     soft   nofile   1000000
root     hard   nofile   1000000
root     soft   memlock  32000
root     hard   memlock  32000
root     soft   msgqueue 8192000
root     hard   msgqueue 8192000
EOF
    ${COLOR}"${OS_ID} ${OS_RELEASE} 优化资源限制参数成功!"${END}
}

set_kernel(){
    modprobe  br_netfilter
    cat > /etc/sysctl.conf <<-EOF
# Controls source route verification
net.ipv4.conf.default.rp_filter = 1
net.ipv4.ip_nonlocal_bind = 1
net.ipv4.ip_forward = 1

# Do not accept source routing
net.ipv4.conf.default.accept_source_route = 0

# Controls the System Request debugging functionality of the kernel
kernel.sysrq = 0

# Controls whether core dumps will append the PID to the core filename.
# Useful for debugging multi-threaded applications.
kernel.core_uses_pid = 1

# Controls the use of TCP syncookies
net.ipv4.tcp_syncookies = 1

# Disable netfilter on bridges.
net.bridge.bridge-nf-call-ip6tables = 0
net.bridge.bridge-nf-call-iptables = 0
net.bridge.bridge-nf-call-arptables = 0

# Controls the default maxmimum size of a mesage queue
kernel.msgmnb = 65536

# Controls the maximum size of a message, in bytes
kernel.msgmax = 65536

# Controls the maximum shared segment size, in bytes
kernel.shmmax = 68719476736

# Controls the maximum number of shared memory segments, in pages
kernel.shmall = 4294967296

# TCP kernel paramater
net.ipv4.tcp_mem = 786432 1048576 1572864
net.ipv4.tcp_rmem = 4096        87380   4194304
net.ipv4.tcp_wmem = 4096        16384   4194304
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_sack = 1

# socket buffer
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 262144
net.core.somaxconn = 20480
net.core.optmem_max = 81920

# TCP conn
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_syn_retries = 3
net.ipv4.tcp_retries1 = 3
net.ipv4.tcp_retries2 = 15

# tcp conn reuse
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_timestamps = 0

net.ipv4.tcp_max_tw_buckets = 20000
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syncookies = 1

# keepalive conn
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.ip_local_port_range = 10001    65000

# swap
vm.overcommit_memory = 0
vm.swappiness = 10

#net.ipv4.conf.eth1.rp_filter = 0
#net.ipv4.conf.lo.arp_ignore = 1
#net.ipv4.conf.lo.arp_announce = 2
#net.ipv4.conf.all.arp_ignore = 1
#net.ipv4.conf.all.arp_announce = 2
EOF
    MAIN_KERNEL=`uname -r | cut -d. -f1`
    SUB_KERNEL=`uname -r | cut -d. -f2`
    if [ ${MAIN_KERNEL} -lt "4" -a ${SUB_KERNEL} -lt "12" ];then
    cat >> /etc/sysctl.conf <<-EOF	
net.ipv4.tcp_tw_recycle = 0
EOF
    fi
    sysctl -p &> /dev/null
    ${COLOR}"${OS_ID} ${OS_RELEASE} 优化内核参数成功!"${END}
}

optimization_ssh(){
    if [ ${OS_ID} == "Rocky" -o ${OS_ID} == "AlmaLinux" -o ${OS_ID} == "CentOS" ];then
        sed -ri.bak -e 's/^#(UseDNS).*/\1 no/' -e 's/^(GSSAPIAuthentication).*/\1 no/' /etc/ssh/sshd_config
    else
        sed -ri.bak -e 's/^#(UseDNS).*/\1 no/' -e 's/^#(GSSAPIAuthentication).*/\1 no/' /etc/ssh/sshd_config
    fi
    if [ ${OS_ID} == "Ubuntu" ];then
        if [ ${OS_RELEASE_VERSION} == 24 ];then
            systemctl restart ssh
        fi
    else
        systemctl restart sshd
    fi
    ${COLOR}"${OS_ID} ${OS_RELEASE} SSH已优化完成!"${END}
}

set_ssh_port(){
    disable_selinux
    disable_firewalls
    read -p "请输入端口号: " PORT
    sed -i 's/#Port 22/Port '${PORT}'/' /etc/ssh/sshd_config
    if [ ${OS_ID} == "Ubuntu" ];then
        if [ ${OS_RELEASE_VERSION} == 24 ];then
            systemctl restart ssh
        fi
    else
        systemctl restart sshd
    fi
    ${COLOR}"${OS_ID} ${OS_RELEASE} 更改SSH端口号已完成,请重新登陆后生效!"${END}
}

set_rocky_almalinux_centos_alias(){
    ETHNAME=`ip addr | awk -F"[ :]" '/^2/{print $3}'`
    ETHNAME2=`ip addr | awk -F"[ :]" '/^3/{print $3}'`
    IP_NUM=`ip addr | awk -F"[: ]" '{print $1}' | grep -v '^$' | wc -l`
    if [ ${IP_NUM} == "2" ];then
        if [ ${OS_RELEASE_VERSION} == "7" -o ${OS_RELEASE_VERSION} == "8" ];then
            cat >>~/.bashrc <<-EOF
alias cdnet="cd /etc/sysconfig/network-scripts"
alias cdrepo="cd /etc/yum.repos.d"
alias vie0="vim /etc/sysconfig/network-scripts/ifcfg-${ETHNAME}"
EOF
        else
            cat >>~/.bashrc <<-EOF
alias cdnet="cd /etc/NetworkManager/system-connections"
alias cdrepo="cd /etc/yum.repos.d"
alias vie0="vim /etc/NetworkManager/system-connections/${ETHNAME}.nmconnection"
EOF
        fi
    else	
        if [ ${OS_RELEASE_VERSION} == "7" -o ${OS_RELEASE_VERSION} == "8" ];then
            cat >>~/.bashrc <<-EOF
alias cdnet="cd /etc/sysconfig/network-scripts"
alias cdrepo="cd /etc/yum.repos.d"
alias vie0="vim /etc/sysconfig/network-scripts/ifcfg-${ETHNAME}"
alias vie1="vim /etc/sysconfig/network-scripts/ifcfg-${ETHNAME2}"
EOF
        else
            cat >>~/.bashrc <<-EOF
alias cdnet="cd /etc/NetworkManager/system-connections"
alias cdrepo="cd /etc/yum.repos.d"
alias vie0="vim /etc/NetworkManager/system-connections/${ETHNAME}.nmconnection"
alias vie1="vim /etc/NetworkManager/system-connections/${ETHNAME2}.nmconnection"
EOF
        fi
    fi
    DISK_NAME=`lsblk|awk -F" " '/disk/{printf $1}' | cut -c1-4`
    if [ ${DISK_NAME} == "sda" ];then
        cat >>~/.bashrc <<-EOF
alias scandisk="echo '- - -' > /sys/class/scsi_host/host0/scan;echo '- - -' > /sys/class/scsi_host/host1/scan;echo '- - -' > /sys/class/scsi_host/host2/scan"
EOF
    fi
    ${COLOR}"${OS_ID} ${OS_RELEASE} 系统别名已设置成功,请重新登陆后生效!"${END}
}

set_ubuntu_alias(){
    cat >>~/.bashrc <<-EOF
alias cdnet="cd /etc/netplan"
alias cdapt="cd /etc/apt"
EOF
    ${COLOR}"${OS_ID} ${OS_RELEASE} 系统别名已设置成功,请重新登陆后生效!"${END}
}

set_debian_alias(){
    cat >>~/.bashrc <<-EOF
alias cdnet="cd /etc/network"
alias cdapt="cd /etc/apt"
EOF
    ${COLOR}"${OS_ID} ${OS_RELEASE} 系统别名已设置成功,请重新登陆后生效!"${END}
}

set_alias(){
    if [ ${OS_ID} == "Rocky" -o ${OS_ID} == "AlmaLinux" -o ${OS_ID} == "CentOS" ];then
        if grep -Eqi "(.*cdnet|.*cdrepo|.*vie0|.*vie1|.*scandisk)" ~/.bashrc;then
            sed -i -e '/.*cdnet/d'  -e '/.*cdrepo/d' -e '/.*vie0/d' -e '/.*vie1/d' -e '/.*scandisk/d' ~/.bashrc
            set_rocky_almalinux_centos_alias
        else
            set_rocky_almalinux_centos_alias
        fi
    elif [ ${OS_ID} == "Ubuntu" ];then
        if grep -Eqi "(.*cdnet|.*cdapt)" ~/.bashrc;then
            sed -i -e '/.*cdnet/d' -e '/.*cdapt/d' ~/.bashrc
            set_ubuntu_alias
        else
            set_ubuntu_alias
        fi
    else
        if grep -Eqi "(.*cdnet|.*cdapt)" ~/.bashrc;then
            sed -i -e '/.*cdnet/d' -e '/.*cdapt/d' ~/.bashrc
            set_debian_alias
        else
            set_debian_alias
        fi
    fi
}

set_vimrc(){
    read -p "请输入作者名: " AUTHOR
    read -p "请输入QQ号: " QQ
    read -p "请输入网址: " V_MIRROR
    cat >~/.vimrc <<-EOF
set ts=4
set expandtab
set ignorecase
set cursorline
set autoindent
autocmd BufNewFile *.sh exec ":call SetTitle()"
func SetTitle()
    if expand("%:e") == 'sh'
    call setline(1,"#!/bin/bash")
    call setline(2,"#")
    call setline(3,"#*********************************************************************************************")
    call setline(4,"#Author:        ${AUTHOR}")
    call setline(5,"#QQ:            ${QQ}")
    call setline(6,"#Date:          ".strftime("%Y-%m-%d"))
    call setline(7,"#FileName:      ".expand("%"))
    call setline(8,"#MIRROR:        ${V_MIRROR}")
    call setline(9,"#Description:   The test script")
    call setline(10,"#Copyright (C): ".strftime("%Y")." All rights reserved")
    call setline(11,"#*********************************************************************************************")
    call setline(12,"")
    endif
endfunc
autocmd BufNewFile * normal G
EOF
    ${COLOR}"${OS_ID} ${OS_RELEASE} vimrc设置完成,请重新系统启动才能生效!"${END}
}

set_mail(){                                                                                                 
    if [ ${OS_ID} == "Rocky" -o ${OS_ID} == "AlmaLinux" -o ${OS_ID} == "CentOS" ];then
        rpm -q postfix &> /dev/null || { ${COLOR}"安装postfix服务,请稍等..."${END};yum -y install postfix &> /dev/null; systemctl enable --now postfix &> /dev/null; }
        rpm -q mailx &> /dev/null || { ${COLOR}"安装mailx服务,请稍等..."${END};yum -y install mailx &> /dev/null; }
    else
        dpkg -s mailutils &> /dev/null || { ${COLOR}"安装mailutils服务,请稍等..."${END};apt -y install mailutils; }
    fi
    read -p "请输入邮箱地址: " MAIL
    read -p "请输入邮箱授权码: " AUTH
    SMTP=`echo ${MAIL} |awk -F"@" '{print $2}'`
    cat >~/.mailrc <<-EOF
set from=${MAIL}
set smtp=smtp.${SMTP}
set smtp-auth-user=${MAIL}
set smtp-auth-password=${AUTH}
set smtp-auth=login
set ssl-verify=ignore
EOF
    ${COLOR}"${OS_ID} ${OS_RELEASE} 邮件设置完成,请重新登录后才能生效!"${END}
}

red(){
    P_COLOR=31
}

green(){
    P_COLOR=32
}

yellow(){
    P_COLOR=33
}

blue(){
    P_COLOR=34
}

violet(){
    P_COLOR=35
}

cyan_blue(){
    P_COLOR=36
}

random_color(){
    P_COLOR="$[RANDOM%7+31]"
}

rocky_almalinux_centos_ps1(){
    C_PS1=$(echo "PS1='\[\e[1;${P_COLOR}m\][\u@\h \W]\\$ \[\e[0m\]'" >> ~/.bashrc)
}

ubuntu_debian_ps1(){
    U_PS1=$(echo 'PS1="\[\e[1;'''${P_COLOR}'''m\]${debian_chroot:+($debian_chroot)}\u@\h:\w\\$ \[\e[0m\]"' >> ~/.bashrc)
}

set_ps1_env(){
    if [ ${OS_ID} == "Rocky" -o ${OS_ID} == "AlmaLinux" -o ${OS_ID} == "CentOS" ];then
        if grep -Eqi "^PS1" ~/.bashrc;then
            sed -i '/^PS1/d' ~/.bashrc
            rocky_almalinux_centos_ps1
        else
            rocky_almalinux_centos_ps1
        fi
    else
        if grep -Eqi "^PS1" ~/.bashrc;then
            sed -i '/^PS1/d' ~/.bashrc
            ubuntu_debian_ps1
        else
            ubuntu_debian_ps1
        fi
    fi
}

set_ps1(){
    TIPS="${COLOR}${OS_ID} ${OS_RELEASE} PS1设置成功,请重新登录生效!${END}"
    while true;do
        echo -e "\E[$[RANDOM%7+31];1m"
        cat <<-EOF
1)31 红色
2)32 绿色
3)33 黄色
4)34 蓝色
5)35 紫色
6)36 青色
7)随机颜色
8)退出
EOF
        echo -e '\E[0m'

        read -p "请输入颜色编号(1-8): " NUM
        case ${NUM} in
        1)
            red
            set_ps1_env
            ${TIPS}
            ;;
        2)
            green
            set_ps1_env
            ${TIPS}
            ;;
        3)
            yellow
            set_ps1_env
            ${TIPS}
            ;;
        4)
            blue
            set_ps1_env
            ${TIPS}
            ;;
        5)
            violet
            set_ps1_env
            ${TIPS}
            ;;
        6)
            cyan_blue
            set_ps1_env
            ${TIPS}
            ;;
        7)
            random_color
            set_ps1_env
            ${TIPS}
            ;;
        8)
            break
            ;;
        *)
            ${COLOR}"输入错误,请输入正确的数字(1-8)!"${END}
            ;;
        esac
    done
}

set_vim(){
    echo "export EDITOR=vim" >> ~/.bashrc
}

set_vim_env(){
    if grep -Eqi ".*EDITOR" ~/.bashrc;then
        sed -i '/.*EDITOR/d' ~/.bashrc
        set_vim
    else
        set_vim
    fi
    ${COLOR}"${OS_ID} ${OS_RELEASE} 默认文本编辑器设置成功,请重新登录生效!"${END}
}

set_history(){
    echo 'export HISTTIMEFORMAT="%F %T "' >> ~/.bashrc 
}

set_history_env(){
    if grep -Eqi ".*HISTTIMEFORMAT" ~/.bashrc;then
        sed -i '/.*HISTTIMEFORMAT/d' ~/.bashrc
        set_history
    else
        set_history
    fi
    ${COLOR}"${OS_ID} ${OS_RELEASE} history格式设置成功,请重新登录生效!"${END}
}

disable_restart(){
    if [ -f /usr/lib/systemd/system/ctrl-alt-del.target ];then
        cp /usr/lib/systemd/system/ctrl-alt-del.target{,.bak}
        rm -f /usr/lib/systemd/system/ctrl-alt-del.target
        ${COLOR}"${OS_ID} ${OS_RELEASE} 禁用ctrl+alt+del重启处理成功!"${END}
    else
        ${COLOR}"${OS_ID} ${OS_RELEASE} 禁用ctrl+alt+del已处理!"${END}
    fi
}

set_ubuntu_debian_root_login(){
    if [ ${OS_ID} == "Ubuntu" -o ${OS_ID} == "Debian" ];then
        read -p "请输入密码: " PASSWORD
        echo ${PASSWORD} |sudo -S sed -ri 's@#(PermitRootLogin )prohibit-password@\1yes@' /etc/ssh/sshd_config
        if [ ${OS_ID} == "Ubuntu" ];then
            if [ ${OS_RELEASE_VERSION} == 24 ];then
                sudo systemctl restart ssh
	        fi
        else
            sudo systemctl restart sshd
        fi
        sudo -S passwd root <<-EOF
${PASSWORD}
${PASSWORD}
EOF
        ${COLOR}"${OS_ID} ${OS_RELEASE} root用户登录已设置完成,请重新登录后生效!"${END}
    else
        ${COLOR}"${OS_ID} ${OS_RELEASE} 系统不可用!"${END}
    fi
}

ubuntu_remove(){
    if [ ${OS_ID} == "Ubuntu" ];then
        apt -y purge ufw lxd lxd-client lxcfs liblxc-common
        ${COLOR}"${OS_ID} ${OS_RELEASE} 无用软件包卸载完成!"${END}
    else
        ${COLOR}"${OS_ID} ${OS_RELEASE} 系统不可用!"${END}
    fi
}

ubuntu_20_22_24_remove_snap(){
    dpkg -s snapd &> /dev/null
    if [ $? -eq 1 ];then 
        ${COLOR}"${OS_ID} ${OS_RELEASE} snap已卸载！"${END}
    else
        systemctl disable snapd.service && systemctl disable snapd.socket && systemctl disable snapd.seeded.service
    
        sum=$(snap list | awk 'NR>=2{print $1}' | wc -l)
        while [ $sum -ne 0 ];do
            for p in $(snap list | awk 'NR>=2{print $1}'); do
                snap remove --purge $p
            done
            sum=$(snap list | awk 'NR>=2{print $1}' | wc -l)
        done
        
        apt -y autoremove --purge snapd
        
        rm -rf ~/snap && sudo rm -rf /snap && rm -rf /var/snap && rm -rf /var/lib/snapd && rm -rf /var/cache/snapd
        
        cat > /etc/apt/preferences.d/no-snapd.pref << EOF
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF
        apt update
        ${COLOR}"${OS_ID} ${OS_RELEASE} snap卸载完成!"${END}
    fi
}

ubuntu_remove_snap(){
    if [ ${OS_ID} == "Ubuntu" ];then
        if [ ${OS_RELEASE_VERSION} == 20 -o ${OS_RELEASE_VERSION} == 22 -o ${OS_RELEASE_VERSION} == 24 ];then
            ubuntu_20_22_24_remove_snap
        else
           ${COLOR}"${OS_ID} ${OS_RELEASE} 默认没有安装snap!"${END} 
        fi
    else
        ${COLOR}"${OS_ID} ${OS_RELEASE} 系统不可用!"${END}
    fi
}

menu(){
    while true;do
        echo -e "\E[$[RANDOM%7+31];1m"
        cat <<-EOF
******************************************************************
*                     系统初始化脚本菜单                         *
* 1.修改网卡名                 15.设置系统别名                   *
* 2.设置网络(单网卡)           16.设置vimrc配置文件              *
* 3.设置网络(双网卡)           17.安装邮件服务并配置邮件         *
* 4.设置主机名                 18.设置PS1(请进入选择颜色)        *
* 5.设置镜像仓库               19.设置默认文本编辑器为vim        *
* 6.Minimal安装建议安装软件    20.设置history格式                *
* 7.关闭防火墙                 21.禁用ctrl+alt+del重启           *
* 8.禁用SELinux                22.Ubuntu和Debian设置root用户登录 *
* 9.禁用SWAP                   23.Ubuntu卸载无用软件包           *
* 10.设置系统时区              24.Ubuntu卸载snap                 *
* 11.优化资源限制参数          25.重启系统                       *
* 12.优化内核参数              26.关机                           *
* 13.优化SSH                   27.退出                           *
* 14.更改SSH端口号                                               *
******************************************************************
EOF
        echo -e '\E[0m'

        read -p "请选择相应的编号(1-27): " choice
        case ${choice} in
        1)
            set_eth
            ;;
        2)
            set_network
            ;;
        3)
            set_dual_network
            ;;
        4)
            set_hostname
            ;;
        5)
            set_mirror_repository
            ;;
        6)
            minimal_install
            ;;
        7)
            disable_firewalls
            ;;
        8)
            disable_selinux
            ;;
        9)
            set_swap
            ;;
        10)
            set_localtime
            ;;
        11)
            set_limits
            ;;
        12)
            set_kernel
            ;;
        13)
            optimization_ssh
            ;;
        14)
            set_ssh_port
            ;;
        15)
            set_alias
            ;;
        16)
            set_vimrc
            ;;
        17)
            set_mail
            ;;
        18)
            set_ps1
            ;;
        19)
            set_vim_env
            ;;
        20)
            set_history_env
            ;;
        21)
            disable_restart
            ;;
        22)
            set_ubuntu_debian_root_login
            ;;
        23)
            ubuntu_remove
            ;;
        24)
            ubuntu_remove_snap
            ;;
        25)
            reboot
            ;;
        26)
            shutdown -h now
            ;;
        27)
            break
            ;;
        *)
            ${COLOR}"输入错误,请输入正确的数字(1-27)!"${END}
            ;;
        esac
    done
}

main(){
    os
    if [ ${OS_ID} == "Rocky" -o ${OS_ID} == "AlmaLinux" -o ${OS_ID} == "CentOS" -o ${OS_ID} == "Ubuntu" -o ${OS_ID} == "Debian" ];then
        menu
    else
        ${COLOR}"此脚本不支持${OS_ID} ${OS_RELEASE} 系统!"${END}
    fi
}

main
