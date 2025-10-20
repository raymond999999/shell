#!/bin/bash
#
#**********************************************************************************
#Author:        Raymond
#QQ:            88563128
#MP:            Raymond运维
#Date:          2025-10-20
#FileName:      reset_v10.sh
#URL:           https://wx.zsxq.com/group/15555885545422
#Description:   The reset linux system initialization script supports 
#               “Rocky Linux 8, 9 and 10, Almalinux 8, 9 and 10,
#               CentOS 7, CentOS Stream 8, 9 and 10,
#               Ubuntu Server 18.04, 20.04, 22.04 and 24.04 LTS,
#               Debian 11 , 12 and 13“ operating systems.
#Copyright (C): 2025 All rights reserved
#**********************************************************************************
COLOR="echo -e \\033[01;31m"
END='\033[0m'
LOGIN_USER=`whoami`

os(){
    . /etc/os-release
    MAIN_NAME=`sed -rn '/^NAME=/s@.*="([[:alpha:]]+).*"$@\1@p' /etc/os-release`
    if [ ${MAIN_NAME} == "Kylin" ];then
        MAIN_VERSION_ID=`sed -rn '/^VERSION_ID=/s@.*="([[:alpha:]]+)(.*)"$@\2@p' /etc/os-release`
    else
        MAIN_VERSION_ID=`sed -rn '/^VERSION_ID=/s@.*="?([0-9]+)\.?.*"?@\1@p' /etc/os-release`
    fi
}

set_root_login(){
    read -p "请输入密码: " PASSWORD
    echo ${PASSWORD} |sudo -S sed -ri 's@#(PermitRootLogin )prohibit-password@\1yes@' /etc/ssh/sshd_config
    if [ ${MAIN_NAME} == "Ubuntu" ];then
        if [ ${MAIN_VERSION_ID} == 24 ];then
            sudo systemctl restart ssh
	    fi
    else
        sudo systemctl restart sshd
    fi
    sudo -S passwd root <<-EOF
${PASSWORD}
${PASSWORD}
EOF
    if [ ${MAIN_NAME} == "Ubuntu" ];then
        if [ ${MAIN_VERSION_ID} == 18 -o ${MAIN_VERSION_ID} == 20 -o ${MAIN_VERSION_ID} == 22 ];then
            ${COLOR}"${PRETTY_NAME}操作系统，root用户登录已设置完成，请重新启动系统后生效！"${END}
        else
            ${COLOR}"${PRETTY_NAME}操作系统，root用户登录已设置完成，请重新登录后生效！"${END}
        fi
    else
        ${COLOR}"${PRETTY_NAME}操作系统，root用户登录已设置完成，请重新登录后生效！"${END}
    fi
}

set_rocky_almalinux_centos_7_8_eth(){
    sed -ri.bak '/^GRUB_CMDLINE_LINUX=/s@"$@ net.ifnames=0 biosdevname=0"@' /etc/default/grub
    if lsblk | grep -q EFI;then
        EFI_DIR=`find /boot/efi/ -name "grub.cfg" | awk -F"/" '{print $5}'`
        grub2-mkconfig -o /boot/efi/EFI/${EFI_DIR}/grub.cfg >& /dev/null
    else
        grub2-mkconfig -o /boot/grub2/grub.cfg >& /dev/null
    fi
    ETHNAME=`ip addr | awk -F"[ :]" '/^2/{print $3}'`
    mv /etc/sysconfig/network-scripts/ifcfg-${ETHNAME} /etc/sysconfig/network-scripts/ifcfg-eth0
    sed -i.bak 's/'${ETHNAME}'/eth0/' /etc/sysconfig/network-scripts/ifcfg-eth0
}

set_rocky_almalinux_centos_9_10_eth0(){
    ETHNAME=`ip addr | awk -F"[ :]" '/^2/{print $3}'`
    ETHMAC=`ip addr show ${ETHNAME} | awk -F' ' '/ether/{print $2}'`
    mkdir -p /etc/systemd/network/
    touch /etc/systemd/network/70-eth0.link
    cat > /etc/systemd/network/70-eth0.link <<-EOF
[Match]
MACAddress=${ETHMAC}

[Link]
Name=eth0
EOF
    mv /etc/NetworkManager/system-connections/${ETHNAME}.nmconnection /etc/NetworkManager/system-connections/eth0.nmconnection
    sed -i.bak 's/'${ETHNAME}'/eth0/' /etc/NetworkManager/system-connections/eth0.nmconnection
}

set_rocky_almalinux_centos_9_10_eth1(){
    ETHNAME2=`ip addr | awk -F"[ :]" '/^3/{print $3}'`
    ETHMAC2=`ip addr show ${ETHNAME2} | awk -F' ' '/ether/{print $2}'`
    touch /etc/systemd/network/70-eth1.link
    cat > /etc/systemd/network/70-eth1.link <<-EOF
[Match]
MACAddress=${ETHMAC2}

[Link]
Name=eth1
EOF
}

set_rocky_almalinux_centos_eth(){
    if [ ${MAIN_VERSION_ID} == "7" -o ${MAIN_VERSION_ID} == "8" ];then
        if grep -Eqi "(net\.ifnames|biosdevname)" /etc/default/grub;then
            ${COLOR}"${PRETTY_NAME}操作系统，网卡名配置文件已修改，不用修改！"${END}
        else
            set_rocky_almalinux_centos_7_8_eth
	        ${COLOR}"${PRETTY_NAME}操作系统，网卡名已修改成功，10秒后，机器会自动重启！"${END}
            sleep 10 && shutdown -r now
        fi
    else
        IP_NUM=`ip addr | awk -F"[: ]" '{print $1}' | grep -v '^$' | wc -l`
        if [ ${IP_NUM} == "2" ];then
            if [ -f /etc/systemd/network/70-eth0.link ];then
                ${COLOR}"${PRETTY_NAME}操作系统，网卡名配置文件已修改，不用修改！"${END}
            else
                set_rocky_almalinux_centos_9_10_eth0
	            ${COLOR}"${PRETTY_NAME}操作系统，网卡名已修改成功，10秒后，机器会自动重启！"${END}
                sleep 10 && shutdown -r now
            fi
        else
            if [ -f /etc/systemd/network/70-eth0.link -a -f /etc/systemd/network/70-eth1.link ];then
                ${COLOR}"${PRETTY_NAME}操作系统，网卡名配置文件已修改，不用修改！"${END}
            else
                set_rocky_almalinux_centos_9_10_eth0
                set_rocky_almalinux_centos_9_10_eth1
	            ${COLOR}"${PRETTY_NAME}操作系统，网卡名已修改成功，10秒后，机器会自动重启！"${END}
                sleep 10 && shutdown -r now
            fi
        fi
    fi
}

set_ubuntu_debian_eth(){
    if grep -Eqi "(net\.ifnames|biosdevname)" /etc/default/grub;then
        ${COLOR}"${PRETTY_NAME}操作系统，网卡名配置文件已修改，不用修改！"${END}
    else
        sed -ri.bak '/^GRUB_CMDLINE_LINUX=/s@"$@net.ifnames=0 biosdevname=0"@' /etc/default/grub
        if lsblk | grep -q efi;then
            EFI_DIR=`find /boot/efi/ -name "grub.cfg" | awk -F"/" '{print $5}'`
            grub-mkconfig -o /boot/efi/EFI/${EFI_DIR}/grub.cfg >& /dev/null
        else
            grub-mkconfig -o /boot/grub/grub.cfg >& /dev/null
        fi
        ETHNAME=`ip addr | awk -F"[ :]" '/^2/{print $3}'`
        if [ ${MAIN_NAME} == "Ubuntu" ];then
		    if [ ${MAIN_VERSION_ID} == "18" ];then
                sed -i.bak 's/'${ETHNAME}'/eth0/' /etc/netplan/01-netcfg.yaml 
            elif [ ${MAIN_VERSION_ID} == "20" ];then
                sed -i.bak 's/'${ETHNAME}'/eth0/' /etc/netplan/00-installer-config.yaml
            elif [ ${MAIN_VERSION_ID} == "22" ];then
                touch /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
                cat > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg <<-EOF
network: {config: disabled}
EOF
                sed -i.bak 's/'${ETHNAME}'/eth0/' /etc/netplan/50-cloud-init.yaml
            else
                sed -i.bak 's/'${ETHNAME}'/eth0/' /etc/netplan/50-cloud-init.yaml
            fi
        else
            sed -i.bak 's/'${ETHNAME}'/eth0/' /etc/network/interfaces
        fi
	    ${COLOR}"${PRETTY_NAME}操作系统，网卡名已修改成功，10秒后,机器会自动重启！"${END}
        sleep 10 && shutdown -r now
    fi
}

set_eth(){
    ETH_PREFIX_NAME=`ip addr | awk -F"[ :]" '/^2/{print $3}' | tr -d "[:digit:]"`
    if [ ${ETH_PREFIX_NAME} == "eth" ];then
        ${COLOR}"${PRETTY_NAME}操作系统，网卡名已修改，不用设置！"${END}
    else
        if [ ${MAIN_NAME} == "Rocky" -o ${MAIN_NAME} == "AlmaLinux" -o ${MAIN_NAME} == "CentOS" ];then
            set_rocky_almalinux_centos_eth
        else
            set_ubuntu_debian_eth
        fi
    fi
}

