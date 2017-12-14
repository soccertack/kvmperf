#!/bin/bash

TIMELOG=${TIMELOG-$(pwd)/kernbench.txt}

source setup.sh
source setup-kernel.sh

TEST_KERNBENCH_REPEAT=${1-1}

KB="kernbench"
KB_VER="0.50"
KB_TAR="$KB-$KB_VER.tar.gz"


if [[ -f $KERNEL/$KB ]]; then
	echo "$KB is here"
else
	pushd /tmp
	wget http://www.cs.columbia.edu/~jintack/kernbench-0.50.tar.gz
	tar xvfz $KB_TAR
	cp $KB-$KB_VER/$KB $KERNEL
	popd
	sync
fi

for i in `seq 1 $TEST_KERNBENCH_REPEAT`; do
	pushd $KERNEL
	refresh
	./kernbench -M -H -f | tee >(grep 'Elapsed' | awk '{print $3 }' >> $TIMELOG)
	popd
done

