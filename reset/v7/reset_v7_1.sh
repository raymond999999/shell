#!/bin/bash
#
#***************************************************************************************************
#Author:        Raymond
#QQ:            88563128
#Date:          2023-12-08
#FileName:      reset_v7_1.sh
#MIRROR:        raymond.blog.csdn.net
#Description:   reset for CentOS 7 & CentOS Stream 8/9 & Ubuntu 18.04/20.04/22.04 & Rocky 8/9
#Copyright (C): 2023 All rights reserved
#***************************************************************************************************
COLOR="echo -e \\033[01;31m"
END='\033[0m'

os(){
    OS_ID=`sed -rn '/^NAME=/s@.*="([[:alpha:]]+).*"$@\1@p' /etc/os-release`
    OS_NAME=`sed -rn '/^NAME=/s@.*="([[:alpha:]]+) (.*)"$@\2@p' /etc/os-release`
    OS_RELEASE=`sed -rn '/^VERSION_ID=/s@.*="?([0-9.]+)"?@\1@p' /etc/os-release`
    OS_RELEASE_VERSION=`sed -rn '/^VERSION_ID=/s@.*="?([0-9]+)\.?.*"?@\1@p' /etc/os-release`
}

set_rocky_centos_eth(){
    if [ ${OS_RELEASE_VERSION} == "7" -o ${OS_RELEASE_VERSION} == "8" ];then
        ETHNAME=`ip addr | awk -F"[ :]" '/^2/{print $3}'`
        if grep -Eqi "(net\.ifnames|biosdevname)" /etc/default/grub;then
            ${COLOR}"${OS_ID} ${OS_RELEASE} 网卡名配置文件已修改,不用修改!"${END}
        else
		    # 修改网卡名称配置文件
            sed -ri.bak '/^GRUB_CMDLINE_LINUX=/s@"$@ net.ifnames=0 biosdevname=0"@' /etc/default/grub
            grub2-mkconfig -o /boot/grub2/grub.cfg >& /dev/null

            # 修改网卡文件名
            mv /etc/sysconfig/network-scripts/ifcfg-${ETHNAME} /etc/sysconfig/network-scripts/ifcfg-eth0
            ${COLOR}"${OS_ID} ${OS_RELEASE} 网卡名已修改成功,10秒后,机器会自动重启!"${END}
		    sleep 10 && shutdown -r now
        fi   
    else
        ${COLOR}"${OS_ID} ${OS_RELEASE} 不能修改网卡名!"${END} 
    fi
}

set_ubuntu_eth(){
    # 修改网卡名称配置文件
	if grep -Eqi "(net\.ifnames|biosdevname)" /etc/default/grub;then
        ${COLOR}"${OS_ID} ${OS_RELEASE} 网卡名配置文件已修改,不用修改!"${END}
    else
        sed -ri.bak '/^GRUB_CMDLINE_LINUX=/s@"$@net.ifnames=0 biosdevname=0"@' /etc/default/grub
        grub-mkconfig -o /boot/grub/grub.cfg >& /dev/null
        ${COLOR}"${OS_ID} ${OS_RELEASE} 网卡名已修改成功，请重新启动系统后才能生效!"${END}
    fi
}

