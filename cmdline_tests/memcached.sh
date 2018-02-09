#!/bin/bash

SERVER=${1-127.0.0.1}
REPTS=${2-40}
RESULTS=${3-memcached.txt}

echo "Benchmarking $SERVER" | tee >(cat >> $RESULTS)
for i in `seq 1 $REPTS`; do
	memtier_benchmark --test-time=30 -p 11211 -P memcache_binary -s $SERVER 2>&1 | \
		tee >(grep 'Totals' | awk '{ print $2 }' >> $RESULTS)
done