check_ip(){
    local IP=$1
    VALID_CHECK=$(echo ${IP}|awk -F. '$1<=255&&$2<=255&&$3<=255&&$4<=255{print "yes"}')
    if echo ${IP}|grep -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$" >/dev/null; then
        if [ ${VALID_CHECK} == "yes" ]; then
            echo "IP ${IP} available!"
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

set_rocky_almalinux_centos_network_eth0(){
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
    if [ ${MAIN_VERSION_ID} == "7" -o ${MAIN_VERSION_ID} == "8" ];then
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
    else
        cat > /etc/NetworkManager/system-connections/${ETHNAME}.nmconnection <<-EOF
[connection]
id=${ETHNAME}
type=ethernet
interface-name=${ETHNAME}

[ipv4]
address1=${IP}/${PREFIX},${GATEWAY}
dns=${PRIMARY_DNS};${BACKUP_DNS};
method=manual
EOF
    fi
}

set_rocky_almalinux_centos_network_eth1(){
    ETHNAME2=`ip addr | awk -F"[ :]" '/^3/{print $3}'`
    while true; do
        read -p "请输入第二块网卡IP地址: " IP2
        check_ip ${IP2}
        [ $? -eq 0 ] && break
    done
    read -p "请输入子网掩码位数: " PREFIX2
    if [ ${MAIN_VERSION_ID} == "7" -o ${MAIN_VERSION_ID} == "8" ];then
        cat > /etc/sysconfig/network-scripts/ifcfg-${ETHNAME2} <<-EOF
NAME=${ETHNAME2}
DEVICE=${ETHNAME2}
ONBOOT=yes
BOOTPROTO=none
TYPE=Ethernet
IPADDR=${IP2}
PREFIX=${PREFIX2}
EOF
    else
        cat > /etc/NetworkManager/system-connections/${ETHNAME2}.nmconnection <<-EOF
[connection]
id=${ETHNAME2}
type=ethernet
interface-name=${ETHNAME2}

[ipv4]
address1=${IP2}/${PREFIX2}
method=manual
EOF
        chmod 600 /etc/NetworkManager/system-connections/${ETHNAME2}.nmconnection
    fi
}

set_ubuntu_network_eth0(){
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
    if [ ${MAIN_VERSION_ID} == "18" ];then
        cat > /etc/netplan/01-netcfg.yaml <<-EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    ${ETHNAME}:
      dhcp4: no
      dhcp6: no
      addresses: [${IP}/${PREFIX}] 
      gateway4: ${GATEWAY}
      nameservers:
        addresses: [${PRIMARY_DNS}, ${BACKUP_DNS}]
EOF
    elif [ ${MAIN_VERSION_ID} == "20" ];then
        cat > /etc/netplan/00-installer-config.yaml <<-EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    ${ETHNAME}:
      dhcp4: no
      dhcp6: no
      addresses: [${IP}/${PREFIX}] 
      gateway4: ${GATEWAY}
      nameservers:
        addresses: [${PRIMARY_DNS}, ${BACKUP_DNS}]
EOF
    else
        if [ ${MAIN_VERSION_ID} == "22" ];then
            if [ ! -f /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg ];then
                touch /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
                cat > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg <<-EOF
network: {config: disabled}
EOF
            fi
        fi
        cat > /etc/netplan/50-cloud-init.yaml <<-EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    ${ETHNAME}:
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
}

set_ubuntu_network_eth1(){
    ETHNAME2=`ip addr | awk -F"[ :]" '/^3/{print $3}'`
    while true; do
        read -p "请输入第二块网卡IP地址: " IP2
        check_ip ${IP2}
        [ $? -eq 0 ] && break
    done
    read -p "请输入子网掩码位数: " PREFIX2
    if [ ${MAIN_VERSION_ID} == "18" ];then
        cat >> /etc/netplan/01-netcfg.yaml <<-EOF
    ${ETHNAME2}:
      dhcp4: no
      dhcp6: no
      addresses: [${IP2}/${PREFIX2}] 
EOF
    elif [ ${MAIN_VERSION_ID} == "20" ];then
        cat >> /etc/netplan/00-installer-config.yaml <<-EOF
    ${ETHNAME2}:
      dhcp4: no
      dhcp6: no
      addresses: [${IP2}/${PREFIX2}] 
EOF
    else
        cat >> /etc/netplan/50-cloud-init.yaml <<-EOF
    ${ETHNAME2}:
      dhcp4: no
      dhcp6: no
      addresses: [${IP2}/${PREFIX2}] 
EOF
    fi
}

set_debian_network_eth0(){
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
    sed -ri -e "s/allow-hotplug/auto/g" -e "s/dhcp/static/g" /etc/network/interfaces
    sed -i '/static/a\address '${IP}'/'${PREFIX}'\ngateway '${GATEWAY}'\ndns-nameservers '${PRIMARY_DNS}' '${BACKUP_DNS}'\n' /etc/network/interfaces
}

set_debian_network_eth1(){
    ETHNAME2=`ip addr | awk -F"[ :]" '/^3/{print $3}'`
    while true; do
        read -p "请输入第二块网卡IP地址: " IP2
        check_ip ${IP2}
        [ $? -eq 0 ] && break
    done
    read -p "请输入子网掩码位数: " PREFIX2
    cat >> /etc/network/interfaces <<-EOF

auto ${ETHNAME2}
iface ${ETHNAME2} inet static
address ${IP2}/${PREFIX2}
EOF
}

set_network(){
    IP_NUM=`ip addr | awk -F"[: ]" '{print $1}' | grep -v '^$' | wc -l`
    if [ ${MAIN_NAME} == "Rocky" -o ${MAIN_NAME} == "AlmaLinux" -o ${MAIN_NAME} == "CentOS" ];then
        if [ ${IP_NUM} == "2" ];then
            set_rocky_almalinux_centos_network_eth0
        else
            set_rocky_almalinux_centos_network_eth0
            set_rocky_almalinux_centos_network_eth1
        fi
    elif [ ${MAIN_NAME} == "Ubuntu" ];then
        if [ ${IP_NUM} == "2" ];then
            set_ubuntu_network_eth0
        else
            set_ubuntu_network_eth0
            set_ubuntu_network_eth1
        fi
    else
        if [ ${IP_NUM} == "2" ];then
            set_debian_network_eth0
        else
            set_debian_network_eth0
            set_debian_network_eth1
        fi
    fi
    ${COLOR}"${PRETTY_NAME}操作系统，网络已设置成功，请重新启动系统后生效！"${END}
}

set_hostname(){
    read -p "请输入主机名: " HOST
    hostnamectl set-hostname ${HOST}
    ${COLOR}"${PRETTY_NAME}操作系统，主机名设置成功，请重新登录生效！"${END}
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

zju(){
    MIRROR=mirrors.zju.edu.cn
}

lzu(){
    MIRROR=mirror.lzu.edu.cn
}

cqupt(){
    MIRROR=mirrors.cqupt.edu.cn
}

volces(){
    MIRROR=mirrors.volces.com
}

iscas(){
    MIRROR=mirror.iscas.ac.cn
}

set_yum_rocky_8_9_10(){
    MIRROR_URL=`echo ${MIRROR} | awk -F"." '{print $2}'`
    OLD_MIRROR=$(sed -rn '/^.*baseurl=/s@.*=http.*://(.*)/(.*)/\$releasever/.*/$@\1@p' /etc/yum.repos.d/[Rr]ocky*.repo | head -1)
    OLD_DIR=$(sed -rn '/^.*baseurl=/s@.*=http.*://(.*)/(.*)/\$releasever/.*/$@\2@p' /etc/yum.repos.d/[Rr]ocky*.repo | head -1)
    if [ ${MIRROR_URL} == "aliyun" -o ${MIRROR_URL} == "volces" ];then
        if [ ${OLD_DIR} == '$contentdir' ];then
            sed -i.bak -e 's|^mirrorlist=|#mirrorlist=|g' -e 's|^#baseurl=http://dl.rockylinux.org/$contentdir|baseurl=https://'${MIRROR}'/rockylinux|g' /etc/yum.repos.d/[Rr]ocky*.repo
        elif [ ${OLD_DIR} == 'rocky' ];then
            sed -i -e 's|^baseurl=https://'${OLD_MIRROR}'/rocky|baseurl=https://'${MIRROR}'/rockylinux|g' /etc/yum.repos.d/[Rr]ocky*.repo
        elif [ ${OLD_DIR} == 'Rocky' ];then
            sed -i -e 's|^baseurl=https://'${OLD_MIRROR}'/Rocky|baseurl=https://'${MIRROR}'/rockylinux|g' /etc/yum.repos.d/[Rr]ocky*.repo
        else
            sed -i -e 's|^baseurl=https://'${OLD_MIRROR}'/rockylinux|baseurl=https://'${MIRROR}'/rockylinux|g' /etc/yum.repos.d/[Rr]ocky*.repo
        fi
    elif [ ${MIRROR_URL} == "sohu" ];then
        if [ ${OLD_DIR} == '$contentdir' ];then
            sed -i.bak -e 's|^mirrorlist=|#mirrorlist=|g' -e 's|^#baseurl=http://'${OLD_MIRROR}'/$contentdir|baseurl=https://'${MIRROR}'/Rocky|g' /etc/yum.repos.d/[Rr]ocky*.repo
        elif [ ${OLD_DIR} == 'rockylinux' ];then
            sed -i -e 's|^baseurl=https://'${OLD_MIRROR}'/rockylinux|baseurl=https://'${MIRROR}'/Rocky|g' /etc/yum.repos.d/[Rr]ocky*.repo
        elif [ ${OLD_DIR} == 'rocky' ];then
            sed -i -e 's|^baseurl=https://'${OLD_MIRROR}'/rocky|baseurl=https://'${MIRROR}'/Rocky|g' /etc/yum.repos.d/[Rr]ocky*.repo 
        else
            sed -i -e 's|^baseurl=https://'${OLD_MIRROR}'/Rocky|baseurl=https://'${MIRROR}'/Rocky|g' /etc/yum.repos.d/[Rr]ocky*.repo
        fi	
    else
        if [ ${OLD_DIR} == '$contentdir' ];then
            sed -i.bak -e 's|^mirrorlist=|#mirrorlist=|g' -e 's|^#baseurl=http://'${OLD_MIRROR}'/$contentdir|baseurl=https://'${MIRROR}'/rocky|g' /etc/yum.repos.d/[Rr]ocky*.repo
        elif [ ${OLD_DIR} == 'rockylinux' ];then
            sed -i -e 's|^baseurl=https://'${OLD_MIRROR}'/rockylinux|baseurl=https://'${MIRROR}'/rocky|g' /etc/yum.repos.d/[Rr]ocky*.repo
        elif [ ${OLD_DIR} == 'Rocky' ];then
            sed -i -e 's|^baseurl=https://'${OLD_MIRROR}'/Rocky|baseurl=https://'${MIRROR}'/rocky|g' /etc/yum.repos.d/[Rr]ocky*.repo 
        else
            sed -i -e 's|^baseurl=https://'${OLD_MIRROR}'/rocky|baseurl=https://'${MIRROR}'/rocky|g' /etc/yum.repos.d/[Rr]ocky*.repo
        fi
    fi
    ${COLOR}"更新镜像源中，请稍等......"${END}
    dnf clean all &> /dev/null && dnf makecache &> /dev/null
    ${COLOR}"${PRETTY_NAME}操作系统，镜像源设置完成！"${END}
}

rocky_8_9_10_base_menu(){
    while true;do
        echo -e "\E[$[RANDOM%7+31];1m"
        cat <<-EOF
1)阿里镜像源
2)腾讯镜像源
3)网易镜像源
4)搜狐镜像源
5)南京大学镜像源
6)中国科学技术大学镜像源
7)上海交通大学镜像源
8)西安交通大学镜像源
9)北京大学镜像源
10)浙江大学镜像源
11)兰州大学镜像源
12)火山引擎镜像源
13)中国科学院软件研究所镜像源
14)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-14): " NUM
        case ${NUM} in
        1)
            aliyun
            set_yum_rocky_8_9_10
            ;;
        2)
            tencent
            set_yum_rocky_8_9_10
            ;;
        3)
            netease
            set_yum_rocky_8_9_10
            ;;
        4)
            sohu
            set_yum_rocky_8_9_10
            ;;
        5)
            nju
            set_yum_rocky_8_9_10
            ;;
        6)
            ustc
            set_yum_rocky_8_9_10
            ;;
        7)
            sjtu
            set_yum_rocky_8_9_10
            ;;
        8)
            xjtu
            set_yum_rocky_8_9_10
            ;;
        9)
            pku
            set_yum_rocky_8_9_10
            ;;
        10)
            zju
            set_yum_rocky_8_9_10
            ;;
        11)
            lzu
            set_yum_rocky_8_9_10
            ;;
        12)
            volces
            set_yum_rocky_8_9_10
            ;;
        13)
            iscas
            set_yum_rocky_8_9_10
            ;;
        14)
            break
            ;;
        *)
            ${COLOR}"输入错误，请输入正确的数字(1-14)！"${END}
            ;;
        esac
    done
}