set_eth(){
    if [ ${OS_ID} == "CentOS" -o ${OS_ID} == "Rocky" ];then
        set_rocky_centos_eth
    else
        set_ubuntu_eth
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

set_rocky_centos_ip(){
    ETHNAME=`ip addr | awk -F"[ :]" '/^2/{print $3}'`
    CONNECTION_NAME=`nmcli dev | awk 'NR==2{print $4,$5,$6}'`
    while true; do
        read -p "请输入IP地址: " IP
        check_ip ${IP}
        [ $? -eq 0 ] && break
    done
    read -p "请输入子网掩码位数: " C_PREFIX
    while true; do
        read -p "请输入网关地址: " GATEWAY
        check_ip ${GATEWAY}
        [ $? -eq 0 ] && break
    done
    ${COLOR}"${OS_ID} ${OS_RELEASE} IP地址、网关地址和DNS已修改成功，请使用新IP重新登录!"${END}
    if [ ${OS_RELEASE_VERSION} == "7" -o ${OS_RELEASE_VERSION} == "8" ];then
        nmcli connection modify "${CONNECTION_NAME}" con-name ${ETHNAME} && nmcli connection delete ${ETHNAME} >& /dev/null && nmcli connection add type ethernet con-name ${ETHNAME} ifname ${ETHNAME} ipv4.method manual ipv4.address "${IP}/${C_PREFIX}" ipv4.gateway "${GATEWAY}" ipv4.dns "223.5.5.5,180.76.76.76" autoconnect yes >& /dev/null && nmcli con reload && nmcli dev up ${ETHNAME} >& /dev/null
    else
        nmcli connection delete ${ETHNAME} >& /dev/null && nmcli connection add type ethernet con-name ${ETHNAME} ifname ${ETHNAME} ipv4.method manual ipv4.address "${IP}/${C_PREFIX}" ipv4.gateway "${GATEWAY}" ipv4.dns "223.5.5.5,180.76.76.76" autoconnect yes >& /dev/null && nmcli con reload && nmcli dev up ${ETHNAME} >& /dev/null
    fi
}

set_ubuntu_ip(){
    while true; do
        read -p "请输入IP地址: " IP
        check_ip ${IP}
        [ $? -eq 0 ] && break
    done
    read -p "请输入子网掩码位数: " U_PREFIX
    while true; do
        read -p "请输入网关地址: " GATEWAY
        check_ip ${GATEWAY}
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
      addresses: [${IP}/${U_PREFIX}] 
      gateway4: ${GATEWAY}
      nameservers:
        addresses: [223.5.5.5, 180.76.76.76]
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
      addresses: [${IP}/${U_PREFIX}] 
      gateway4: ${GATEWAY}
      nameservers:
        addresses: [223.5.5.5, 180.76.76.76]
EOF
    else
        cat > /etc/netplan/00-installer-config.yaml <<-EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      dhcp6: no
      addresses: [${IP}/${U_PREFIX}]
      routes:
        - to: default
          via: ${GATEWAY}
      nameservers:
        addresses: [223.5.5.5, 180.76.76.76]
EOF
    fi    
    ${COLOR}"${OS_ID} ${OS_RELEASE} IP地址、网关地址和DNS已修改成功,请重新启动系统后生效!"${END}
}

set_ip(){
    if [ ${OS_ID} == "CentOS" -o ${OS_ID} == "Rocky" ];then
        set_rocky_centos_ip
    else
        set_ubuntu_ip
    fi
}

set_dual_rocky_centos_ip(){
    ETHNAME=`ip addr | awk -F"[ :]" '/^2/{print $3}'`
    ETHNAME2=`ip addr | awk -F"[ :]" '/^3/{print $3}'`
    CONNECTION_NAME1=`nmcli dev | awk 'NR==2{print $4,$5,$6}'`
    CONNECTION_NAME2=`nmcli dev | awk 'NR==3{print $4,$5,$6}'`
    while true; do
        read -p "请输入第一块网卡IP地址: " IP
        check_ip ${IP}
        [ $? -eq 0 ] && break
    done
    read -p "请输入子网掩码位数: " C_PREFIX
    while true; do
        read -p "请输入网关地址: " GATEWAY
        check_ip ${GATEWAY}
        [ $? -eq 0 ] && break
    done
    while true; do
        read -p "请输入第二块网卡IP地址: " IP2
        check_ip ${IP2}
        [ $? -eq 0 ] && break
    done
    read -p "请输入子网掩码位数: " C_PREFIX2
    ${COLOR}"${OS_ID} ${OS_RELEASE} IP地址、网关地址和DNS已修改成功，请使用新IP重新登录!"${END}
    if [ ${OS_RELEASE_VERSION} == "7" -o ${OS_RELEASE_VERSION} == "8" ];then
        nmcli connection modify "${CONNECTION_NAME1}" con-name ${ETHNAME} && nmcli connection delete ${ETHNAME} >& /dev/null && nmcli connection add type ethernet con-name ${ETHNAME} ifname ${ETHNAME} ipv4.method manual ipv4.address "${IP}/${C_PREFIX}" ipv4.gateway "${GATEWAY}" ipv4.dns "223.5.5.5,180.76.76.76" autoconnect yes >& /dev/null && nmcli connection modify "${CONNECTION_NAME2}" con-name ${ETHNAME2} && nmcli connection delete ${ETHNAME2} >& /dev/null && nmcli connection add type ethernet con-name ${ETHNAME2} ifname ${ETHNAME2} ipv4.method manual ipv4.address "${IP2}/${C_PREFIX2}" autoconnect yes >& /dev/null && nmcli con reload && nmcli dev up ${ETHNAME} ${ETHNAME2} >& /dev/null
    else
        nmcli connection delete ${ETHNAME} >& /dev/null && nmcli connection add type ethernet con-name ${ETHNAME} ifname ${ETHNAME} ipv4.method manual ipv4.address "${IP}/${C_PREFIX}" ipv4.gateway "${GATEWAY}" ipv4.dns "223.5.5.5,180.76.76.76" autoconnect yes >& /dev/null && nmcli connection modify "${CONNECTION_NAME2}" con-name ${ETHNAME2} && nmcli connection delete ${ETHNAME2} >& /dev/null && nmcli connection add type ethernet con-name ${ETHNAME2} ifname ${ETHNAME2} ipv4.method manual ipv4.address "${IP2}/${C_PREFIX2}" autoconnect yes >& /dev/null && nmcli con reload && nmcli dev up ${ETHNAME} ${ETHNAME2} >& /dev/null
    fi
}

set_dual_ubuntu_ip(){
    while true; do
        read -p "请输入第一块网卡IP地址: " IP
        check_ip ${IP}
        [ $? -eq 0 ] && break
    done
    read -p "请输入子网掩码位数: " U_PREFIX
    while true; do
        read -p "请输入网关地址: " GATEWAY
        check_ip ${GATEWAY}
        [ $? -eq 0 ] && break
    done
    while true; do
        read -p "请输入第二块网卡IP地址: " IP2
        check_ip ${IP2}
        [ $? -eq 0 ] && break
    done
    read -p "请输入子网掩码位数: " U_PREFIX2
    if [ ${OS_RELEASE_VERSION} == "18" ];then
        cat > /etc/netplan/01-netcfg.yaml <<-EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      dhcp6: no
      addresses: [${IP}/${U_PREFIX}] 
      gateway4: ${GATEWAY}
      nameservers:
        addresses: [223.5.5.5, 180.76.76.76]
    eth1:
      dhcp4: no
      dhcp6: no
      addresses: [${IP2}/${U_PREFIX2}] 
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
      addresses: [${IP}/${U_PREFIX}] 
      gateway4: ${GATEWAY}
      nameservers:
        addresses: [223.5.5.5, 180.76.76.76]
    eth1:
      dhcp4: no
      dhcp6: no
      addresses: [${IP2}/${U_PREFIX2}] 
EOF
    else
        cat > /etc/netplan/00-installer-config.yaml <<-EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      dhcp6: no
      addresses: [${IP}/${U_PREFIX}] 
      routes:
        - to: default
          via: ${GATEWAY}
      nameservers:
        addresses: [223.5.5.5, 180.76.76.76]
    eth1:
      dhcp4: no
      dhcp6: no
      addresses: [${IP2}/${U_PREFIX2}] 
EOF
    fi
    ${COLOR}"${OS_ID} ${OS_RELEASE} IP地址、网关地址和DNS已修改成功,请重新启动系统后生效!"${END}
}

set_dual_ip(){
    if [ ${OS_ID} == "CentOS" -o ${OS_ID} == "Rocky" ];then
        set_dual_rocky_centos_ip
    else
        set_dual_ubuntu_ip
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

pku(){
    MIRROR=mirrors.pku.edu.cn
}

xjtu(){
    MIRROR=mirrors.xjtu.edu.cn
}

set_yum_rocky8_9(){
    MIRROR_URL=`echo ${MIRROR} | awk -F"." '{print $2}'`
    OLD_MIRROR=$(sed -rn '/^.*baseurl=/s@.*=http.*://(.*)/(.*)/\$releasever/.*/$@\1@p' /etc/yum.repos.d/[Rr]ocky*.repo | head -1)
    OLD_DIR=$(sed -rn '/^.*baseurl=/s@.*=http.*://(.*)/(.*)/\$releasever/.*/$@\2@p' /etc/yum.repos.d/[Rr]ocky*.repo | head -1)
    if [ ${MIRROR_URL} == "aliyun" -o ${MIRROR_URL} == "xjtu" ];then
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
    ${COLOR}"更新镜像源中,请稍等..."${END}
    dnf clean all &> /dev/null && dnf makecache &> /dev/null
    ${COLOR}"${OS_ID} ${OS_RELEASE} YUM源设置完成!"${END}
}

rocky8_9_base_menu(){
    while true;do
        echo -e "\E[$[RANDOM%7+31];1m"
        cat <<-EOF
1)阿里镜像源
2)网易镜像源
3)搜狐镜像源
4)南京大学镜像源
5)中科大镜像源
6)上海交通大学镜像源
7)北京大学镜像源
8)西安交通大学镜像源
9)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-9): " NUM
        case ${NUM} in
        1)
            aliyun
            set_yum_rocky8_9
            ;;
        2)
            netease
            set_yum_rocky8_9
            ;;
        3)
            sohu
            set_yum_rocky8_9
            ;;
        4)
            nju
            set_yum_rocky8_9
            ;;
        5)
            ustc
            set_yum_rocky8_9
            ;;
        6)
            sjtu
            set_yum_rocky8_9
            ;;
        7)
            pku
            set_yum_rocky8_9
            ;;
        8)
            xjtu
            set_yum_rocky8_9
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

