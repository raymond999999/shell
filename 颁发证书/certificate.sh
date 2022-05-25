#!/bin/bash
#
#**********************************************************************************************
#Author:        Raymond
#QQ:            88563128
#Date:          2021-11-16
#FileName:      certificate.sh
#URL:           raymond.blog.csdn.net
#Description:   The test script
#Copyright (C): 2021 All rights reserved
#*********************************************************************************************
CA_SUBJECT="/O=raymonds/CN=ca.raymonds.cc"
CA_EXPIRE=3650
SUBJECT="/C=CN/ST=Shaanxi/L=xi'an/O=raymonds/CN=*.raymonds.cc"
SERIAL=01
EXPIRE=365
FILE=httpd

openssl req  -x509 -newkey rsa:2048 -subj ${CA_SUBJECT} -keyout ca.key -nodes -days ${CA_EXPIRE} -out ca.crt

openssl req -newkey rsa:2048 -nodes -keyout ${FILE}.key  -subj ${SUBJECT} -out ${FILE}.csr

openssl x509 -req -in ${FILE}.csr  -CA ca.crt -CAkey ca.key -set_serial ${SERIAL}  -days ${EXPIRE} -out ${FILE}.crt

chmod 600 ${FILE}.key ca.key