set_devel_rocky_9_10(){
    dnf config-manager --set-enabled devel
    ${COLOR}"更新镜像源中，请稍等......"${END}
    dnf clean all &> /dev/null && dnf makecache &> /dev/null
    ${COLOR}"${PRETTY_NAME}操作系统，devel仓库镜像源设置完成！"${END}
}

set_powertools_rocky_almalinux_centos_8(){
    dnf config-manager --set-enabled powertools
    ${COLOR}"更新镜像源中，请稍等......"${END}
    dnf clean all &> /dev/null && dnf makecache &> /dev/null
    ${COLOR}"${PRETTY_NAME}操作系统，PowerTools仓库镜像源设置完成！"${END}
}

set_yum_almalinux_8_9_10(){
    OLD_MIRROR=$(sed -rn '/^.*baseurl=/s@.*=http.*://(.*)/(.*)/\$releasever/.*/$@\1@p' /etc/yum.repos.d/almalinux*.repo | head -1)
    sed -i.bak -e 's|^mirrorlist=|#mirrorlist=|g' -e 's|^# baseurl=https://'${OLD_MIRROR}'|baseurl=https://'${MIRROR}'|g' /etc/yum.repos.d/almalinux*.repo
    ${COLOR}"更新镜像源中，请稍等......"${END}
    dnf clean all &> /dev/null && dnf makecache &> /dev/null
    ${COLOR}"${PRETTY_NAME}操作系统，镜像源设置完成！"${END}
}

almalinux_8_9_10_base_menu(){
    while true;do
        echo -e "\E[$[RANDOM%7+31];1m"
        cat <<-EOF
1)阿里镜像源
2)腾讯镜像源
3)南京大学镜像源
4)上海交通大学镜像源
5)北京大学镜像源
6)浙江大学镜像源
7)兰州大学镜像源
8)重庆邮电大学镜像源
9)火山引擎镜像源
10)中国科学院软件研究所镜像源
11)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-11): " NUM
        case ${NUM} in
        1)
            aliyun
            set_yum_almalinux_8_9_10
            ;;
        2)
            tencent
            set_yum_almalinux_8_9_10
            ;;
        3)
            nju
            set_yum_almalinux_8_9_10
            ;;
        4)
            sjtu
            set_yum_almalinux_8_9_10
            ;;
        5)
            pku
            set_yum_almalinux_8_9_10
            ;;
        6)
            zju
            set_yum_almalinux_8_9_10
            ;;
        7)
            lzu
            set_yum_almalinux_8_9_10
            ;;
        8)
            cqupt
            set_yum_almalinux_8_9_10
            ;;
        9)
            volces
            set_yum_almalinux_8_9_10
            ;;
        10)
            iscas
            set_yum_almalinux_8_9_10
            ;;
        11)
            break
            ;;
        *)
            ${COLOR}"输入错误，请输入正确的数字(1-11)！"${END}
            ;;
        esac
    done
}

set_devel_almalinux_9_10(){
    cat > /etc/yum.repos.d/devel.repo <<-EOF
[devel]
name=devel
baseurl=https://${MIRROR}/almalinux/\$releasever/devel/\$basearch/os
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9
EOF
    ${COLOR}"更新镜像源中，请稍等......"${END}
    dnf clean all &> /dev/null
    dnf makecache &> /dev/null
    ${COLOR}"${PRETTY_NAME}操作系统，devel仓库镜像源设置完成！"${END}
}

almalinux_9_10_devel_menu(){
    while true;do
        echo -e "\E[$[RANDOM%7+31];1m"
        cat <<-EOF
1)阿里镜像源
2)腾讯镜像源
3)南京大学镜像源
4)上海交通大学镜像源
5)北京大学镜像源
6)浙江大学镜像源
7)兰州大学镜像源
8)重庆邮电大学镜像源
9)火山引擎镜像源
10)中国科学院软件研究所镜像源
11)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-11): " NUM
        case ${NUM} in
        1)
            aliyun
            set_devel_almalinux_9_10
            ;;
        2)
            tencent
            set_devel_almalinux_9_10
            ;;
        3)
            nju
            set_devel_almalinux_9_10
            ;;
        4)
            sjtu
            set_devel_almalinux_9_10
            ;;
        5)
            pku
            set_devel_almalinux_9_10
            ;;
        6)
            zju
            set_devel_almalinux_9_10
            ;;
        7)
            lzu
            set_devel_almalinux_9_10
            ;;
        8)
            cqupt
            set_devel_almalinux_9_10
            ;;
        9)
            volces
            set_devel_almalinux_9_10
            ;;
        10)
            iscas
            set_devel_almalinux_9_10
            ;;
        11)
            break
            ;;
        *)
            ${COLOR}"输入错误，请输入正确的数字(1-11)！"${END}
            ;;
        esac
    done
}

set_crb_almalinux_centos_9_10(){
    dnf config-manager --set-enabled crb
    ${COLOR}"更新镜像源中，请稍等......"${END}
    dnf clean all &> /dev/null && dnf makecache &> /dev/null
    ${COLOR}"${PRETTY_NAME}操作系统，crb仓库镜像源设置完成！"${END}
}

