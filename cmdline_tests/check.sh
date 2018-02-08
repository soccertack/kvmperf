#!/bin/bash

#########
TEST_KERNEL="4.15.0"
TEST_KERNEL_ARM="4.15.0+"
TEST_QEMU="2.11.0"
#########

# L0, L1 or L2
TEST_LEVEL=$1
USER=jintackl

MACHINE=`uname -m`
KERNEL=`uname -r`
KERNEL_CMD='uname -r'

C_KERNEL=$TEST_KERNEL
L2_KERNEL=$TEST_KERNEL
if [[ "$MACHINE" == "x86_64" ]]; then
		L0_KERNEL=$TEST_KERNEL
		L1_KERNEL=$TEST_KERNEL
	else
		L0_KERNEL=$TEST_KERNEL_ARM
		L1_KERNEL=$TEST_KERNEL_ARM
fi

QEMU_CMD_x86='/srv/vm/qemu-system-x86_64 --version'
QEMU_CMD_ARM='/srv/vm/qemu-system-aarch64 --version'
QEMU_CMD_ARM_L1='/root/vm/qemu-system-aarch64 --version'

if [[ "$MACHINE" == "x86_64" ]]; then
	QEMU_CMD=$QEMU_CMD_x86
else
	QEMU_CMD=$QEMU_CMD_ARM
fi

TRACE_CMD='gunzip -c /proc/config.gz | grep CONFIG_FTRACE=y | wc -l'

IRQB_CMD="pgrep irqbalance"

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
	if [[ $1 == $2 ]]; then
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

function vcpu_pin_check()
{

	if [[ "$TEST_LEVEL" == "L1" ]]; then
		proceed "Have you pinned vcpus in L0?"
	fi
	if [[ "$TEST_LEVEL" == "L2" ]]; then
		proceed "Have you pinned vcpus in L0 AND L1?"
	fi
}

function mem_check()
{
	proceed "Have you consumed memory in L0?"
}

function kernel_check()
{
	if [[ -z "$3" ]]; then
		MY_KERNEL=$KERNEL
	else
		MY_KERNEL=`ssh $3@$4 $KERNEL_CMD`
	fi
	echo "$2 Kernel: $MY_KERNEL"
	kernel_ok $MY_KERNEL $1
}

function trace_check()
{
	TRACE_ON=`ssh $2@$3 $TRACE_CMD`
	if [[ $TRACE_ON == "0" ]]; then
		echo "$1 TRACE OFF"
	else
		proceed "$1 TRACE is ON. Want to Proceed?"
	fi
}


function qemu_check()
{
	if [[ "$1" == "L1" && "$MACHINE" == "aarch64" ]]; then
		QEMU_CMD=$QEMU_CMD_ARM_L1
	fi
	QEMU_VERSION=`ssh $2@$3 $QEMU_CMD`

	MY_QEMU_VERSION=`echo $QEMU_VERSION | awk '{ print $4 }' | sed 's/.$//'`
	echo "$1 QEMU: $MY_QEMU_VERSION"
	qemu_ok $MY_QEMU_VERSION
}

function kernel_check_all()
{
	kernel_check $C_KERNEL Client
	kernel_check $L0_KERNEL L0 $USER 10.10.1.2
	if [[ "$TEST_LEVEL" != "L0" ]]; then
		kernel_check $L1_KERNEL L1 root 10.10.1.100
	fi
	if [[ "$TEST_LEVEL" == "L2" ]]; then
		kernel_check $L2_KERNEL L2 root 10.10.1.101
	fi
}

function trace_check_all()
{
	trace_check L0 $USER 10.10.1.2
	if [[ "$TEST_LEVEL" != "L0" ]]; then
		trace_check L1 root 10.10.1.100
	fi
	if [[ "$TEST_LEVEL" == "L2" ]]; then
		trace_check L2 root 10.10.1.101
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

function irqb_check()
{
	if [[ -z "$2" ]]; then
		IRQB=`$IRQB_CMD`
	else
		IRQB=`ssh $2@$3 $IRQB_CMD`
	fi

	if [[ $? -eq 0 ]]; then
		echo "irqbalance is running: $IRQB in $1"
	else
		echo "irqbalance is NOT running"
		proceed "Want to Proceed?"
	fi
}

function irqbalance_check_all()
{
	irqb_check Client
	irqb_check L0 $USER 10.10.1.2
	if [[ "$TEST_LEVEL" != "L0" ]]; then
		irqb_check L1 root 10.10.1.100
	fi
	if [[ "$TEST_LEVEL" == "L2" ]]; then
		irqb_check L2 root 10.10.1.101
	fi
}

kernel_check_all
trace_check_all
qemu_check_all
mem_check
vcpu_pin_check
irqbalance_check_all
