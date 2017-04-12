#!/bin/bash

TEST_LEVEL=${1:-"L2"}

source ./check.sh $TEST_LEVEL

L0_IP="10.10.1.2"
L1_IP="10.10.1.100"
L2_IP="10.10.1.101"
ME=jintackl
TEST_USER="root"

LOCAL=0
IDX_OFFSET=3

TESTS="mysql netperf apache memcached nginx"
TEST_LIST=( $TESTS )

__i=0
for TEST in ${TESTS[@]}; do
	TEST_ARRAY[$__i]=0
	__i=$(($__i+1))
done

show_tests() {
	i=0
	echo [$i] "==== Start Test ====="

	i=$(($i+1))
	echo [$i] "All"

	i=$(($i+1))
	if [[ $LOCAL == 1 ]]; then
		echo -n "*"
	fi
	echo [$i] "local tests (hackbench and kernbench)"

	for TEST in ${TEST_LIST[@]}; do
		i=$(($i+1))
		idx=$(($i-$IDX_OFFSET))
		if [[ ${TEST_ARRAY[$idx]} == 1 ]]; then
			echo -n "*" 
		fi
		echo [$i] $TEST
	done

	echo -n "Type test number: "
	read number

	if [[ $number == 0 ]]; then
		echo "Begin test"
		break;
	elif [[ $number == "" ]]; then
		echo "Begin test"
		break;
	elif [[ $number == 1 ]]; then
		__i=0
		for TEST in ${TESTS[@]}; do
			TEST_ARRAY[$__i]=1
			__i=$(($__i+1))
		done
		LOCAL=1
	elif [[ $number == 2 ]]; then
		LOCAL=1
	elif [[ $number -lt 8  ]]; then
		idx=$(($number-$IDX_OFFSET))
		TEST_ARRAY[$idx]=1
	else
		echo "Wrong test number"
	fi
	echo ""
}

while :
do
	show_tests
done

if [[ $LOCAL == 1 ]]; then
	echo "Test Local"
fi
__i=0
for TEST in ${TESTS[@]}; do
	if [[ ${TEST_ARRAY[$__i]} == 1 ]]; then
		echo "Test "${TEST_LIST[$__i]}
	fi
	__i=$(($__i+1))
done

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

# Run local tests
if [[ $LOCAL == 1 ]]; then
	ssh $TEST_USER@$TARGET_IP "pushd ${LOCAL_PATH};rm *.txt"
	ssh $TEST_USER@$TARGET_IP "pushd ${LOCAL_PATH};sudo ./run_all.sh 0 3 0 10"
fi

# Prepare tests
__i=0
for TEST in ${TESTS[@]}; do
	if [[ ${TEST_ARRAY[$__i]} == 1 ]]; then
		sudo ./${TEST}_install.sh
		ssh $TEST_USER@$TARGET_IP "sudo ${CMD_PATH}/${TESTS[$__i]}_install.sh"
		ssh $TEST_USER@$TARGET_IP "sudo service ${SERVICES[$__i]} stop"
		ssh $TEST_USER@$TARGET_IP "sudo service ${SERVICES[$__i]} start"
	fi
	__i=$(($__i+1))
done

# Allow memcached and mysql to get requests from servers
ssh $TEST_USER@$TARGET_IP "sudo sed -i 's/^-l/#-l/' /etc/memcached.conf"
ssh $TEST_USER@$TARGET_IP "sudo sed -i 's/^bind/#bind/' /etc/mysql/my.cnf"

# Run tests
__i=0
for TEST in ${TESTS[@]}; do
	if [[ ${TEST_ARRAY[$__i]} == 1 ]]; then
		# Commands for mysql is a bit different from others.
		if [[ $__i == 0 ]]; then
			ssh $TEST_USER@$TARGET_IP "pushd ${CMD_PATH};sudo ./mysql.sh cleanup"
			ssh $TEST_USER@$TARGET_IP "pushd ${CMD_PATH};sudo ./mysql.sh prep"
			sudo ./mysql.sh run $TARGET_IP
			ssh $TEST_USER@$TARGET_IP "pushd ${CMD_PATH};sudo ./mysql.sh cleanup"
		else
			./$TEST.sh $TARGET_IP
		fi
	fi
	__i=$(($__i+1))
done

