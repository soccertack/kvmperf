#!/bin/bash

SERVER=${1-127.0.0.1}
REPTS=${2-1}
RESULTS=memcached.txt
source exits.sh memcached

echo "Benchmarking $SERVER" | tee >(cat >> $RESULTS)
echo "Benchmarking $SERVER" >> $ALL_EXITS
print_title

for i in `seq 1 $REPTS`; do
	save_prev 0 10.10.1.2 jintackl
	save_prev 1 10.10.1.100 root
	memtier_benchmark -p 11211 -P memcache_binary -s $SERVER 2>&1 | \
		tee >(grep 'Totals' | awk '{ print $2 }' >> $RESULTS)
	save_curr 0 10.10.1.2 jintackl
	save_curr 1 10.10.1.100 root
	save_diff 0
	save_diff 1

done