set_yum_centos_stream9_perl(){
    ${COLOR}"由于CentOS Stream 9系统默认镜像源是Perl语言实现的，在更改镜像源之前先确保把'update_mirror.pl'文件和reset脚本放在同一个目录下，否则后面程序会退出，默认的CentOS Stream 9镜像源设置的是阿里云，要修改镜像源，请去'update_mirror.pl'文件里修改url变量！"${END}
    sleep 10
    PERL_FILE=update_mirror.pl
    if [ ! -e ${PERL_FILE} ];then
        ${COLOR}"缺少${PERL_FILE}文件"${END}
        exit
    else
        ${COLOR}"${PERL_FILE}文件已准备好，继续后续配置！"${END}       
    fi
    rpm -q perl &> /dev/null || { ${COLOR}"安装perl工具,请稍等..."${END};yum -y install perl &> /dev/null; }
    perl ./update_mirror.pl /etc/yum.repos.d/centos*.repo
    ${COLOR}"更新镜像源中,请稍等..."${END}
    dnf clean all &> /dev/null && dnf makecache &> /dev/null
    ${COLOR}"${OS_ID} ${OS_RELEASE} YUM源设置完成!"${END}
}

set_yum_centos_stream9(){
    OLD_MIRROR=$(sed -rn '/^.*baseurl=/s@.*=http.*://(.*)/(.*)/\$releasever-stream/.*/$@\1@p' /etc/yum.repos.d/centos*.repo | head -1)
    sed -i -e 's|^baseurl=https://'${OLD_MIRROR}'|baseurl=https://'${MIRROR}'|g' /etc/yum.repos.d/centos*.repo
    ${COLOR}"更新镜像源中,请稍等..."${END}
    dnf clean all &> /dev/null && dnf makecache &> /dev/null
    ${COLOR}"${OS_ID} ${OS_RELEASE} YUM源设置完成!"${END}
}

