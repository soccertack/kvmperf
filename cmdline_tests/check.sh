#!/bin/bash

#########
TEST_KERNEL="4.10.0-rc3"
TEST_QEMU="2.3.50"
#########

# L0, L1 or L2
TEST_LEVEL=$1
USER=jintackl

MACHINE=`uname -m`
KERNEL=`uname -r`
KERNEL_CMD='uname -r'

QEMU_CMD_x86='qemu-system-x86_64 --version'
QEMU_CMD_ARM='/srv/vm/qemu-system-aarch64 --version'
if [[ "$MACHINE" == "x86_64" ]]; then
	QEMU_CMD=$QEMU_CMD_x86
else
	QEMU_CMD=$QEMU_CMD_ARM
fi

function proceed()
{
	read -r -p "$1 [y/N] " response
	case "$response" in
	    [yY][eE][sS]|[yY]) 
		;;
	    *)
		exit
		;;
	esac
}

function kernel_ok()
{
	if [[ $1 == $TEST_KERNEL  ]]; then
		echo "KERNEL OK"
	else
		echo "**** WARNING: CHECK KERNEL VERSION"
		proceed "Want to Proceed?"
	fi
}

function qemu_ok()
{
	if [[ $1 == $TEST_QEMU ]]; then
		echo "QEMU OK"
	else
		echo "**** WARNING: CHECK QEMU VERSION"
		proceed "Want to Proceed?"
	fi
}

function mem_check()
{
	proceed "Have you consumed memory in L0?"
}

function kernel_check()
{
	if [[ -z "$2" ]]; then
		MY_KERNEL=$KERNEL
	else
		MY_KERNEL=`ssh $2@$3 $KERNEL_CMD`
	fi
	echo "$1 Kernel: $MY_KERNEL"
	kernel_ok $MY_KERNEL
}

function qemu_check()
{
	QEMU_VERSION=`ssh $2@$3 $QEMU_CMD`
	MY_QEMU_VERSION=`echo $QEMU_VERSION | awk '{ print $4 }' | sed 's/.$//'`
	echo "$1 QEMU: $MY_QEMU_VERSION"
	qemu_ok $MY_QEMU_VERSION
}

function kernel_check_all()
{
	kernel_check Client
	kernel_check L0 $USER 10.10.1.2
	if [[ "$TEST_LEVEL" != "L0" ]]; then
		kernel_check L1 root 10.10.1.100
	fi
	if [[ "$TEST_LEVEL" == "L2" ]]; then
		kernel_check L2 root 10.10.1.101
	fi
}

function qemu_check_all()
{
	if [[ "$TEST_LEVEL" != "L0" ]]; then
		qemu_check L0 $USER 10.10.1.2
	fi
	if [[ "$TEST_LEVEL" == "L2" ]]; then
		qemu_check L1 root 10.10.1.100
	fi
}

kernel_check_all
qemu_check_all
mem_check
