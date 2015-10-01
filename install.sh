#!/bin/sh

# Check running user
USERID=$(id -u)
if [ $USERID -ne 0 ] ; then
	echo 'This program must be run as root'
	exit 1
fi

# Create directories
mkdir /etc/blstools 2> /dev/null
mkdir /var/log/blstools 2> /dev/null
mkdir /etc/blstools/func-scripts 2> /dev/null
mkdir /etc/logrotate.d 2> /dev/null

# Install scripts 
cp init.d/* /etc/init.d
cp default/* /etc/default
cp logrotate.d/* /etc/logrotate.d

# Install lsmonitor daemon
update-rc.d -f lsmonitor remove
update-rc.d lsmonitor defaults 99 00