centos_stream9_base_menu(){
    while true;do
        echo -e "\E[$[RANDOM%7+31];1m"
        cat <<-EOF
1)阿里镜像源
2)华为镜像源
3)腾讯镜像源
4)清华镜像源
5)网易镜像源
6)南京大学镜像源
7)中科大镜像源
8)北京大学镜像源
9)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-9): " NUM
        case ${NUM} in
        1)
            aliyun
            set_yum_centos_stream9
            ;;
        2)
            huawei
            set_yum_centos_stream9
            ;;
        3)
            tencent
            set_yum_centos_stream9
            ;;
        4)
            tuna
            set_yum_centos_stream9
            ;;
        5)
            netease
            set_yum_centos_stream9
            ;;
        6)
            nju
            set_yum_centos_stream9
            ;;
        7)
            ustc
            set_yum_centos_stream9
            ;;
        8)
            pku
            set_yum_centos_stream9
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

set_yum_centos_stream8(){
    OLD_MIRROR=$(sed -rn '/^.*baseurl=/s@.*=http.*://(.*)/(.*)/\$stream/.*/$@\1@p' /etc/yum.repos.d/CentOS-*.repo | head -1)
    OLD_DIR=$(sed -rn '/^.*baseurl=/s@.*=http.*://(.*)/(.*)/\$stream/.*/$@\2@p' /etc/yum.repos.d/CentOS-*.repo | head -1)
    if [ ${OLD_DIR} == '$contentdir' ];then
        sed -i.bak -e 's|^mirrorlist=|#mirrorlist=|g' -e 's|^#baseurl=http://mirror.centos.org/$contentdir|baseurl=https://'${MIRROR}'/centos|g' /etc/yum.repos.d/CentOS-*.repo
    else
        sed -i -e 's|^baseurl=https://'${OLD_MIRROR}'|baseurl=https://'${MIRROR}'|g' /etc/yum.repos.d/CentOS-*.repo
    fi
    ${COLOR}"更新镜像源中,请稍等..."${END}
    dnf clean all &> /dev/null && dnf makecache &> /dev/null
    ${COLOR}"${OS_ID} ${OS_RELEASE} YUM源设置完成!"${END}
}

centos_stream8_base_menu(){
    while true;do
        echo -e "\E[$[RANDOM%7+31];1m"
        cat <<-EOF
1)阿里镜像源
2)华为镜像源
3)腾讯镜像源
4)清华镜像源
5)网易镜像源
6)南京大学镜像源
7)中科大镜像源
8)北京大学镜像源
9)西安交通大学镜像源
10)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-10): " NUM
        case ${NUM} in
        1)
            aliyun
            set_yum_centos_stream8
            ;;
        2)
            huawei
            set_yum_centos_stream8
            ;;
        3)
            tencent
            set_yum_centos_stream8
            ;;
        4)
            tuna
            set_yum_centos_stream8
            ;;
        5)
            netease
            set_yum_centos_stream8
            ;;
        6)
            nju
            set_yum_centos_stream8
            ;;
        7)
            ustc
            set_yum_centos_stream8
            ;;
        8)
            pku
            set_yum_centos_stream8
            ;;
        9)
            xjtu
            set_yum_centos_stream8
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

set_epel_rocky_centos8_9(){
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
    if [ ${OS_RELEASE_VERSION} == "9" ];then
        sed -i -e 's|^enabled=1|enabled=0|g' /etc/yum.repos.d/epel-cisco*.repo
    fi
    ${COLOR}"更新镜像源中,请稍等..."${END}
    dnf clean all &> /dev/null && dnf makecache &> /dev/null
    ${COLOR}"${OS_ID} ${OS_RELEASE} EPEL源设置完成!"${END}
}

rocky_centos8_9_epel_menu(){
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
9)北京大学镜像源
10)西安交通大学镜像源
11)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-11): " NUM
        case ${NUM} in
        1)
            aliyun
            set_epel_rocky_centos8_9
            ;;
        2)
            huawei
            set_epel_rocky_centos8_9
            ;;
        3)
            tencent
            set_epel_rocky_centos8_9
            ;;
        4)
            tuna
            set_epel_rocky_centos8_9
            ;;
        5)
            sohu
            set_epel_rocky_centos8_9
            ;;
        6)
            nju
            set_epel_rocky_centos8_9
            ;;
        7)
            ustc
            set_epel_rocky_centos8_9
            ;;
        8)
            sjtu
            set_epel_rocky_centos8_9
            ;;
        9)
            pku
            set_epel_rocky_centos8_9
            ;;
        10)
            xjtu
            set_epel_rocky_centos8_9
            ;;
        11)
            break
            ;;
        *)
            ${COLOR}"输入错误,请输入正确的数字(1-11)!"${END}
            ;;
        esac
    done
}

