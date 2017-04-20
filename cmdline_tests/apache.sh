#!/bin/bash

SRV=$1
REPTS=${2-50}

echo "Measuring performance of $SRV"

source exits.sh apache
print_title

# requires that apache is installed with the gcc manual in place
NR_REQUESTS=100000
RESULTS=apache.txt
ab=/usr/bin/ab
CMD="$ab -n $NR_REQUESTS -c 10 http://$SRV/gcc/index.html"
EXITS=apache-exits.txt

service apache2 start

for i in `seq 1 $REPTS`; do
	save_prev 0 10.10.1.2 jintackl
	save_prev 1 10.10.1.100 root
	$CMD | tee >(grep 'Requests per second' | awk '{ print $4 }' >> $RESULTS)
	save_curr 0 10.10.1.2 jintackl
	save_curr 1 10.10.1.100 root
	save_diff 0
	save_diff 1
done
