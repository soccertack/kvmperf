#!/bin/bash

SRV=$1
REPTS=${2-50}

echo "Measuring performance of $SRV"

# requires that apache is installed with the gcc manual in place
NR_REQUESTS=100000
RESULTS=apache.txt
ab=/usr/bin/ab
CMD="$ab -n $NR_REQUESTS -c 100 http://$SRV/gcc/index.html"
EXITS=apache-exits.txt

service apache2 start

for i in `seq 1 $REPTS`; do
	PREV_EXIT=$(ssh jintackl@10.10.1.2 'sudo cat /sys/kernel/debug/kvm/exits')
	$CMD | tee >(grep 'Requests per second' | awk '{ print $4 }' >> $RESULTS)
	CURR_EXIT=$(ssh jintackl@10.10.1.2 'sudo cat /sys/kernel/debug/kvm/exits')
	N_EXIT=$((CURR_EXIT - PREV_EXIT))
	echo "Number of exits: $N_EXIT"
	echo $N_EXIT >> $EXITS
done