set_yum_centos_stream_9_10_perl(){
    ${COLOR}"由于${PRETTY_NAME}操作系统，系统默认镜像源是Perl语言实现的，在更改镜像源之前先确保把'update_mirror.pl'文件和reset脚本放在同一个目录下，否则后面程序会退出，默认的${PRETTY_NAME}操作系统，镜像源设置的是阿里云，要修改镜像源，请去'update_mirror.pl'文件里修改url变量！"${END}
    sleep 10
    PERL_FILE=update_mirror.pl
    if [ ! -e ${PERL_FILE} ];then
        ${COLOR}"缺少${PERL_FILE}文件！"${END}
        exit
    else
        ${COLOR}"${PERL_FILE}文件已准备好，继续后续配置！"${END}       
    fi
    rpm -q perl &> /dev/null || { ${COLOR}"安装perl工具,请稍等..."${END};yum -y install perl &> /dev/null; }
    perl ./update_mirror.pl /etc/yum.repos.d/centos*.repo
    ${COLOR}"更新镜像源中，请稍等......"${END}
    dnf clean all &> /dev/null && dnf makecache &> /dev/null
    ${COLOR}"${PRETTY_NAME}操作系统，镜像源设置完成！"${END}
}

set_yum_centos_stream_9_10(){
    OLD_MIRROR=$(sed -rn '/^.*baseurl=/s@.*=http.*://(.*)/(.*)/\$releasever-stream/.*/$@\1@p' /etc/yum.repos.d/centos*.repo | head -1)
    sed -i -e 's|^baseurl=https://'${OLD_MIRROR}'|baseurl=https://'${MIRROR}'|g' /etc/yum.repos.d/centos*.repo
    ${COLOR}"更新镜像源中，请稍等......"${END}
    dnf clean all &> /dev/null && dnf makecache &> /dev/null
    ${COLOR}"${PRETTY_NAME}操作系统，镜像源设置完成！"${END}
}

centos_stream_9_10_base_menu(){
    while true;do
        echo -e "\E[$[RANDOM%7+31];1m"
        cat <<-EOF
1)阿里镜像源
2)华为镜像源
3)腾讯镜像源
4)清华镜像源
5)南京大学镜像源
6)中国科学技术大学镜像源
7)北京外国语大学镜像源
8)北京大学镜像源
9)重庆邮电大学镜像源
10)火山引擎镜像源
11)中国科学院软件研究所镜像源
12)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-12): " NUM
        case ${NUM} in
        1)
            aliyun
            set_yum_centos_stream_9_10
            ;;
        2)
            huawei
            set_yum_centos_stream_9_10
            ;;
        3)
            tencent
            set_yum_centos_stream_9_10
            ;;
        4)
            tuna
            set_yum_centos_stream_9_10
            ;;
        5)
            nju
            set_yum_centos_stream_9_10
            ;;
        6)
            ustc
            set_yum_centos_stream_9_10
            ;;
        7)
            bfsu
            set_yum_centos_stream_9_10
            ;;
        8)
            pku
            set_yum_centos_stream_9_10
            ;;
        9)
            cqupt
            set_yum_centos_stream_9_10
            ;;
        10)
            volces
            set_yum_centos_stream_9_10
            ;;
        11)
            iscas
            set_yum_centos_stream_9_10
            ;;
        12)
            break
            ;;
        *)
            ${COLOR}"输入错误，请输入正确的数字(1-12)！"${END}
            ;;
        esac
    done
}

set_yum_centos_stream_8(){
    OLD_MIRROR=$(sed -rn '/^.*baseurl=/s@.*=http.*://(.*)/(.*)/\$stream/.*/$@\1@p' /etc/yum.repos.d/CentOS-*.repo | head -1)
    OLD_DIR=$(sed -rn '/^.*baseurl=/s@.*=http.*://(.*)/(.*)/\$stream/.*/$@\2@p' /etc/yum.repos.d/CentOS-*.repo | head -1)
    if [ ${OLD_DIR} == '$contentdir' ];then
        sed -i.bak -e 's|^mirrorlist=|#mirrorlist=|g' -e 's|^#baseurl=http://mirror.centos.org/$contentdir|baseurl=https://'${MIRROR}'/centos-vault|g' /etc/yum.repos.d/CentOS-*.repo
    else
        sed -i -e 's|^baseurl=https://'${OLD_MIRROR}'|baseurl=https://'${MIRROR}'|g' /etc/yum.repos.d/CentOS-*.repo
    fi
    ${COLOR}"更新镜像源中，请稍等......"${END}
    dnf clean all &> /dev/null && dnf makecache &> /dev/null
    ${COLOR}"${PRETTY_NAME}操作系统，镜像源设置完成！"${END}
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
6)中国科学技术大学镜像源
7)北京外国语大学镜像源
8)北京大学镜像源
9)重庆邮电大学镜像源
10)火山引擎镜像源
11)中国科学院软件研究所镜像源
12)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-12): " NUM
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
        7)
            bfsu
            set_yum_centos_stream_8
            ;;
        8)
            pku
            set_yum_centos_stream_8
            ;;
        9)
            cqupt
            set_yum_centos_stream_8
            ;;
        10)
            volces
            set_yum_centos_stream_8
            ;;
        11)
            iscas
            set_yum_centos_stream_8
            ;;
        12)
            break
            ;;
        *)
            ${COLOR}"输入错误，请输入正确的数字(1-12)！"${END}
            ;;
        esac
    done
}

set_epel_rocky_almalinux_centos_8_9_10(){
    rpm -q epel-release &> /dev/null || { ${COLOR}"安装epel-release工具,请稍等..."${END};yum -y install epel-release &> /dev/null; }
    MIRROR_URL=`echo ${MIRROR} | awk -F"." '{print $2}'`
    OLD_MIRROR=$(awk -F'/' '/^baseurl=/{print $3}' /etc/yum.repos.d/epel*.repo | head -1)
    OLD_DIR=$(awk -F'/' '/^baseurl=/{print $4}' /etc/yum.repos.d/epel*.repo | head -1)
    if [ ${MIRROR_URL} == "sohu" ];then
        if grep -Eqi "^#baseurl" /etc/yum.repos.d/epel*.repo;then
            sed -i.bak -e 's|^metalink=|#metalink=|g' -e 's|^#baseurl=https://download.example/pub/epel|baseurl=https://'${MIRROR}'/fedora-epel|g' /etc/yum.repos.d/epel*.repo
        elif [ ${OLD_DIR} == 'epel' ];then
            sed -i -e 's|^baseurl=https://'${OLD_MIRROR}'/epel|baseurl=https://'${MIRROR}'/fedora-epel|g' /etc/yum.repos.d/epel*.repo
        elif [ ${OLD_DIR} == 'fedora' ];then
            sed -i -e 's|^baseurl=https://'${OLD_MIRROR}'/fedora/epel|baseurl=https://'${MIRROR}'/fedora-epel|g' /etc/yum.repos.d/epel*.repo
        else
            sed -i -e 's|^baseurl=https://'${OLD_MIRROR}'/fedora-epel|baseurl=https://'${MIRROR}'/fedora-epel|g' /etc/yum.repos.d/epel*.repo
        fi
    elif [ ${MIRROR_URL} == "sjtu" ];then
        if grep -Eqi "^#baseurl" /etc/yum.repos.d/epel*.repo;then
            sed -i.bak -e 's|^metalink=|#metalink=|g' -e 's|^#baseurl=https://download.example/pub/epel|baseurl=https://'${MIRROR}'/fedora/epel|g' /etc/yum.repos.d/epel*.repo
        elif [ ${OLD_DIR} == 'epel' ];then
            sed -i -e 's|^baseurl=https://'${OLD_MIRROR}'/epel|baseurl=https://'${MIRROR}'/fedora/epel|g' /etc/yum.repos.d/epel*.repo
        elif [ ${OLD_DIR} == 'fedora-epel' ];then
            sed -i -e 's|^baseurl=https://'${OLD_MIRROR}'/fedora-epel|baseurl=https://'${MIRROR}'/fedora/epel|g' /etc/yum.repos.d/epel*.repo
        else
            sed -i -e 's|^baseurl=https://'${OLD_MIRROR}'/fedora/epel|baseurl=https://'${MIRROR}'/fedora/epel|g' /etc/yum.repos.d/epel*.repo
        fi
    else
        if grep -Eqi "^#baseurl" /etc/yum.repos.d/epel*.repo;then
	        sed -i.bak -e 's|^metalink=|#metalink=|g' -e 's|^#baseurl=https://download.example/pub/epel|baseurl=https://'${MIRROR}'/epel|g' /etc/yum.repos.d/epel*.repo
        elif [ ${OLD_DIR} == 'fedora' ];then
            sed -i -e 's|^baseurl=https://'${OLD_MIRROR}'/fedora/epel|baseurl=https://'${MIRROR}'/epel|g' /etc/yum.repos.d/epel*.repo
        elif [ ${OLD_DIR} == 'fedora-epel' ];then
            sed -i -e 's|^baseurl=https://'${OLD_MIRROR}'/fedora-epel|baseurl=https://'${MIRROR}'/epel|g' /etc/yum.repos.d/epel*.repo
        else
            sed -i -e 's|^baseurl=https://'${OLD_MIRROR}'/epel|baseurl=https://'${MIRROR}'/epel|g' /etc/yum.repos.d/epel*.repo
        fi
    fi
    if [ ${MAIN_NAME} == "Rocky" -o ${MAIN_NAME} == "CentOS" ];then
        if [ ${MAIN_VERSION_ID} == "9" ];then
            dnf config-manager --set-disabled epel-cisco-openh264
        fi
    fi
    ${COLOR}"更新镜像源中，请稍等......"${END}
    dnf clean all &> /dev/null && dnf makecache &> /dev/null
    ${COLOR}"${PRETTY_NAME}操作系统，EPEL镜像源设置完成！"${END}
}

