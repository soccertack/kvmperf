#!/bin/bash

SRV=$1
TEST=${2-ALL}
REPTS=${3-50}
RESULTS=netperf.txt
EXITS=netperf-exits.txt
echo "Measuring netperf performance of $SRV"


for _TEST in TCP_MAERTS TCP_STREAM TCP_RR; do
	if [[ "$TEST" != "ALL" && "$TEST" != "$_TEST" ]]; then
		continue
	fi
	echo $_TEST >> $RESULTS
	echo $_TEST >> $EXITS
	for i in `seq 1 $REPTS`; do
		PREV_EXIT=$(ssh jintackl@10.10.1.2 'sudo cat /sys/kernel/debug/kvm/exits')
		netperf -H $SRV -t $_TEST | tee >(cat > /tmp/netperf_single.txt)
		CURR_EXIT=$(ssh jintackl@10.10.1.2 'sudo cat /sys/kernel/debug/kvm/exits')
		N_EXIT=$((CURR_EXIT - PREV_EXIT))
		echo "Number of exits: $N_EXIT"
		if [[ $? == 0 ]]; then
			if [[ "$_TEST" == "TCP_RR" ]]; then
				cat /tmp/netperf_single.txt | tail -n 2 | head -n 1 | awk '{ print $6 }' >> $RESULTS
			else
				cat /tmp/netperf_single.txt | tail -n 1 | awk '{ print $5 }' >> $RESULTS
			fi
			echo $N_EXIT >> $EXITS
		fi
	done
done
