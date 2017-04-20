
#!/bin/bash

SRV=$1
REPTS=${2-50}

echo "Measuring performance of $SRV"

RESULTS=nginx.txt
TMP=/tmp/nginx.txt
source exits.sh nginx 
print_title

CMD="sudo siege -q -t 10s -c 8  http://$1/gcc/index.html -b"
for i in `seq 1 $REPTS`; do
	save_prev 0 10.10.1.2 jintackl
	save_prev 1 10.10.1.100 root
	$CMD 2>&1 | tee /tmp/nginx.txt
	save_curr 0 10.10.1.2 jintackl
	save_curr 1 10.10.1.100 root
	save_diff 0
	save_diff 1
	cat $TMP | grep 'Transaction rate' | awk '{ print $3 }' >> $RESULTS
	SUCCESS=`cat $TMP | grep 'Successful' | awk '{ print $3 }'`
	if [[ "$SUCCESS" == "0" ]]; then
		echo "No successful transaction."
		exit 1
	fi
done


