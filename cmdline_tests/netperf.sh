#!/bin/bash

SRV=$1
TEST=${2-ALL}
REPTS=${3-50}
RESULTS=netperf.txt

echo "Measuring netperf performance of $SRV"

for _TEST in TCP_MAERTS TCP_STREAM TCP_RR; do
	if [[ "$TEST" != "ALL" && "$TEST" != "$_TEST" ]]; then
		continue
	fi
	echo $_TEST >> $RESULTS
	source exits.sh $_TEST
	print_title
	for i in `seq 1 $REPTS`; do
		save_prev
		netperf -T ,2 -H $SRV -t $_TEST | tee >(cat > /tmp/netperf_single.txt)
		save_curr
		save_diff

		if [[ $? == 0 ]]; then
			if [[ "$_TEST" == "TCP_RR" ]]; then
				cat /tmp/netperf_single.txt | tail -n 2 | head -n 1 | awk '{ print $6 }' >> $RESULTS
			else
				cat /tmp/netperf_single.txt | tail -n 1 | awk '{ print $5 }' >> $RESULTS
			fi
		fi
	done
done
