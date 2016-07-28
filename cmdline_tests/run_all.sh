#!/bin/bash

TARGET_IP="10.10.1.100"

#TODO: ask before delete
sudo rm *.txt

# mysql should be the first one in the list
TESTS="mysql netperf apache memcached"
SERVICES="mysql netserver apache2 memcached"

TESTS=( $TESTS )
SERVICES=( $SERVICES )
KVMPERF_PATH="/root/kvmperf/cmdline_tests"

# Prepare tests
__i=0
for TEST in ${TESTS[@]}; do
	sudo ./${TEST}_install.sh
	ssh root@$TARGET_IP "${KVMPERF_PATH}/${TESTS[$__i]}_install.sh"
	ssh root@$TARGET_IP "service ${SERVICES[$__i]} stop"
	ssh root@$TARGET_IP "service ${SERVICES[$__i]} start"
	__i=$(($__i+1))
done

# Allow memcached to get requests from servers
ssh root@$TARGET_IP "sed -i 's/^-l/#-l/' /etc/memcached.conf"
ssh root@$TARGET_IP "sed -i 's/^bind/#bind/' /etc/mysql/my.cnf"

# Run mysql
ssh root@$TARGET_IP "pushd ${KVMPERF_PATH};./mysql.sh cleanup"
ssh root@$TARGET_IP "pushd ${KVMPERF_PATH};./mysql.sh prep"
sudo ./mysql.sh run $TARGET_IP
ssh root@$TARGET_IP "pushd ${KVMPERF_PATH};./mysql.sh cleanup"

# Run tests except mysql
__i=1
for TEST in ${TESTS[@]}; do
	./$TEST.sh $TARGET_IP
	__i=$(($__i+1))
done