set_yum_centos7(){
    OLD_MIRROR=$(sed -rn '/^.*baseurl=/s@.*=(http.*)://(.*)/(.*)/\$releasever/.*/$@\2@p' /etc/yum.repos.d/CentOS-*.repo | head -1)
    if grep -Eqi "^#baseurl" /etc/yum.repos.d/CentOS-*.repo;then
        sed -i.bak -e 's|^mirrorlist=|#mirrorlist=|g' -e 's|^#baseurl=http://mirror.centos.org|baseurl=https://'${MIRROR}'|g' /etc/yum.repos.d/CentOS-*.repo
    else
        sed -i -e 's|^baseurl=https://'${OLD_MIRROR}'|baseurl=https://'${MIRROR}'|g' /etc/yum.repos.d/CentOS-*.repo
    fi
    ${COLOR}"更新镜像源中,请稍等..."${END}
    yum clean all &> /dev/null && yum makecache &> /dev/null
    ${COLOR}"${OS_ID} ${OS_RELEASE} YUM源设置完成!"${END}
}

centos7_base_menu(){
    while true;do
        echo -e "\E[$[RANDOM%7+31];1m"
        cat <<-EOF
1)阿里镜像源
2)华为镜像源
3)腾讯镜像源
4)清华镜像源
5)网易镜像源
6)南京大学镜像源
7)中科大镜像源
8)北京大学镜像源
9)西安交通大学镜像源
10)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-10): " NUM
        case ${NUM} in
        1)
            aliyun
            set_yum_centos7
            ;;
        2)
            huawei
            set_yum_centos7
            ;;
        3)
            tencent
            set_yum_centos7
            ;;
        4)
            tuna
            set_yum_centos7
            ;;
        5)
            netease
            set_yum_centos7
            ;;
        6)
            nju
            set_yum_centos7
            ;;
        7)
            ustc
            set_yum_centos7
            ;;
        8)
            pku
            set_yum_centos7
            ;;
        9)
            xjtu
            set_yum_centos7
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

set_epel_centos7(){
    rpm -q epel-release &> /dev/null || { ${COLOR}"安装epel-release工具,请稍等..."${END};yum -y install epel-release &> /dev/null; }
    MIRROR_URL=`echo ${MIRROR} | awk -F"." '{print $2}'`
    OLD_MIRROR=$(awk -F'/' '/^baseurl=/{print $3}' /etc/yum.repos.d/epel*.repo | head -1)
    OLD_DIR=$(awk -F'/' '/^baseurl=/{print $4}' /etc/yum.repos.d/epel*.repo | head -1)
    if [ ${MIRROR_URL} == "sohu" ];then
        if grep -Eqi "^#baseurl" /etc/yum.repos.d/epel*.repo;then
            sed -i.bak -e 's!^metalink=!#metalink=!g' -e 's!^#baseurl=!baseurl=!g' -e 's!https\?://download\.fedoraproject\.org/pub/epel!https://'${MIRROR}'/fedora-epel!g' -e 's!https\?://download\.example/pub/epel!https://'${MIRROR}'/fedora-epel!g' /etc/yum.repos.d/epel*.repo
        elif [ ${OLD_DIR} == 'epel' ];then
            sed -i -e 's|^baseurl=https://'${OLD_MIRROR}'/epel|baseurl=https://'${MIRROR}'/fedora-epel|g' /etc/yum.repos.d/epel*.repo
        elif [ ${OLD_DIR} == 'fedora' ];then
            sed -i -e 's|^baseurl=https://'${OLD_MIRROR}'/fedora/epel|baseurl=https://'${MIRROR}'/fedora-epel|g' /etc/yum.repos.d/epel*.repo
        else
            sed -i -e 's|^baseurl=https://'${OLD_MIRROR}'/fedora-epel|baseurl=https://'${MIRROR}'/fedora-epel|g' /etc/yum.repos.d/epel*.repo
        fi
    elif [ ${MIRROR_URL} == "sjtu" ];then
        if grep -Eqi "^#baseurl" /etc/yum.repos.d/epel*.repo;then
            sed -i.bak -e 's!^metalink=!#metalink=!g' -e 's!^#baseurl=!baseurl=!g' -e 's!https\?://download\.fedoraproject\.org/pub/epel!https://'${MIRROR}'/fedora/epel!g' -e 's!https\?://download\.example/pub/epel!https://'${MIRROR}'/fedora/epel!g' /etc/yum.repos.d/epel*.repo
        elif [ ${OLD_DIR} == 'epel' ];then
            sed -i -e 's|^baseurl=https://'${OLD_MIRROR}'/epel|baseurl=https://'${MIRROR}'/fedora/epel|g' /etc/yum.repos.d/epel*.repo
        elif [ ${OLD_DIR} == 'fedora-epel' ];then
            sed -i -e 's|^baseurl=https://'${OLD_MIRROR}'/fedora-epel|baseurl=https://'${MIRROR}'/fedora/epel|g' /etc/yum.repos.d/epel*.repo
        else
            sed -i -e 's|^baseurl=https://'${OLD_MIRROR}'/fedora/epel|baseurl=https://'${MIRROR}'/fedora/epel|g' /etc/yum.repos.d/epel*.repo
        fi
    else
        if grep -Eqi "^#baseurl" /etc/yum.repos.d/epel*.repo;then
	        sed -i.bak -e 's!^metalink=!#metalink=!g' -e 's!^#baseurl=!baseurl=!g' -e 's!https\?://download\.fedoraproject\.org/pub/epel!https://'${MIRROR}'/epel!g' -e 's!https\?://download\.example/pub/epel!https://'${MIRROR}'/epel!g' /etc/yum.repos.d/epel*.repo
        elif [ ${OLD_DIR} == 'fedora' ];then
            sed -i -e 's|^baseurl=https://'${OLD_MIRROR}'/fedora/epel|baseurl=https://'${MIRROR}'/epel|g' /etc/yum.repos.d/epel*.repo
        elif [ ${OLD_DIR} == 'fedora-epel' ];then
            sed -i -e 's|^baseurl=https://'${OLD_MIRROR}'/fedora-epel|baseurl=https://'${MIRROR}'/epel|g' /etc/yum.repos.d/epel*.repo
        else
            sed -i -e 's|^baseurl=https://'${OLD_MIRROR}'/epel|baseurl=https://'${MIRROR}'/epel|g' /etc/yum.repos.d/epel*.repo
        fi
    fi
    ${COLOR}"更新镜像源中,请稍等..."${END}
    dnf clean all &> /dev/null && dnf makecache &> /dev/null
    ${COLOR}"${OS_ID} ${OS_RELEASE} EPEL源设置完成!"${END}
}

