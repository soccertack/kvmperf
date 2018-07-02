#!/bin/bash

SRV=$1
REPTS=${2-1}

echo "Measuring performance of $SRV"

# requires that apache is installed with the gcc manual in place
NR_REQUESTS=100000
RESULTS=apache.txt
ab=/usr/bin/ab
CMD="$ab -n $NR_REQUESTS -c 10 http://$SRV/gcc/index.html"
source exits.sh apache
print_title

service apache2 start

for i in `seq 1 $REPTS`; do
	save_prev 0 10.10.1.2 root
#	save_prev 1 10.10.1.100 root
	$CMD | tee >(grep 'Requests per second' | awk '{ print $4 }' >> $RESULTS)
	save_curr 0 10.10.1.2 root
#	save_curr 1 10.10.1.100 root
	save_diff 0
#	save_diff 1
done
