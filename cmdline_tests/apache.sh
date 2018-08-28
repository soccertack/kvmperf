#!/bin/bash

SRV=$1
REPTS=${2-50}

echo "Measuring performance of $SRV"

# requires that apache is installed with the gcc manual in place
NR_REQUESTS=50000
RESULTS=apache.txt
ab=/usr/bin/ab
CMD="$ab -n $NR_REQUESTS -c 1 -t 10 http://$SRV/gcc/index.html"

source exits.sh apache

for i in `seq 1 $REPTS`; do
	start_measurement

	$CMD | tee >(grep 'Requests per second' | awk '{ print $4 }' >> $RESULTS)

	end_measurement
	save_stat
done
