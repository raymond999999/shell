#!/bin/bash
#
#***************************************************************************************************
#Author:        Raymond
#QQ:            88563128
#Date:          2024-05-06
#FileName:      remove_snap.sh
#MIRROR:        raymond.blog.csdn.net
#Description:   remove_snap for Ubuntu 20.04/22.04
#Copyright (C): 2024 All rights reserved
#***************************************************************************************************
COLOR="echo -e \\033[01;31m"
END='\033[0m'

ubuntu_remove_snap(){
    dpkg -s snapd &> /dev/null || { ${COLOR}"snap已卸载！"${END};exit; }
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
}

main(){
    ubuntu_remove_snap
}

main