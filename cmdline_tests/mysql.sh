#!/bin/bash

ACTION=$1

function usage() {
	echo "Usage: $0 <prep|run|cleanup> [remoteserver] [repts]" >&2
	exit 1
}

function prepare() {
	mysql -u root --password=kvm < create_db.sql
	sysbench --test=oltp --oltp-table-size=$TABLE_SIZE --mysql-password=kvm prepare
}

function cleanup() {
	sysbench --test=oltp --mysql-password=kvm cleanup
	mysql -u root --password=kvm < drop_db.sql
}

function run() {
	sysbench --test=oltp --oltp-table-size=$TABLE_SIZE --num-threads=$num_threads --mysql-host=$SERVER --mysql-password=kvm run | tee \
	>(grep 'total time:' | awk '{ print $3 }' | sed 's/s//' >> $RESULTS)
}

SERVER=${2-localhost}	# dns/ip for machine to test
REPTS=${3-4}

NR_REQUESTS=1000
TABLE_SIZE=1000000
RESULTS=mysql.txt

if [[ "`whoami`" != "root" ]]; then
	echo "Please run as root" >&2
	exit 1
fi


if [[ "$SERVER" != "localhost" && ("$ACTION" == "prep" || "$ACTION" == "cleanup") ]]; then
	echo "prep and cleanup actions can only be run on the db server" >&2
	exit 1
fi

if [[ "$ACTION" == "prep" ]]; then
	echo "Do nothing on prep"
elif [[ "$ACTION" == "run" ]]; then
	# Exec
	for num_threads in 200; do
		echo -e "$num_threads threads:\n---" >> $RESULTS
		for i in `seq 1 $REPTS`; do
			sync && echo 3 > /proc/sys/vm/drop_caches
			service mysql start
			cleanup
			prepare
			sleep 2
			run
			sleep 2 
			cleanup
			service mysql stop
		done;
		echo "" >> $RESULTS
	done;
elif [[ "$ACTION" == "cleanup" ]]; then
	# Cleanup
	echo "Do nothing on cleanup"
else
	usage
fi