rocky_almalinux_centos_8_9_10_epel_menu(){
    while true;do
        echo -e "\E[$[RANDOM%7+31];1m"
        cat <<-EOF
1)阿里镜像源
2)华为镜像源
3)腾讯镜像源
4)清华镜像源
5)搜狐镜像源
6)南京大学镜像源
7)中国科学技术大学镜像源
8)上海交通大学镜像源
9)西安交通大学镜像源
9)北京外国语大学镜像源
11)北京大学镜像源
12)浙江大学镜像源
13)兰州大学镜像源
14)重庆邮电大学镜像源
15)火山引擎镜像源
16)中国科学院软件研究所镜像源
17)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-17): " NUM
        case ${NUM} in
        1)
            aliyun
            set_epel_rocky_almalinux_centos_8_9_10
            ;;
        2)
            huawei
            set_epel_rocky_almalinux_centos_8_9_10
            ;;
        3)
            tencent
            set_epel_rocky_almalinux_centos_8_9_10
            ;;
        4)
            tuna
            set_epel_rocky_almalinux_centos_8_9_10
            ;;
        5)
            sohu
            set_epel_rocky_almalinux_centos_8_9_10
            ;;
        6)
            nju
            set_epel_rocky_almalinux_centos_8_9_10
            ;;
        7)
            ustc
            set_epel_rocky_almalinux_centos_8_9_10
            ;;
        8)
            sjtu
            set_epel_rocky_almalinux_centos_8_9_10
            ;;
        9)
            xjtu
            set_epel_rocky_almalinux_centos_8_9_10
            ;;
        10)
            bfsu
            set_epel_rocky_almalinux_centos_8_9_10
            ;;
        11)
            pku
            set_epel_rocky_almalinux_centos_8_9_10
            ;;
        12)
            zju
            set_epel_rocky_almalinux_centos_8_9_10
            ;;
        13)
            lzu
            set_epel_rocky_almalinux_centos_8_9_10
            ;;
        14)
            cqupt
            set_epel_rocky_almalinux_centos_8_9_10
            ;;
        15)
            volces
            set_epel_rocky_almalinux_centos_8_9_10
            ;;
        16)
            iscas
            set_epel_rocky_almalinux_centos_8_9_10
            ;;
        17)
            break
            ;;
        *)
            ${COLOR}"输入错误，请输入正确的数字(1-17)！"${END}
            ;;
        esac
    done
}

set_yum_centos_7(){
    OLD_MIRROR=$(sed -rn '/^.*baseurl=/s@.*=(http.*)://(.*)/(.*)/\$releasever/.*/$@\2@p' /etc/yum.repos.d/CentOS-*.repo | head -1)
    OS_RELEASE_FULL_VERSION=`cat /etc/centos-release | sed -rn 's/^(CentOS Linux release )(.*)( \(Core\))/\2/p'`
    if grep -Eqi "^#baseurl" /etc/yum.repos.d/CentOS-*.repo;then
        sed -i.bak -e 's|^mirrorlist=|#mirrorlist=|g' -e 's|^#baseurl=http://mirror.centos.org/centos|baseurl=https://'${MIRROR}'/centos-vault|g' -e "s/\$releasever/${OS_RELEASE_FULL_VERSION}/g" /etc/yum.repos.d/CentOS-*.repo
    else
        sed -i -e 's|^baseurl=https://'${OLD_MIRROR}'|baseurl=https://'${MIRROR}'|g' /etc/yum.repos.d/CentOS-*.repo
    fi
    ${COLOR}"更新镜像源中，请稍等......"${END}
    yum clean all &> /dev/null && yum makecache &> /dev/null
    ${COLOR}"${PRETTY_NAME}操作系统，镜像源设置完成！"${END}
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
6)中国科学技术大学镜像源
7)北京外国语大学镜像源
8)北京大学镜像源
9)重庆邮电大学镜像源
10)火山引擎镜像源
11)中国科学院软件研究所镜像源
12)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-12): " NUM
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
            cqupt
            set_yum_centos_7
            ;;
        10)
            volces
            set_yum_centos_7
            ;;
        11)
            iscas
            set_yum_centos_7
            ;;
        12)
            break
            ;;
        *)
            ${COLOR}"输入错误，请输入正确的数字(1-12)！"${END}
            ;;
        esac
    done
}

set_epel_centos_7(){
    rpm -q epel-release &> /dev/null || { ${COLOR}"安装epel-release工具,请稍等..."${END};yum -y install epel-release &> /dev/null; }
    MIRROR_URL=`echo ${MIRROR} | awk -F"." '{print $2}'`
    OLD_MIRROR=$(awk -F'/' '/^baseurl=/{print $3}' /etc/yum.repos.d/epel*.repo | head -1)
    OLD_DIR=$(awk -F'/' '/^baseurl=/{print $4}' /etc/yum.repos.d/epel*.repo | head -1)
    if [ ${MIRROR_URL} == "aliyun" -o ${MIRROR_URL} == "tencent" ];then
        if grep -Eqi "^#baseurl" /etc/yum.repos.d/epel*.repo;then
	        sed -i.bak -e 's!^metalink=!#metalink=!g' -e 's!^#baseurl=!baseurl=!g' -e 's!https\?://download\.fedoraproject\.org/pub/epel!https://'${MIRROR}'/epel-archive!g' -e 's!https\?://download\.example/pub/epel!https://'${MIRROR}'/epel!g' /etc/yum.repos.d/epel*.repo
        elif [ ${OLD_DIR} == 'pub' ];then
            sed -i -e 's|^baseurl=https://'${OLD_MIRROR}'/pub/archive/epel|baseurl=https://'${MIRROR}'/epel-archive|g' /etc/yum.repos.d/epel*.repo
        else
            sed -i -e 's|^baseurl=https://'${OLD_MIRROR}'/epel-archive|baseurl=https://'${MIRROR}'/epel-archive|g' /etc/yum.repos.d/epel*.repo
        fi
    else
        if grep -Eqi "^#baseurl" /etc/yum.repos.d/epel*.repo;then
	        sed -i.bak -e 's!^metalink=!#metalink=!g' -e 's!^#baseurl=!baseurl=!g' -e 's!https\?://download\.fedoraproject\.org/pub/epel!https://'${MIRROR}'/pub/archive/epel!g' -e 's!https\?://download\.example/pub/epel!https://'${MIRROR}'/epel!g' /etc/yum.repos.d/epel*.repo
        elif [ ${OLD_DIR} == 'epel-archive' ];then
            sed -i -e 's|^baseurl=https://'${OLD_MIRROR}'/epel-archive|baseurl=https://'${MIRROR}'/pub/archive/epel|g' /etc/yum.repos.d/epel*.repo
        else
            sed -i -e 's|^baseurl=https://'${OLD_MIRROR}'/pub/archive/epel|baseurl=https://'${MIRROR}'/pub/archive/epel|g' /etc/yum.repos.d/epel*.repo
        fi
    fi
    ${COLOR}"更新镜像源中，请稍等......"${END}
    dnf clean all &> /dev/null && dnf makecache &> /dev/null
    ${COLOR}"${PRETTY_NAME}操作系统，EPEL镜像源设置完成！"${END}
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
            ${COLOR}"输入错误，请输入正确的数字(1-4)！"${END}
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
3)启用Rocky 9和10 devel仓库
4)启用Rocky 8 PowerTools仓库
5)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-5): " NUM
        case ${NUM} in
        1)
            rocky_8_9_10_base_menu
            ;;
        2)
            rocky_almalinux_centos_8_9_10_epel_menu
            ;;
        3)
            if [ ${MAIN_VERSION_ID} == "9" -o ${MAIN_VERSION_ID} == "10" ];then
                set_devel_rocky_9_10
            else
                ${COLOR}"${PRETTY_NAME}操作系统，没有devel仓库，不用设置！"${END}
            fi
            ;;
        4)
            if [ ${MAIN_VERSION_ID} == "8" ];then
                set_powertools_rocky_almalinux_centos_8
            else
                ${COLOR}"${PRETTY_NAME}操作系统，没有PowerTools仓库，不用设置！"${END}
            fi
            ;;
        5)
            break
            ;;
        *)
            ${COLOR}"输入错误，请输入正确的数字(1-5)！"${END}
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
3)启用AlmaLinux 9和10 crb仓库
4)添加AlmaLinux 9和10 devel仓库
5)启用AlmaLinux 8 PowerTools仓库
6)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-6): " NUM
        case ${NUM} in
        1)
            almalinux_8_9_10_base_menu
            ;;
        2)
            rocky_almalinux_centos_8_9_10_epel_menu
            ;;
        3)
            if [ ${MAIN_VERSION_ID} == "9" -o ${MAIN_VERSION_ID} == "10" ];then
                set_crb_almalinux_centos_9_10
            else
                ${COLOR}"${PRETTY_NAME}操作系统，没有crb仓库，不用设置！"${END}
            fi
            ;;
        4)
            if [ ${MAIN_VERSION_ID} == "9" -o ${MAIN_VERSION_ID} == "10" ];then
                almalinux_9_10_devel_menu
            else
                ${COLOR}"${PRETTY_NAME}操作系统，没有devel仓库，不用设置！"${END}
            fi
            ;;
        5)
            if [ ${MAIN_VERSION_ID} == "8" ];then
                set_powertools_rocky_almalinux_centos_8
            else
                ${COLOR}"${PRETTY_NAME}操作系统，没有PowerTools仓库，不用设置!"${END}
            fi
            ;;
        6)
            break
            ;;
        *)
            ${COLOR}"输入错误，请输入正确的数字(1-6)！"${END}
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
3)启用CentOS Stream 9和10 crb仓库
4)启用CentOS Stream 8 PowerTools仓库
5)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-5): " NUM
        case ${NUM} in
        1)
            if [ ${MAIN_VERSION_ID} == "7" ];then
                centos_7_base_menu
            elif [ ${MAIN_VERSION_ID} == "8" ];then
                centos_stream_8_base_menu
            else
                if grep -Eqi "^baseurl" /etc/yum.repos.d/centos*.repo;then
                    centos_stream_9_10_base_menu
                else
                    set_yum_centos_stream_9_10_perl
                fi
            fi
            ;;
        2)
            if [ ${MAIN_VERSION_ID} == "7" ];then
                centos_7_epel_menu
            else
                rocky_almalinux_centos_8_9_10_epel_menu
            fi
            ;;
        3)
            if [ ${MAIN_VERSION_ID} == "9" -o ${MAIN_VERSION_ID} == "10" ];then
                set_crb_almalinux_centos_9_10
            else
                ${COLOR}"${PRETTY_NAME}操作系统，没有crb仓库，不用设置！"${END}
            fi
            ;;
        4)
            if [ ${MAIN_VERSION_ID} == "8" ];then
                set_powertools_rocky_almalinux_centos_8
            else
                ${COLOR}"${PRETTY_NAME}操作系统，没有PowerTools仓库，不用设置！"${END}
            fi
            ;;
        5)
            break
            ;;
        *)
            ${COLOR}"输入错误，请输入正确的数字(1-5)！"${END}
            ;;
        esac
    done
}

