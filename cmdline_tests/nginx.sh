
#!/bin/bash

SRV=$1
REPTS=${2-50}

echo "Measuring performance of $SRV"

RESULTS=nginx.txt

service nginx start
for i in `seq 1 $REPTS`; do
	siege -q -t 10s -c 100  http://$1/gcc/index.html -b
	$CMD | tee >(grep 'Transaction rate' | awk '{ print $3 }' >> $RESULTS)
done


