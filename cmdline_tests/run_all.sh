#!/bin/bash

TEST_LEVEL=${1:-"L2"}

source ./check.sh $TEST_LEVEL

L0_IP="10.10.1.2"
L1_IP="10.10.1.100"
L2_IP="10.10.1.101"
#PP: PV-Passthrough
L2_PP_IP="10.10.1.201"
ME=jintackl
TEST_USER="root"

LOCAL=0
IDX_OFFSET=3

# mysql should be the first one in the list
TESTS="mysql netperf-rr netperf-stream netperf-maerts apache memcached nginx"
SERVICES="mysql netperf netperf netperf apache2 memcached nginx"

TEST_LIST=( $TESTS )

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

TEST_DESC=""
function move_results()
{
	mv *.txt $1
}

function ctrl_c()
{
        echo "** Trapped CTRL-C"
	move_results $TEST_DESC/abort
}

function print_target_tests()
{
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
}

function setup_ip_kvmpath()
{
	echo "TEST LEVEL: $TEST_LEVEL"
	if [ $TEST_LEVEL == "L2" ] ; then
		TARGET_IP=$L2_IP
		KVMPERF_PATH="/root/kvmperf"
	elif [ $TEST_LEVEL == "L2-PP" ] ; then
		TARGET_IP=$L2_PP_IP
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
}

function install_tests()
{
	__i=0
	for TEST in ${TESTS[@]}; do
		if [[ ${TEST_ARRAY[$__i]} == 1 ]]; then
			PKG=$(echo "$TEST" | cut -d- -f1)
			sudo ./${PKG}_install.sh
			ssh $TEST_USER@$TARGET_IP "sudo ${CMD_PATH}/${PKG}_install.sh"
		fi
		__i=$(($__i+1))
	done

	# Allow memcached and mysql to get requests from servers
	ssh $TEST_USER@$TARGET_IP "sudo sed -i 's/^-l/#-l/' /etc/memcached.conf"
	ssh $TEST_USER@$TARGET_IP "sudo sed -i 's/^bind/#bind/' /etc/mysql/my.cnf"
}

function run_tests()
{
	# Run local tests
	if [[ $LOCAL == 1 ]]; then
		ssh $TEST_USER@$TARGET_IP "pushd ${LOCAL_PATH};rm *.txt"
		ssh $TEST_USER@$TARGET_IP "pushd ${LOCAL_PATH};sudo ./run_all.sh 0 3 0 10"
	fi

	# Run tests
	__i=0
	for TEST in ${TESTS[@]}; do
		if [[ ${TEST_ARRAY[$__i]} == 1 ]]; then
			# Commands for mysql is a bit different from others.
			if [[ $__i == 0 ]]; then
				./mysql.sh run $TARGET_IP $TEST_USER $CMD_PATH
			else
				ssh $TEST_USER@$TARGET_IP "sudo service ${SERVICES[$__i]} start"
				./$TEST.sh $TARGET_IP
				ssh $TEST_USER@$TARGET_IP "sudo service ${SERVICES[$__i]} stop"
			fi
		fi
		__i=$(($__i+1))
	done
}

# Init TEST_ARRAY
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
	elif [[ $number -lt 10  ]]; then
		idx=$(($number-$IDX_OFFSET))
		TEST_ARRAY[$idx]=1
	else
		echo "Wrong test number"
	fi
	echo ""
}

while :
do
	# This is an inline function, and it has 'break' in it.
	show_tests
done

print_target_tests

setup_ip_kvmpath

#TODO: ask before delete
sudo rm *.txt

TESTS=( $TESTS )
SERVICES=( $SERVICES )
CMD_PATH=$KVMPERF_PATH/cmdline_tests
LOCAL_PATH=$KVMPERF_PATH/localtests

install_tests

echo -n "Enter test name: "
read TEST_DESC
mkdir $TEST_DESC
echo -n "How many times to repeat? "
read repeat

for i in `seq 1 $repeat`; do
	mkdir $TEST_DESC/$i
	run_tests
	move_results $TEST_DESC/$i
done