set_ubuntu_apt(){
    if [ ${MAIN_VERSION_ID} == "18" -o ${MAIN_VERSION_ID} == "20" -o ${MAIN_VERSION_ID} == "22" ];then
        OLD_MIRROR=`sed -rn "s@^deb http(.*)://(.*)/ubuntu/? $(lsb_release -cs) main.*@\2@p" /etc/apt/sources.list`
        SECURITY_MIRROR=`sed -rn "s@^deb http(.*)://(.*)/ubuntu.* $(lsb_release -cs)-security main.*@\2@p" /etc/apt/sources.list`
        sed -i.bak -e 's@http.*://'${OLD_MIRROR}'@https://'${MIRROR}'@g' -e 's@http.*://'${SECURITY_MIRROR}'@https://'${MIRROR}'@g' /etc/apt/sources.list
    else
        sed -ri "s@^(URIs: )(http.*://)(.*)(/ubuntu).?@\1https://${MIRROR}\4@g" /etc/apt/sources.list.d/ubuntu.sources
    fi
    ${COLOR}"更新镜像源中，请稍等......"${END}
    apt update &> /dev/null
    ${COLOR}"${PRETTY_NAME}操作系统，镜像源设置完成！"${END}
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
8)中国科学技术大学镜像源
9)上海交通大学镜像源
10)西安交通大学镜像源
11)北京外国语大学镜像源
12)北京交通大学镜像源
13)北京大学镜像源
14)浙江大学镜像源
15)兰州大学镜像源
16)重庆邮电大学镜像源
17)火山引擎镜像源
18)中国科学院软件研究所镜像源
19)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-19): " NUM
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
            zju
            set_ubuntu_apt
            ;;
        15)
            lzu
            set_ubuntu_apt
            ;;
        16)
            cqupt
            set_ubuntu_apt
            ;;
        17)
            volces
            set_ubuntu_apt
            ;;
        18)
            iscas
            set_ubuntu_apt
            ;;
        19)
            break
            ;;
        *)
            ${COLOR}"输入错误，请输入正确的数字(1-19)！"${END}
            ;;
        esac
    done
}

set_debian_apt(){
    OLD_MIRROR=`sed -rn "s@^deb http(.*)://(.*)/debian/? $(lsb_release -cs) main.*@\2@p" /etc/apt/sources.list`
    SECURITY_MIRROR=`sed -rn "s@^deb http(.*)://(.*)/debian-security $(lsb_release -cs)-security main.*@\2@p" /etc/apt/sources.list`
    sed -ri.bak -e 's/'${OLD_MIRROR}'/'${MIRROR}'/g' -e 's/'${SECURITY_MIRROR}'/'${MIRROR}'/g' -e 's/^(deb cdrom.*)/#\1/g' /etc/apt/sources.list
    ${COLOR}"更新镜像源中，请稍等......"${END}
    apt update &> /dev/null
    ${COLOR}"${PRETTY_NAME}操作系统，镜像源设置完成！"${END}
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
8)中国科学技术大学镜像源
9)上海交通大学镜像源
10)西安交通大学镜像源
11)北京外国语大学镜像源
12)北京交通大学镜像源
13)北京大学镜像源
14)浙江大学镜像源
15)兰州大学镜像源
16)重庆邮电大学镜像源
17)火山引擎镜像源
18)中国科学院软件研究所镜像源
19)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-19): " NUM
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
            zju
            set_debian_apt
            ;;
        15)
            lzu
            set_debian_apt
            ;;
        16)
            cqupt
            set_debian_apt
            ;;
        17)
            volces
            set_debian_apt
            ;;
        18)
            iscas
            set_debian_apt
            ;;
        19)
            break
            ;;
        *)
            ${COLOR}"输入错误，请输入正确的数字(1-19)！"${END}
            ;;
        esac
    done
}

set_mirror_repository(){
    if [ ${MAIN_NAME} == "Rocky" ];then
        rocky_menu
    elif [ ${MAIN_NAME} == "AlmaLinux" ];then
        almalinux_menu
    elif [ ${MAIN_NAME} == "CentOS" ];then
        centos_menu
    elif [ ${MAIN_NAME} == "Ubuntu" ];then
        apt_menu
    else
        debian_menu
    fi
}

rocky_almalinux_centos_minimal_install(){
    ${COLOR}'开始安装“Minimal安装建议安装软件包”，请稍等......'${END}
    yum install -y vim lrzsz tree tmux lsof tcpdump wget net-tools iotop bc bzip2 zip unzip man-pages &> /dev/null
    ${COLOR}"${PRETTY_NAME}操作系统，Minimal安装建议安装软件包已安装完成！"${END}
}

ubuntu_debian_minimal_install(){
    ${COLOR}'开始安装“Minimal安装建议安装软件包”，请稍等......'${END}
    apt install -y iproute2 tcpdump telnet traceroute lrzsz tree iotop unzip zip
    if [ ${MAIN_NAME} == "Ubuntu" ];then
        apt install -y ntpdate
    else
        apt install -y ntpsec-ntpdate vim
    fi
    ${COLOR}"${PRETTY_NAME}操作系统，Minimal安装建议安装软件包已安装完成！"${END}
}

minimal_install(){
    if [ ${MAIN_NAME} == "Rocky" -o ${MAIN_NAME} == "AlmaLinux" -o ${MAIN_NAME} == "CentOS" ];then
        rocky_almalinux_centos_minimal_install
    else
        ubuntu_debian_minimal_install
    fi
}

disable_firewalls(){
    if [ ${MAIN_NAME} == "Rocky" -o ${MAIN_NAME} == "AlmaLinux" -o ${MAIN_NAME} == "CentOS" ];then
        rpm -q firewalld &> /dev/null && { systemctl disable --now firewalld &> /dev/null; ${COLOR}"${PRETTY_NAME}操作系统，Firewall防火墙已关闭！"${END}; } || ${COLOR}"${PRETTY_NAME}操作系统，默认没有安装Firewall防火墙服务，不要设置!"${END}
    elif [ ${MAIN_NAME} == "Ubuntu" ];then
        dpkg -s ufw &> /dev/null && { systemctl disable --now ufw &> /dev/null; ${COLOR}"${PRETTY_NAME}操作系统，ufw防火墙已关闭!"${END}; } || ${COLOR}"${PRETTY_NAME}操作系统， 默认没有ufw防火墙服务,不用关闭！"${END}
    else
        ${COLOR}"${PRETTY_NAME}操作系统，没有安装防火墙服务，不用关闭！"${END}
    fi
}

