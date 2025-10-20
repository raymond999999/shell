#!/bin/bash
#
#**********************************************************************************************
#Author:        Raymond
#QQ:            88563128
#Date:          2022-01-09
#FileName:      check_nginx.sh
#URL:           raymond.blog.csdn.net
#Description:   The test script
#Copyright (C): 2022 All rights reserved
#*********************************************************************************************
err=0
for k in $(seq 1 3);do
    check_code=$(pgrep nginx)
    if [[ $check_code == "" ]]; then
        err=$(expr $err + 1)
        sleep 1
        continue
    else
        err=0
        break
    fi
done

if [[ $err != "0" ]]; then
    echo "systemctl stop keepalived"
    /usr/bin/systemctl stop keepalived
    exit 1
else
    exit 0
fi
