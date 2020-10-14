#!/bin/bash

SRV=$1
REPTS=${2-40}

RESULTS=iperf.txt

echo "Measuring performance of $SRV"

CMD="iperf -c $SRV"

for i in `seq 1 $REPTS`; do
	$CMD | tee >(grep 'GBytes' | awk '{ print $7 }' >> $RESULTS)
done