centos7_epel_menu(){
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
9)北京大学镜像源
10)西安交通大学镜像源
11)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-11): " NUM
        case ${NUM} in
        1)
            aliyun
            set_epel_centos7
            ;;
        2)
            huawei
            set_epel_centos7
            ;;
        3)
            tencent
            set_epel_centos7
            ;;
        4)
            tuna
            set_epel_centos7
            ;;
        5)
            sohu
            set_epel_centos7
            ;;
        6)
            nju
            set_epel_centos7
            ;;
        7)
            ustc
            set_epel_centos7
            ;;
        8)
            sjtu
            set_epel_centos7
            ;;
        9)
            pku
            set_epel_centos7
            ;;
        10)
            xjtu
            set_epel_centos7
            ;;
        11)
            break
            ;;
        *)
            ${COLOR}"输入错误,请输入正确的数字(1-11)!"${END}
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
3)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-3): " NUM
        case ${NUM} in
        1)
            rocky8_9_base_menu
            ;;
        2)
            rocky_centos8_9_epel_menu
            ;;
        3)
            break
            ;;
        *)
            ${COLOR}"输入错误,请输入正确的数字(1-3)!"${END}
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
3)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-3): " NUM
        case ${NUM} in
        1)
            if [ ${OS_NAME} == "Stream" ];then
                if [ ${OS_RELEASE_VERSION} == "8" ];then
                    centos_stream8_base_menu
                else
                    if grep -Eqi "^baseurl" /etc/yum.repos.d/centos*.repo;then
                        centos_stream9_base_menu
                    else
                        set_yum_centos_stream9_perl
                    fi
                fi
            else
                centos7_base_menu
            fi
            ;;
        2)
            if [ ${OS_RELEASE_VERSION} == "8" -o ${OS_RELEASE_VERSION} == "9" ];then
                rocky_centos8_9_epel_menu
            else
                centos7_epel_menu
            fi
            ;;
        3)
            break
            ;;
        *)
            ${COLOR}"输入错误,请输入正确的数字(1-3)!"${END}
            ;;
        esac
    done
}

set_apt(){
    OLD_MIRROR=`sed -rn "s@^deb http(.*)://(.*)/ubuntu/? $(lsb_release -cs) main.*@\2@p" /etc/apt/sources.list`
    sed -i.bak 's/'${OLD_MIRROR}'/'${MIRROR}'/g' /etc/apt/sources.list
    if [ ${OS_RELEASE_VERSION} == "18" ];then
	    SECURITY_MIRROR=`sed -rn "s@^deb http(.*)://(.*)/ubuntu $(lsb_release -cs)-security main.*@\2@p" /etc/apt/sources.list`
        sed -i.bak 's/'${SECURITY_MIRROR}'/'${MIRROR}'/g' /etc/apt/sources.list
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
6)南京大学镜像源
7)中科大镜像源
8)上海交通大学镜像源
9)北京大学镜像源
10)西安交通大学镜像源
11)退出
EOF
        echo -e '\E[0m'

        read -p "请输入镜像源编号(1-11): " NUM
        case ${NUM} in
        1)
            aliyun
            set_apt
            ;;
        2)
            huawei
            set_apt
            ;;
        3)
            tencent
            set_apt
            ;;
        4)
            tuna
            set_apt
            ;;
        5)
            netease
            set_apt
            ;;
        6)
            nju
            set_apt
            ;;
        7)
            ustc
            set_apt
            ;;
        8)
            sjtu
            set_apt
            ;;
        9)
            pku
            set_apt
            ;;
        10)
            xjtu
            set_apt
            ;;
        11)
            break
            ;;
        *)
            ${COLOR}"输入错误,请输入正确的数字(1-11)!"${END}
            ;;
        esac
    done
}

