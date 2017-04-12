
#!/bin/bash

SRV=$1
REPTS=${2-50}

echo "Measuring performance of $SRV"

RESULTS=nginx.txt

CMD="siege -q -t 10s -c 100  http://$1/gcc/index.html -b"
for i in `seq 1 $REPTS`; do
	$CMD 2>&1 | tee >(grep 'Transaction rate' | awk '{ print $3 }' >> $RESULTS)
done


