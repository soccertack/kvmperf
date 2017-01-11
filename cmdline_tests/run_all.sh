#!/bin/bash

TEST_LEVEL=${1:-"L2"}
L0_IP="10.10.1.2"
L1_IP="10.10.1.100"
L2_IP="10.10.1.101"
ME=jintackl
TEST_USER="root"

echo "TEST LEVEL: $TEST_LEVEL"
if [ $TEST_LEVEL == "L2" ] ; then
	TARGET_IP=$L2_IP
	KVMPERF_PATH="/root/kvmperf"
elif [ $TEST_LEVEL == "L1" ] ; then
	TARGET_IP=$L1_IP
	KVMPERF_PATH="/root/kvmperf"
elif [ $TEST_LEVEL == "L0" ] ; then
	TARGET_IP=$L0_IP
	KVMPERF_PATH="/users/$ME/kvmperf"
	TEST_USER=$ME
else
	echo "Usage: ./run_all [L0|L1|l2]"
	exit
fi
echo "TARGET IP: $TARGET_IP"

echo "Make sure that you consumed memory!"
#TODO: ask before delete
sudo rm *.txt

# mysql should be the first one in the list
TESTS="mysql netperf apache memcached"
SERVICES="mysql netperf apache2 memcached"

TESTS=( $TESTS )
SERVICES=( $SERVICES )
CMD_PATH=$KVMPERF_PATH/cmdline_tests
LOCAL_PATH=$KVMPERF_PATH/localtests
L0_QEMU_PATH="/srv/vm/qemu/scripts/qmp"
L1_QEMU_PATH="/root/vm/qemu/scripts/qmp"

if [ $TEST_LEVEL != "L0" ] ; then
	#Isolate vcpus
	ssh $ME@$L0_IP "pushd ${L0_QEMU_PATH};sudo ./isolate_vcpus.sh"
	if [ $TEST_LEVEL != "L1" ] ; then
		#Isolate L2 vcpus if we have
		ssh root@$L1_IP "pushd ${L1_QEMU_PATH};./isolate_vcpus.sh"
	fi
fi

# Run local tests
ssh $TEST_USER@$TARGET_IP "pushd ${LOCAL_PATH};rm *.txt"
ssh $TEST_USER@$TARGET_IP "pushd ${LOCAL_PATH};./run_all.sh 0 3 0 10"

# Prepare tests
__i=0
for TEST in ${TESTS[@]}; do
	sudo ./${TEST}_install.sh
	ssh root@$TARGET_IP "${CMD_PATH}/${TESTS[$__i]}_install.sh"
	ssh root@$TARGET_IP "service ${SERVICES[$__i]} stop"
	ssh root@$TARGET_IP "service ${SERVICES[$__i]} start"
	__i=$(($__i+1))
done

# Allow memcached and mysql to get requests from servers
ssh root@$TARGET_IP "sed -i 's/^-l/#-l/' /etc/memcached.conf"
ssh root@$TARGET_IP "sed -i 's/^bind/#bind/' /etc/mysql/my.cnf"

# Run mysql
ssh root@$TARGET_IP "pushd ${CMD_PATH};./mysql.sh cleanup"
ssh root@$TARGET_IP "pushd ${CMD_PATH};./mysql.sh prep"
sudo ./mysql.sh run $TARGET_IP
ssh root@$TARGET_IP "pushd ${CMD_PATH};./mysql.sh cleanup"

# Run tests except mysql
__i=1
for TEST in ${TESTS[@]}; do
	./$TEST.sh $TARGET_IP
	__i=$(($__i+1))
done

