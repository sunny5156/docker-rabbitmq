#!/bin/bash

IS_EXSIT=`sudo /usr/sbin/rabbitmqctl list_users |grep super | wc -l`

if [ $IS_EXSIT -eq  0 ];then
    sudo /usr/sbin/rabbitmqctl add_user super super 
    sudo /usr/sbin/rabbitmqctl set_user_tags  super administrator
fi
 