disable_selinux(){
    if [ ${MAIN_NAME} == "Rocky" -o ${MAIN_NAME} == "AlmaLinux" -o ${MAIN_NAME} == "CentOS" ];then
        if [ `getenforce` == "Enforcing" ];then
            sed -ri.bak 's/^(SELINUX=).*/\1disabled/' /etc/selinux/config
            setenforce 0
            ${COLOR}"${PRETTY_NAME}操作系统，SELinux已禁用，请重新启动系统后才能永久生效！"${END}
        else
            ${COLOR}"${PRETTY_NAME}操作系统，SELinux已被禁用，不用设置！"${END}
        fi
    else
        ${COLOR}"${PRETTY_NAME}操作系统，SELinux默认没有安装，不用设置！"${END}
    fi
}

set_swap(){
    if [ ${MAIN_NAME} == "CentOS" -a ${MAIN_VERSION_ID} == 7 ];then
        sed -ri.bak 's/.*swap.*/#&/' /etc/fstab
    elif [ ${MAIN_NAME} == "Ubuntu" -a ${MAIN_VERSION_ID} == 18 ];then
        sed -ri.bak 's/.*swap.*/#&/' /etc/fstab
	else
        systemctl mask swap.target &> /dev/null
    fi
    swapoff -a
    ${COLOR}"${PRETTY_NAME}操作系统，禁用swap已设置成功，请重启系统后生效！"${END}
}

set_localtime(){
    timedatectl set-timezone Asia/Shanghai
    echo 'Asia/Shanghai' >/etc/timezone
    if [ ${MAIN_NAME} == "ubuntu" ];then
        cat >> /etc/default/locale <<-EOF
LC_TIME=en_DK.UTF-8
EOF
    fi
    ${COLOR}"${PRETTY_NAME}操作系统，系统时区已设置成功，请重启系统后生效！"${END}
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
    ${COLOR}"${PRETTY_NAME}操作系统，优化资源限制参数成功！"${END}
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
    ${COLOR}"${PRETTY_NAME}操作系统，优化内核参数成功！"${END}
}

optimization_ssh(){
    if [ ${MAIN_NAME} == "Rocky" -o ${MAIN_NAME} == "AlmaLinux" -o ${MAIN_NAME} == "CentOS" ];then
        sed -ri.bak -e 's/^#(UseDNS).*/\1 no/' -e 's/^(GSSAPIAuthentication).*/\1 no/' /etc/ssh/sshd_config
    else
        sed -ri.bak -e 's/^#(UseDNS).*/\1 no/' -e 's/^#(GSSAPIAuthentication).*/\1 no/' /etc/ssh/sshd_config
    fi
    if [ ${MAIN_NAME} == "Ubuntu" ];then
        if [ ${MAIN_VERSION_ID} == 24 ];then
            sudo systemctl restart ssh
	    fi
    else
        sudo systemctl restart sshd
    fi
    ${COLOR}"${PRETTY_NAME}操作系统，SSH已优化完成！"${END}
}

set_ssh_port(){
    disable_selinux
    disable_firewalls
    read -p "请输入端口号: " PORT
    sed -i 's/#Port 22/Port '${PORT}'/' /etc/ssh/sshd_config
    if [ ${MAIN_NAME} == "Ubuntu" ];then
        if [ ${MAIN_VERSION_ID} == 24 ];then
            sudo systemctl restart ssh
	    fi
    else
        sudo systemctl restart sshd
    fi
    ${COLOR}"${PRETTY_NAME}操作系统，更改SSH端口号已完成，请重新登陆后生效！"${END}
}

set_rocky_almalinux_centos_alias(){
    ETHNAME=`ip addr | awk -F"[ :]" '/^2/{print $3}'`
    ETHNAME2=`ip addr | awk -F"[ :]" '/^3/{print $3}'`
    IP_NUM=`ip addr | awk -F"[: ]" '{print $1}' | grep -v '^$' | wc -l`
    if [ ${IP_NUM} == "2" ];then
        if [ ${MAIN_VERSION_ID} == "7" -o ${MAIN_VERSION_ID} == "8" ];then
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
        if [ ${MAIN_VERSION_ID} == "7" -o ${MAIN_VERSION_ID} == "8" ];then
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
    ${COLOR}"${PRETTY_NAME}操作系统，系统别名已设置成功，请重新登陆后生效！"${END}
}

set_ubuntu_alias(){
    cat >>~/.bashrc <<-EOF
alias cdnet="cd /etc/netplan"
alias cdapt="cd /etc/apt"
EOF
    if [ ${MAIN_VERSION_ID} == 18 ];then
        cat >>~/.bashrc <<-EOF
alias vie="vim /etc/netplan/01-netcfg.yaml"
EOF
    elif [ ${MAIN_VERSION_ID} == 20 ];then
        cat >>~/.bashrc <<-EOF
alias vie="vim /etc/netplan/00-installer-config.yaml"
EOF
    else
        cat >>~/.bashrc <<-EOF
alias vie="vim /etc/netplan/50-cloud-init.yaml"
EOF
    fi
    ${COLOR}"${PRETTY_NAME}操作系统，系统别名已设置成功，请重新登陆后生效！"${END}
}

set_debian_alias(){
    cat >>~/.bashrc <<-EOF
alias cdnet="cd /etc/network"
alias cdapt="cd /etc/apt"
alias vie="vim /etc/network/interfaces"
EOF
    ${COLOR}"${PRETTY_NAME}操作系统，系统别名已设置成功，请重新登陆后生效！"${END}
}

set_alias(){
    if [ ${MAIN_NAME} == "Rocky" -o ${MAIN_NAME} == "AlmaLinux" -o ${MAIN_NAME} == "CentOS" ];then
        if grep -Eqi "(.*cdnet|.*cdrepo|.*vie0|.*vie1|.*scandisk)" ~/.bashrc;then
            sed -i -e '/.*cdnet/d'  -e '/.*cdrepo/d' -e '/.*vie0/d' -e '/.*vie1/d' -e '/.*scandisk/d' ~/.bashrc
            set_rocky_almalinux_centos_alias
        else
            set_rocky_almalinux_centos_alias
        fi
    elif [ ${MAIN_NAME} == "Ubuntu" ];then
        if grep -Eqi "(.*cdnet|.*cdapt|.*vie)" ~/.bashrc;then
            sed -i -e '/.*cdnet/d' -e '/.*cdapt/d' -e '/.*vie/d' ~/.bashrc
            set_ubuntu_alias
        else
            set_ubuntu_alias
        fi
    else
        if grep -Eqi "(.*cdnet|.*cdapt|.*vie)" ~/.bashrc;then
            sed -i -e '/.*cdnet/d' -e '/.*cdapt/d' -e '/.*vie/d' ~/.bashrc
            set_debian_alias
        else
            set_debian_alias
        fi
    fi
}

set_vimrc(){
    read -p "请输入作者名: " AUTHOR
    read -p "请输入QQ号: " QQ
    read -p "请输入微信公众号: " MP
    read -p "请输入网址: " URL
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
    call setline(3,"#**********************************************************************************")
    call setline(4,"#Author:        ${AUTHOR}")
    call setline(5,"#QQ:            ${QQ}")
    call setline(6,"#MP:            ${MP}")
    call setline(7,"#Date:          ".strftime("%Y-%m-%d"))
    call setline(8,"#FileName:      ".expand("%"))
    call setline(9,"#URL:           ${URL}")
    call setline(10,"#Description:   The test script")
    call setline(11,"#Copyright (C): ".strftime("%Y")." All rights reserved")
    call setline(12,"#**********************************************************************************")
    call setline(13,"")
    endif
endfunc
autocmd BufNewFile * normal G
EOF
    ${COLOR}"${PRETTY_NAME}操作系统，vimrc设置完成，请重新系统启动才能生效！"${END}
}

set_mail(){                                                                                                 
    if [ ${MAIN_NAME} == "Rocky" -o ${MAIN_NAME} == "AlmaLinux" -o ${MAIN_NAME} == "CentOS" ];then
        rpm -q postfix &> /dev/null || { ${COLOR}"安装postfix服务，请稍等......"${END};yum -y install postfix &> /dev/null; systemctl enable --now postfix &> /dev/null; }
        rpm -q mailx &> /dev/null || { ${COLOR}"安装mailx服务，请稍等......"${END};yum -y install mailx &> /dev/null; }
    else
        dpkg -s mailutils &> /dev/null || { ${COLOR}"安装mailutils服务，请稍等......"${END};apt -y install mailutils; }
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
    ${COLOR}"${PRETTY_NAME}操作系统，邮件设置完成，请重新登录后才能生效！"${END}
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
    if [ ${MAIN_NAME} == "Rocky" -o ${MAIN_NAME} == "AlmaLinux" -o ${MAIN_NAME} == "CentOS" ];then
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
    TIPS="${COLOR}${PRETTY_NAME}操作系统，PS1设置成功，请重新登录生效！${END}"
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
            ${COLOR}"输入错误，请输入正确的数字(1-8)！"${END}
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
    ${COLOR}"${PRETTY_NAME}操作系统，默认文本编辑器设置成功，请重新登录生效！"${END}
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
    ${COLOR}"${PRETTY_NAME}操作系统，history格式设置成功，请重新登录生效！"${END}
}

disable_restart(){
    START_STATUS=`systemctl status ctrl-alt-del.target | sed -n '2p' | awk -F"[[:space:]]+|;" '{print $6}'`
    if [ ${START_STATUS} == "enabled" ];then
        systemctl disable ctrl-alt-del.target &> /dev/null
    fi
    systemctl mask ctrl-alt-del.target &> /dev/null
    ${COLOR}"${PRETTY_NAME}操作系统，禁用ctrl+alt+del重启功能设置成功！"${END}
}

