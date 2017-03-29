#!/bin/bash

ACTION=$1

function usage() {
	echo "Usage: $0 <prep|run|cleanup> [remoteserver] [repts]" >&2
	exit 1
}

SERVER=${2-localhost}	# dns/ip for machine to test
REPTS=${3-4}

NR_REQUESTS=1000
TABLE_SIZE=1000000
RESULTS=mysql.txt
EXITS=mysql-exits.txt

if [[ "`whoami`" != "root" ]]; then
	echo "Please run as root" >&2
	exit 1
fi


if [[ "$SERVER" != "localhost" && ("$ACTION" == "prep" || "$ACTION" == "cleanup") ]]; then
	echo "prep and cleanup actions can only be run on the db server" >&2
	exit 1
fi

if [[ "$ACTION" == "prep" ]]; then
	# Prep
	service mysql start
	mysql -u root --password=kvm < create_db.sql
	sysbench --test=oltp --oltp-table-size=$TABLE_SIZE --mysql-password=kvm prepare
elif [[ "$ACTION" == "run" ]]; then
	# Exec
	for num_threads in 200; do
		echo -e "$num_threads threads:\n---" >> $RESULTS
		for i in `seq 1 $REPTS`; do
			sync && echo 3 > /proc/sys/vm/drop_caches
			sleep 5
			PREV_EXIT=$(ssh jintackl@10.10.1.2 'sudo cat /sys/kernel/debug/kvm/exits')
			sysbench --test=oltp --oltp-table-size=$TABLE_SIZE --num-threads=$num_threads --mysql-host=$SERVER --mysql-password=kvm run | tee \
				>(grep 'total time:' | awk '{ print $3 }' | sed 's/s//' >> $RESULTS)
			
			CURR_EXIT=$(ssh jintackl@10.10.1.2 'sudo cat /sys/kernel/debug/kvm/exits')
			N_EXIT=$((CURR_EXIT - PREV_EXIT))
			echo "Number of exits: $N_EXIT"
			echo $N_EXIT >> $EXITS
			sleep 2 # Just to give some time to write the data to $RESULTS before echo "" >> $RESULTS happens.
		done;
		echo "" >> $RESULTS
	done;
elif [[ "$ACTION" == "cleanup" ]]; then
	# Cleanup
	sysbench --test=oltp --mysql-password=kvm cleanup
	mysql -u root --password=kvm < drop_db.sql
	service mysql stop
else
	usage
fi
