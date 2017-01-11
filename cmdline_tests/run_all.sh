#!/bin/bash

TEST_LEVEL=${1:-"L2"}
L0_IP="10.10.1.2"
L1_IP="10.10.1.100"
L2_IP="10.10.1.101"

echo "TEST LEVEL: $TEST_LEVEL"
if [ $TEST_LEVEL == "L2" ] ; then
	TARGET_IP=$L2_IP
elif [ $TEST_LEVEL == "L1" ] ; then
	TARGET_IP=$L1_IP
elif [ $TEST_LEVEL == "L0" ] ; then
	TARGET_IP=$L0_IP
else
	echo "Usage: ./run_all [L0|L1|l2]"
	exit
fi
echo "TARGET IP: $TARGET_IP"

echo "Make sure that you consumed memory!"
#TODO: ask before delete
sudo rm *.txt

sudo apt-get update

# mysql should be the first one in the list
TESTS="mysql netperf apache memcached"
SERVICES="mysql netperf apache2 memcached"

USER=jintackl
TESTS=( $TESTS )
SERVICES=( $SERVICES )
KVMPERF_PATH="/root/kvmperf/cmdline_tests"
LOCAL_PATH="/root/kvmperf/localtests"
L0_QEMU_PATH="/srv/vm/qemu/scripts/qmp"
L1_QEMU_PATH="/root/vm/qemu/scripts/qmp"

#Isolate vcpus
ssh $USER@$L0_IP "pushd ${L0_QEMU_PATH};sudo ./isolate_vcpus.sh"
#Isolate L2 vcpus if we have
ssh root@$L1_IP "pushd ${L1_QEMU_PATH};./isolate_vcpus.sh"

# Run local tests
ssh root@$TARGET_IP "pushd ${LOCAL_PATH};rm *.txt"
ssh root@$TARGET_IP "pushd ${LOCAL_PATH};./run_all.sh 3 1 0 4"

# Prepare tests
__i=0
for TEST in ${TESTS[@]}; do
	sudo ./${TEST}_install.sh
	ssh root@$TARGET_IP "${KVMPERF_PATH}/${TESTS[$__i]}_install.sh"
	ssh root@$TARGET_IP "service ${SERVICES[$__i]} stop"
	ssh root@$TARGET_IP "service ${SERVICES[$__i]} start"
	__i=$(($__i+1))
done

# Allow memcached and mysql to get requests from servers
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

