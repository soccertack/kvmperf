#!/bin/bash

SRV=$1
REPTS=${2-50}

echo "Measuring performance of $SRV"

RESULTS=nginx.txt
TMP=/tmp/nginx.txt

CMD="sudo siege -q -t 10s -c 1  http://$1/gcc/index.html -b"
for i in `seq 1 $REPTS`; do
	$CMD 2>&1 | tee /tmp/nginx.txt
	cat $TMP | grep 'Transaction rate' | awk '{ print $3 }' >> $RESULTS
	SUCCESS=`cat $TMP | grep 'Successful' | awk '{ print $3 }'`
	if [[ "$SUCCESS" == "0" ]]; then
		echo "No successful transaction."
		exit 1
	fi
done