set_mirror_repository(){
    if [ ${OS_ID} == "CentOS" ];then
        centos_menu
    elif [ ${OS_ID} == "Rocky" ];then
        rocky_menu
    else
        apt_menu
    fi
}

rocky_centos_minimal_install(){
    ${COLOR}'开始安装“Minimal安装建议安装软件包”,请稍等......'${END}
    yum -y install gcc make autoconf gcc-c++ glibc glibc-devel pcre pcre-devel openssl openssl-devel systemd-devel zlib-devel vim lrzsz tree tmux lsof tcpdump wget net-tools iotop bc bzip2 zip unzip nfs-utils man-pages &> /dev/null
    ${COLOR}"${OS_ID} ${OS_RELEASE} Minimal安装建议安装软件包已安装完成!"${END}
}

ubuntu_minimal_install(){
    ${COLOR}'开始安装“Minimal安装建议安装软件包”,请稍等......'${END}
    apt -y install iproute2 ntpdate tcpdump telnet traceroute nfs-kernel-server nfs-common lrzsz tree openssl libssl-dev libpcre3 libpcre3-dev zlib1g-dev gcc openssh-server iotop unzip zip
    ${COLOR}"${OS_ID} ${OS_RELEASE} Minimal安装建议安装软件包已安装完成!"${END}
}

minimal_install(){
    if [ ${OS_ID} == "CentOS" -o ${OS_ID} == "Rocky" ] &> /dev/null;then
        rocky_centos_minimal_install
    else
        ubuntu_minimal_install
    fi
}

disable_firewall(){
    if [ ${OS_ID} == "CentOS" -o ${OS_ID} == "Rocky" ];then
        rpm -q firewalld &> /dev/null && { systemctl disable --now firewalld &> /dev/null; ${COLOR}"${OS_ID} ${OS_RELEASE} Firewall防火墙已关闭!"${END}; } || ${COLOR}"${OS_ID} ${OS_RELEASE} iptables防火墙已关闭!"${END}
    else
        dpkg -s ufw &> /dev/null && { systemctl disable --now ufw &> /dev/null; ${COLOR}"${OS_ID} ${OS_RELEASE} ufw防火墙已关闭!"${END}; } || ${COLOR}"${OS_ID} ${OS_RELEASE}  没有ufw防火墙服务,不用关闭！"${END}
    fi
}

disable_selinux(){
    if [ ${OS_ID} == "CentOS" -o ${OS_ID} == "Rocky" ];then
        if [ `getenforce` == "Enforcing" ];then
            sed -ri.bak 's/^(SELINUX=).*/\1disabled/' /etc/selinux/config
            ${COLOR}"${OS_ID} ${OS_RELEASE} SELinux已禁用,请重新启动系统后才能生效!"${END}
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
        if [ ${OS_RELEASE_VERSION} == 20 -o ${OS_RELEASE_VERSION} == 22 ];then
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
net.ipv4.tcp_tw_recycle = 0
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
    sysctl -p &> /dev/null
    ${COLOR}"${OS_ID} ${OS_RELEASE} 优化内核参数成功!"${END}
}

optimization_sshd(){
    if [ ${OS_ID} == "CentOS" -o ${OS_ID} == "Rocky" ];then
        sed -ri.bak -e 's/^#(UseDNS).*/\1 no/' -e 's/^(GSSAPIAuthentication).*/\1 no/' /etc/ssh/sshd_config
    else
        sed -ri.bak -e 's/^#(UseDNS).*/\1 no/' -e 's/^#(GSSAPIAuthentication).*/\1 no/' /etc/ssh/sshd_config
    fi
    systemctl restart sshd
    ${COLOR}"${OS_ID} ${OS_RELEASE} SSH已优化完成!"${END}
}

set_sshd_port(){
    disable_selinux
    disable_firewall
    read -p "请输入端口号: " PORT
    sed -i 's/#Port 22/Port '${PORT}'/' /etc/ssh/sshd_config
    ${COLOR}"${OS_ID} ${OS_RELEASE} 更改SSH端口号已完成,请重启系统后生效!"${END}
}

