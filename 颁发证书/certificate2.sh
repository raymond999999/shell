#!/bin/bash
#
#**********************************************************************************************
#Author:        Raymond
#QQ:            88563128
#Date:          2021-11-19
#FileName:      certificate2.sh
#URL:           raymond.blog.csdn.net
#Description:   The test script
#Copyright (C): 2021 All rights reserved
#*********************************************************************************************
#证书存放目录
DIR=/data

#每个证书信息
declare -A CERT_INFO
CERT_INFO=([subject0]="/O=raymond/CN=ca.raymonds.cc" \
           [keyfile0]="cakey.pem" \
           [crtfile0]="cacert.pem" \
           [key0]=2048 \
           [expire0]=3650 \
           [serial0]=0    \
           [subject1]="/C=CN/ST=shaanxi/L=xi'an/O=it/CN=master.raymonds.cc" \
           [keyfile1]="master.key" \
           [crtfile1]="master.crt" \
           [key1]=2048 \
           [expire1]=365
           [serial1]=1 \
           [csrfile1]="master.csr" \
           [subject2]="/C=CN/ST=shaanxi/L=xi'an/O=sales/CN=slave.raymonds.cc" \
           [keyfile2]="slave.key" \
           [crtfile2]="slave.crt" \
           [key2]=2048 \
           [expire2]=365 \
           [serial2]=2 \
           [csrfile2]="slave.csr"   )

COLOR="echo -e \\E[1;32m"
END="\\E[0m"

#证书编号最大值
N=`echo ${!CERT_INFO[*]} |grep -o subject|wc -l`

cd $DIR 

for((i=0;i<N;i++));do
    if [ $i -eq 0 ] ;then
        openssl req  -x509 -newkey rsa:${CERT_INFO[key${i}]} -subj ${CERT_INFO[subject${i}]} \
            -set_serial ${CERT_INFO[serial${i}]} -keyout ${CERT_INFO[keyfile${i}]} -nodes \
	    -days ${CERT_INFO[expire${i}]}  -out ${CERT_INFO[crtfile${i}]} &>/dev/null
        
    else 
        openssl req -newkey rsa:${CERT_INFO[key${i}]} -nodes -subj ${CERT_INFO[subject${i}]} \
            -keyout ${CERT_INFO[keyfile${i}]}   -out ${CERT_INFO[csrfile${i}]} &>/dev/null

        openssl x509 -req -in ${CERT_INFO[csrfile${i}]}  -CA ${CERT_INFO[crtfile0]} \
	    -CAkey ${CERT_INFO[keyfile0]}  -set_serial ${CERT_INFO[serial${i}]}  \
	    -days ${CERT_INFO[expire${i}]} -out ${CERT_INFO[crtfile${i}]} &>/dev/null
    fi
    $COLOR"**************************************生成证书信息**************************************"$END
    openssl x509 -in ${CERT_INFO[crtfile${i}]} -noout -subject -dates -serial
    echo 
done
chmod 600 *.key
echo  "证书生成完成"
$COLOR"**************************************生成证书文件如下**************************************"$END
echo "证书存放目录: "$DIR
echo "证书文件列表: "`ls $DIR`
