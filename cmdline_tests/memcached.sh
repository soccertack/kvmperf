#!/bin/bash

SERVER=${1-127.0.0.1}
REPTS=${2-40}
RESULTS=memcached.txt
EXITS=memcached-exits.txt

echo "Benchmarking $SERVER" | tee >(cat >> $RESULTS)
echo "Benchmarking $SERVER" >> $EXITS

for i in `seq 1 $REPTS`; do
	PREV_EXIT=$(ssh jintackl@10.10.1.2 'sudo cat /sys/kernel/debug/kvm/exits')
	memtier_benchmark -p 11211 -P memcache_binary -s $SERVER 2>&1 | \
		tee >(grep 'Totals' | awk '{ print $2 }' >> $RESULTS)
	CURR_EXIT=$(ssh jintackl@10.10.1.2 'sudo cat /sys/kernel/debug/kvm/exits')
	N_EXIT=$((CURR_EXIT - PREV_EXIT))
	echo "Number of exits: $N_EXIT"
	echo $N_EXIT >> $EXITS
done