ubuntu_remove(){
    if [ ${MAIN_NAME} == "Ubuntu" ];then
        if [ ${MAIN_VERSION_ID} == 18 ];then
            apt -y purge ufw lxd lxd-client lxcfs liblxc-common
        else
            apt -y purge ufw
        fi
        ${COLOR}"${PRETTY_NAME}操作系统，无用软件包卸载完成！"${END}
    else
        ${COLOR}"${PRETTY_NAME}操作系统，系统不可用！"${END}
    fi
}

ubuntu_20_22_24_remove_snap(){
    dpkg -s snapd &> /dev/null || { ${COLOR}"snap已卸载！"${END};exit; }
    systemctl disable snapd.service && systemctl disable snapd.socket && systemctl disable snapd.seeded.service
    if [ ${MAIN_NAME} == "Ubuntu" ];then
        if [ ${MAIN_VERSION_ID} == 20 -o ${MAIN_VERSION_ID} == 22 ];then
            snap remove --purge lxd
            sum=$(snap list | awk 'NR>=2{print $1}' | wc -l)
            while [ $sum -ne 0 ];do
                for p in $(snap list | awk 'NR>=2{print $1}'); do
                    snap remove --purge $p
                done
                sum=$(snap list | awk 'NR>=2{print $1}' | wc -l)
            done
        fi
    fi
    apt -y autoremove --purge snapd
    rm -rf ~/snap && sudo rm -rf /snap && rm -rf /var/snap && rm -rf /var/lib/snapd && rm -rf /var/cache/snapd
    cat > /etc/apt/preferences.d/no-snapd.pref << EOF
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF
    apt update
    ${COLOR}"${PRETTY_NAME}操作系统，snap卸载完成！"${END}
}

ubuntu_remove_snap(){
    if [ ${MAIN_NAME} == "Ubuntu" ];then
        if [ ${MAIN_VERSION_ID} == 20 -o ${MAIN_VERSION_ID} == 22 -o ${MAIN_VERSION_ID} == 24 ];then
            ubuntu_20_22_24_remove_snap
        else
           ${COLOR}"${PRETTY_NAME}操作系统，默认没有安装snap！"${END} 
        fi
    else
        ${COLOR}"${PRETTY_NAME}操作系统，系统不可用！"${END}
    fi
}

menu(){
    while true;do
        echo -e "\E[$[RANDOM%7+31];1m"
        cat <<-EOF
********************************************************
*            系统初始化脚本菜单                        *
* 1.设置root用户登录   14.更改SSH端口号                *
* 2.修改网卡名         15.设置系统别名                 *
* 3.设置网络           16.设置vimrc配置文件            *
* 4.设置主机名         17.安装邮件服务并配置           *
* 5.设置镜像仓库       18.设置PS1(请进入选择颜色)      *
* 6.建议安装软件       19.设置默认文本编辑器为vim      *
* 7.关闭防火墙         20.设置history格式              *
* 8.禁用SELinux        21.禁用ctrl+alt+del重启系统功能 *
* 9.禁用SWAP           22.Ubuntu卸载无用软件包         *
* 10.设置系统时区      23.Ubuntu卸载snap               *
* 11.优化资源限制参数  24.重启系统                     *
* 12.优化内核参数      25.关机                         *
* 13.优化SSH           26.退出                         *
********************************************************
EOF
        echo -e '\E[0m'

        read -p "请选择相应的编号(1-26): " choice
        case ${choice} in
        1)
            if [ ${LOGIN_USER} == "root" ];then
                ${COLOR}"当然登录用户是${LOGIN_USER}，不用设置！"${END}
            else
                set_root_login
            fi
            ;;
        2)
            if [ ${LOGIN_USER} == "root" ];then
                set_eth
            else
                ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录后再执行此操作！"${END}
            fi
            ;;
        3)
            if [ ${LOGIN_USER} == "root" ];then
                set_network
            else
                ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录后再执行此操作！"${END}
            fi
            ;;
        4)
            if [ ${LOGIN_USER} == "root" ];then
                set_hostname
            else
                ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录后再执行此操作！"${END}
            fi
            ;;
        5)
            if [ ${LOGIN_USER} == "root" ];then
                set_mirror_repository
            else
                ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录后再执行此操作！"${END}
            fi
            ;;
        6)
            if [ ${LOGIN_USER} == "root" ];then
                minimal_install
            else
                ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录后再执行此操作！"${END}
            fi
            ;;
        7)
            if [ ${LOGIN_USER} == "root" ];then
                disable_firewalls
            else
                ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录后再执行此操作！"${END}
            fi
            ;;
        8)
            if [ ${LOGIN_USER} == "root" ];then
                disable_selinux
            else
                ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录后再执行此操作！"${END}
            fi
            ;;
        9)
            if [ ${LOGIN_USER} == "root" ];then
                set_swap
            else
                ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录后再执行此操作！"${END}
            fi
            ;;
        10)
            if [ ${LOGIN_USER} == "root" ];then
                set_localtime
            else
                ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录后再执行此操作！"${END}
            fi
            ;;
        11)
            if [ ${LOGIN_USER} == "root" ];then
                set_limits
            else
                ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录后再执行此操作！"${END}
            fi
            ;;
        12)
            if [ ${LOGIN_USER} == "root" ];then
                set_kernel
            else
                ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录后再执行此操作！"${END}
            fi
            ;;
        13)
            if [ ${LOGIN_USER} == "root" ];then
                optimization_ssh
            else
                ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录后再执行此操作！"${END}
            fi
            ;;
        14)
            if [ ${LOGIN_USER} == "root" ];then
                set_ssh_port
            else
                ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录后再执行此操作！"${END}
            fi
            ;;
        15)
            if [ ${LOGIN_USER} == "root" ];then
                set_alias
            else
                ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录后再执行此操作！"${END}
            fi
            ;;
        16)
            if [ ${LOGIN_USER} == "root" ];then
                set_vimrc
            else
                ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录后再执行此操作！"${END}
            fi
            ;;
        17)
            if [ ${LOGIN_USER} == "root" ];then
                set_mail
            else
                ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录后再执行此操作！"${END}
            fi
            ;;
        18)
            if [ ${LOGIN_USER} == "root" ];then
                set_ps1
            else
                ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录后再执行此操作！"${END}
            fi
            ;;
        19)
            if [ ${LOGIN_USER} == "root" ];then
                set_vim_env
            else
                ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录后再执行此操作！"${END}
            fi
            ;;
        20)
            if [ ${LOGIN_USER} == "root" ];then
                set_history_env
            else
                ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录后再执行此操作！"${END}
            fi
            ;;
        21)
            if [ ${LOGIN_USER} == "root" ];then
                disable_restart
            else
                ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录后再执行此操作！"${END}
            fi
            ;;
        22)
            if [ ${LOGIN_USER} == "root" ];then
                ubuntu_remove
            else
                ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录后再执行此操作！"${END}
            fi
            ;;
        23)
            if [ ${LOGIN_USER} == "root" ];then
                ubuntu_remove_snap
            else
                ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录后再执行此操作！"${END}
            fi
            ;;
        24)
            if [ ${LOGIN_USER} == "root" ];then
                shutdown -r now
            else
                sudo shutdown -r now
            fi
            ;;
        25)
            if [ ${LOGIN_USER} == "root" ];then
                shutdown -h now
            else
                sudo shutdown -h now
            fi
            ;;
        26)
            break
            ;;
        *)
            ${COLOR}"输入错误，请输入正确的数字(1-26)！"${END}
            ;;
        esac
    done
}

main(){
    if [ ${LOGIN_USER} == "root" ];then
        menu
    else
        ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录！"${END}
        menu
    fi
}

os
if [ ${MAIN_NAME} == "Rocky" ];then
    if [ ${MAIN_VERSION_ID} == 8 -o ${MAIN_VERSION_ID} == 9 -o ${MAIN_VERSION_ID} == 10 ];then
        main
    fi
elif [ ${MAIN_NAME} == "AlmaLinux" ];then
    if [ ${MAIN_VERSION_ID} == 8 -o ${MAIN_VERSION_ID} == 9 -o ${MAIN_VERSION_ID} == 10 ];then
        main
    fi
elif [ ${MAIN_NAME} == "CentOS" ];then
    if [ ${MAIN_VERSION_ID} == 7 -o ${MAIN_VERSION_ID} == 8 -o ${MAIN_VERSION_ID} == 9 -o ${MAIN_VERSION_ID} == 10 ];then
        main
    fi
elif [ ${MAIN_NAME} == "Ubuntu" ];then
    if [ ${MAIN_VERSION_ID} == 18 -o ${MAIN_VERSION_ID} == 20 -o ${MAIN_VERSION_ID} == 22 -o ${MAIN_VERSION_ID} == 24 ];then
        main
    fi
elif [ ${MAIN_NAME} == 'Debian' ];then
    if [ ${MAIN_VERSION_ID} == 11 -o ${MAIN_VERSION_ID} == 12 -o ${MAIN_VERSION_ID} == 13 ];then
        main
    fi
else
    ${COLOR}"此脚本不支持${PRETTY_NAME}操作系统！"${END}
fi