set_centos_alias(){
    ETHNAME=`ip addr | awk -F"[ :]" '/^2/{print $3}'`
    ETHNAME2=`ip addr | awk -F"[ :]" '/^3/{print $3}'`
    read -p "请输入网卡数量（仅支持1个和2个网卡，输入1或2）: " IP_NUM
    if [ ${IP_NUM} == "1" ];then
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

set_alias(){
    if [ ${OS_ID} == "CentOS" -o ${OS_ID} == "Rocky" ];then
        if grep -Eqi "(.*cdnet|.*vie0|.*vie1|.*scandisk)" ~/.bashrc;then
            sed -i -e '/.*cdnet/d'  -e '/.*vie0/d' -e '/.*vie1/d' -e '/.*scandisk/d' ~/.bashrc
            set_centos_alias
        else
            set_centos_alias
        fi
    fi
    if [ ${OS_ID} == "Ubuntu" ];then
        if grep -Eqi "(.*cdnet|.*scandisk)" ~/.bashrc;then
            sed -i -e '/.*cdnet/d' -e '/.*scandisk/d' ~/.bashrc
            set_ubuntu_alias
        else
            set_ubuntu_alias
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
    call setline(3,"#**********************************************************************************************")
    call setline(4,"#Author:        ${AUTHOR}")
    call setline(5,"#QQ:            ${QQ}")
    call setline(6,"#Date:          ".strftime("%Y-%m-%d"))
    call setline(7,"#FileName:      ".expand("%"))
    call setline(8,"#MIRROR:           ${V_MIRROR}")
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
    if [ ${OS_ID} == "CentOS" -o ${OS_ID} == "Rocky" ];then
        rpm -q postfix &> /dev/null || { yum -y install postfix &> /dev/null; systemctl enable --now postfix &> /dev/null; }
        rpm -q mailx &> /dev/null || yum -y install mailx &> /dev/null
    else
        dpkg -s mailutils &> /dev/null || apt -y install mailutils
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

rocky_centos_ps1(){
    C_PS1=$(echo "PS1='\[\e[1;${P_COLOR}m\][\u@\h \W]\\$ \[\e[0m\]'" >> ~/.bashrc)
}

ubuntu_ps1(){
    U_PS1=$(echo 'PS1="\[\e[1;'''${P_COLOR}'''m\]${debian_chroot:+($debian_chroot)}\u@\h:\w\\$ \[\e[0m\]"' >> ~/.bashrc)
}

set_ps1_env(){
    if [ ${OS_ID} == "CentOS" -o ${OS_ID} == "Rocky" ];then
        if grep -Eqi "^PS1" ~/.bashrc;then
            sed -i '/^PS1/d' ~/.bashrc
            rocky_centos_ps1
        else
            rocky_centos_ps1
        fi
    fi
    if [ ${OS_ID} == "Ubuntu" ];then
        if grep -Eqi "^PS1" ~/.bashrc;then
            sed -i '/^PS1/d' ~/.bashrc
            ubuntu_ps1
        else
            ubuntu_ps1
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

set_root_login(){
    read -p "请输入密码: " PASSWORD
    echo ${PASSWORD} |sudo -S sed -ri 's@#(PermitRootLogin )prohibit-password@\1yes@' /etc/ssh/sshd_config
    sudo systemctl restart sshd
    sudo -S passwd root <<-EOF
${PASSWORD}
${PASSWORD}
EOF
    ${COLOR}"${OS_ID} ${OS_RELEASE} root用户登录已设置完成,请重新登录后生效!"${END}
}

ubuntu_remove(){
    apt purge ufw lxd lxd-client lxcfs liblxc-common
    ${COLOR}"${OS_ID} ${OS_RELEASE} 无用软件包卸载完成!"${END}
}

menu(){
    while true;do
        echo -e "\E[$[RANDOM%7+31];1m"
        cat <<-EOF
********************************************************************
*                          初始化脚本菜单                          *
* 1.修改网卡名                     14.更改SSH端口号                *
* 2.修改IP地址和网关地址(单网卡)   15.设置系统别名                 *
* 3.修改IP地址和网关地址(双网卡)   16.设置vimrc配置文件            *
* 4.设置主机名                     17.安装邮件服务并配置邮件       *
* 5.设置镜像仓库                   18.设置PS1(请进入选择颜色)      *
* 6.Minimal安装建议安装软件        19.设置默认文本编辑器为vim      *
* 7.关闭防火墙                     20.设置history格式              *
* 8.禁用SELinux                    21.禁用ctrl+alt+del重启         *
* 9.禁用SWAP                       22.Ubuntu设置root用户登录       *
* 10.设置系统时区                  23.Ubuntu卸载无用软件包         *
* 11.优化资源限制参数              24.重启系统                     *
* 12.优化内核参数                  25.关机                         *
* 13.优化SSH                       26.退出                         *
********************************************************************
EOF
        echo -e '\E[0m'

        read -p "请选择相应的编号(1-26): " choice
        case ${choice} in
        1)
            set_eth
            ;;
        2)
            set_ip
            ;;
        3)
            set_dual_ip
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
            disable_firewall
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
            optimization_sshd
            ;;
        14)
            set_sshd_port
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
            set_root_login
            ;;
        23)
            ubuntu_remove
            ;;
        24)
            reboot
            ;;
        25)
            shutdown -h now
            ;;
        26)
            break
            ;;
        *)
            ${COLOR}"输入错误,请输入正确的数字(1-26)!"${END}
            ;;
        esac
    done
}

main(){
    os
    menu
}

main
