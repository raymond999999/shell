#!/bin/bash
#
#**********************************************************************************
#Author:        Raymond
#QQ:            88563128
#MP:            Raymond运维
#Date:          2025-10-19
#FileName:      reset_kylin_server.sh
#URL:           https://wx.zsxq.com/group/15555885545422
#Description:   The reset linux system initialization script supports 
#               “Kylin Server v10 and v11“ operating systems.
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
    sudo systemctl restart sshd
    sudo -S passwd root <<-EOF
${PASSWORD}
${PASSWORD}
EOF
    ${COLOR}"${PRETTY_NAME}操作系统，root用户登录已设置完成，请重新登录后生效！"${END}
}

set_kylin_eth(){
    if grep -Eqi "(net\.ifnames|biosdevname)" /etc/default/grub;then
        ${COLOR}"${PRETTY_NAME}操作系统，网卡名配置文件已修改，不用修改！"${END}
    else
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
        ${COLOR}"${PRETTY_NAME}操作系统，网卡名已修改成功，10秒后，机器会自动重启！"${END}
        sleep 10 && shutdown -r now
    fi
}

set_eth(){
    ETH_PREFIX_NAME=`ip addr | awk -F"[ :]" '/^2/{print $3}' | tr -d "[:digit:]"`
    if [ ${ETH_PREFIX_NAME} == "eth" ];then
        ${COLOR}"${PRETTY_NAME}操作系统，网卡名已修改，不用设置！"${END}
    else
        set_kylin_eth
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

set_network_eth0(){
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
}

set_network_eth1(){
    ETHNAME2=`ip addr | awk -F"[ :]" '/^3/{print $3}'`
    while true; do
        read -p "请输入第二块网卡IP地址: " IP2
        check_ip ${IP2}
        [ $? -eq 0 ] && break
    done
    read -p "请输入子网掩码位数: " PREFIX2
    cat > /etc/sysconfig/network-scripts/ifcfg-${ETHNAME2} <<-EOF
NAME=${ETHNAME2}
DEVICE=${ETHNAME2}
ONBOOT=yes
BOOTPROTO=none
TYPE=Ethernet
IPADDR=${IP2}
PREFIX=${PREFIX2}
EOF
}

set_single_network(){
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
}

set_dual_network(){
    ETHNAME=`ip addr | awk -F"[ :]" '/^2/{print $3}'`
    ETHNAME2=`ip addr | awk -F"[ :]" '/^3/{print $3}'`
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
    cat > /etc/sysconfig/network-scripts/ifcfg-${ETHNAME2} <<-EOF
NAME=${ETHNAME2}
DEVICE=${ETHNAME2}
ONBOOT=yes
BOOTPROTO=none
TYPE=Ethernet
IPADDR=${IP2}
PREFIX=${PREFIX2}
EOF
}

set_network(){
    IP_NUM=`ip addr | awk -F"[: ]" '{print $1}' | grep -v '^$' | wc -l`
    if [ ${MAIN_VERSION_ID} == 10 ];then
        if [ ${IP_NUM} == "2" ];then
            set_single_network
        else
            set_dual_network
        fi
        ${COLOR}"${PRETTY_NAME}操作系统，网络已设置成功，10秒后，机器会自动重启！"${END}
	    sleep 10 && shutdown -r now
    else
        if [ ${IP_NUM} == "2" ];then
            set_network_eth0
        else
            set_network_eth0
            set_network_eth1
        fi
        ${COLOR}"${PRETTY_NAME}操作系统，网络已设置成功，请重新启动系统后生效！"${END}
    fi
}

set_hostname(){
    read -p "请输入主机名: " HOST
    hostnamectl set-hostname ${HOST}
    ${COLOR}"${PRETTY_NAME}操作系统，主机名设置成功，请重新登录生效！"${END}
}

minimal_install(){
    ${COLOR}'开始安装“Minimal安装建议安装软件包”，请稍等......'${END}
    yum install -y vim lrzsz tree tmux lsof tcpdump wget net-tools iotop bc bzip2 zip unzip man-pages &> /dev/null
    ${COLOR}"${PRETTY_NAME}操作系统，Minimal安装建议安装软件包已安装完成!"${END}
}

disable_firewalls(){
    rpm -q firewalld &> /dev/null && { systemctl disable --now firewalld &> /dev/null; ${COLOR}"${PRETTY_NAME}操作系统，Firewall防火墙已关闭！"${END}; } || ${COLOR}"${PRETTY_NAME}操作系统，默认没有安装Firewall防火墙服务，不要设置!"${END}
}

disable_selinux(){
    if [ `getenforce` == "Enforcing" ];then
        sed -ri.bak 's/^(SELINUX=).*/\1disabled/' /etc/selinux/config
        setenforce 0
        ${COLOR}"${PRETTY_NAME}操作系统，SELinux已禁用，请重新启动系统后才能永久生效！"${END}
    else
        ${COLOR}"${PRETTY_NAME}操作系统，SELinux已被禁用，不用设置！"${END}
    fi
}

set_swap(){
    systemctl mask swap.target &> /dev/null
    swapoff -a
    ${COLOR}"${PRETTY_NAME}操作系统，禁用swap已设置成功，请重启系统后生效！"${END}
}

set_localtime(){
    timedatectl set-timezone Asia/Shanghai
    echo 'Asia/Shanghai' >/etc/timezone
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
    sed -ri.bak -e 's/^#(UseDNS).*/\1 no/' -e 's/^(GSSAPIAuthentication).*/\1 no/' /etc/ssh/sshd_config
    systemctl restart sshd
    ${COLOR}"${PRETTY_NAME}操作系统，SSH已优化完成！"${END}
}

set_ssh_port(){
    disable_selinux
    disable_firewalls
    read -p "请输入端口号: " PORT
    sed -i 's/#Port 22/Port '${PORT}'/' /etc/ssh/sshd_config
	systemctl restart sshd
    ${COLOR}"${PRETTY_NAME}操作系统，更改SSH端口号已完成，请重新登陆后生效！"${END}
}

set_base_alias(){
    ETHNAME=`ip addr | awk -F"[ :]" '/^2/{print $3}'`
    ETHNAME2=`ip addr | awk -F"[ :]" '/^3/{print $3}'`
    IP_NUM=`ip addr | awk -F"[: ]" '{print $1}' | grep -v '^$' | wc -l`
    if [ ${IP_NUM} == "2" ];then
        cat >>~/.bashrc <<-EOF
alias cdnet="cd /etc/sysconfig/network-scripts"
alias cdrepo="cd /etc/yum.repos.d"
alias vie0="vim /etc/sysconfig/network-scripts/ifcfg-${ETHNAME}"
EOF
    else	
        cat >>~/.bashrc <<-EOF
alias cdnet="cd /etc/sysconfig/network-scripts"
alias cdrepo="cd /etc/yum.repos.d"
alias vie0="vim /etc/sysconfig/network-scripts/ifcfg-${ETHNAME}"
alias vie1="vim /etc/sysconfig/network-scripts/ifcfg-${ETHNAME2}"
EOF
    fi
    DISK_NAME=`lsblk|awk -F" " '/disk/{printf $1}' | cut -c1-4`
    if [ ${DISK_NAME} == "sda" ];then
        cat >>~/.bashrc <<-EOF
alias scandisk="echo '- - -' > /sys/class/scsi_host/host0/scan;echo '- - -' > /sys/class/scsi_host/host1/scan;echo '- - -' > /sys/class/scsi_host/host2/scan"
EOF
    fi
    ${COLOR}"${PRETTY_NAME}操作系统，系统别名已设置成功，请重新登陆后生效！"${END}
}

set_alias(){
    if grep -Eqi "(.*cdnet|.*cdrepo|.*vie0|.*vie1|.*scandisk)" ~/.bashrc;then
        sed -i -e '/.*cdnet/d'  -e '/.*cdrepo/d' -e '/.*vie0/d' -e '/.*vie1/d' -e '/.*scandisk/d' ~/.bashrc
        set_base_alias
    else
        set_base_alias
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
    rpm -q postfix &> /dev/null || { ${COLOR}"安装postfix服务，请稍等......"${END};yum -y install postfix &> /dev/null; systemctl enable --now postfix &> /dev/null; }
    rpm -q mailx &> /dev/null || { ${COLOR}"安装mailx服务，请稍等......"${END};yum -y install mailx &> /dev/null; }
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

set_base_ps1(){
    C_PS1=$(echo "PS1='\[\e[1;${P_COLOR}m\][\u@\h \W]\\$ \[\e[0m\]'" >> ~/.bashrc)
}

set_ps1_env(){
    if grep -Eqi "^PS1" ~/.bashrc;then
        sed -i '/^PS1/d' ~/.bashrc
        set_base_ps1
    else
        set_base_ps1
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

menu(){
    while true;do
        echo -e "\E[$[RANDOM%7+31];1m"
        cat <<-EOF
********************************************************
*            系统初始化脚本菜单                        *
* 1.设置root用户登录   13.更改SSH端口号                *
* 2.修改网卡名         14.设置系统别名                 *
* 3.设置网络           15.设置vimrc配置文件            *
* 4.设置主机名         16.安装邮件服务并配置           *
* 5.建议安装软件       17.设置PS1(请进入选择颜色)      *
* 6.关闭防火墙         18.设置默认文本编辑器为vim      *
* 7.禁用SELinux        19.设置history格式              *
* 8.禁用SWAP           20.禁用ctrl+alt+del重启系统功能 *
* 9.设置系统时区       21.重启系统                     *
* 10.优化资源限制参数  22.关机                         *
* 11.优化内核参数      23.退出                         *
* 12.优化SSH                                           *
********************************************************
EOF
        echo -e '\E[0m'

        read -p "请选择相应的编号(1-23): " choice
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
                minimal_install
            else
                ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录后再执行此操作！"${END}
            fi
            ;;
        6)
            if [ ${LOGIN_USER} == "root" ];then
                disable_firewalls
            else
                ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录后再执行此操作！"${END}
            fi
            ;;
        7)
            if [ ${LOGIN_USER} == "root" ];then
                disable_selinux
            else
                ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录后再执行此操作！"${END}
            fi
            ;;
        8)
            if [ ${LOGIN_USER} == "root" ];then
                set_swap
            else
                ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录后再执行此操作！"${END}
            fi
            ;;
        9)
            if [ ${LOGIN_USER} == "root" ];then
                set_localtime
            else
                ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录后再执行此操作！"${END}
            fi
            ;;
        10)
            if [ ${LOGIN_USER} == "root" ];then
                set_limits
            else
                ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录后再执行此操作！"${END}
            fi
            ;;
        11)
            if [ ${LOGIN_USER} == "root" ];then
                set_kernel
            else
                ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录后再执行此操作！"${END}
            fi
            ;;
        12)
            if [ ${LOGIN_USER} == "root" ];then
                optimization_ssh
            else
                ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录后再执行此操作！"${END}
            fi
            ;;
        13)
            if [ ${LOGIN_USER} == "root" ];then
                set_ssh_port
            else
                ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录后再执行此操作！"${END}
            fi
            ;;
        14)
            if [ ${LOGIN_USER} == "root" ];then
                set_alias
            else
                ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录后再执行此操作！"${END}
            fi
            ;;
        15)
            if [ ${LOGIN_USER} == "root" ];then
                set_vimrc
            else
                ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录后再执行此操作！"${END}
            fi
            ;;
        16)
            if [ ${LOGIN_USER} == "root" ];then
                set_mail
            else
                ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录后再执行此操作！"${END}
            fi
            ;;
        17)
            if [ ${LOGIN_USER} == "root" ];then
                set_ps1
            else
                ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录后再执行此操作！"${END}
            fi
            ;;
        18)
            if [ ${LOGIN_USER} == "root" ];then
                set_vim_env
            else
                ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录后再执行此操作！"${END}
            fi
            ;;
        19)
            if [ ${LOGIN_USER} == "root" ];then
                set_history_env
            else
                ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录后再执行此操作！"${END}
            fi
            ;;
        20)
            if [ ${LOGIN_USER} == "root" ];then
                disable_restart
            else
                ${COLOR}"当然登录用户是${LOGIN_USER}，请使用root用户登录或设置root用户登录后再执行此操作！"${END}
            fi
            ;;
        21)
            if [ ${LOGIN_USER} == "root" ];then
                shutdown -r now
            else
                sudo shutdown -r now
            fi
            ;;
        22)
            if [ ${LOGIN_USER} == "root" ];then
                shutdown -h now
            else
                sudo shutdown -h now
            fi
            ;;
        23)
            break
            ;;
        *)
            ${COLOR}"输入错误，请输入正确的数字(1-23)！"${END}
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
if [ ${MAIN_NAME} == "Kylin" ];then
    if [ ${MAIN_VERSION_ID} == 10 -o ${MAIN_VERSION_ID} == 11 ];then
        main
    fi
else
    ${COLOR}"此脚本不支持${PRETTY_NAME}操作系统！"${END}
fi
