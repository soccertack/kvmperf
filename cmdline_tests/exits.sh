APP=${1:-"noapp"}
ALL_EXITS=$APP-exits-all.txt
USER=root
L0_IP=10.10.1.2
L1_IP=10.10.1.100

#These are default ones from KVM
default_exits=(exits io_exits irq_exits halt_exits mmio_exits)

function print_title {
	for exit in ${exits[@]}; do
		echo -n "$exit," >> $ALL_EXITS
	done
	echo "" >> $ALL_EXITS
}

function read_raw {
	for exit in ${exits[@]}; do
		declare -n ref="$1_$exit"
		ref[$2]=$(ssh $USER@$3 "sudo cat /sys/kernel/debug/kvm/$exit")
	done
}

function read_stat {
	if [ "$measure_L0" == 1 ]; then
		read_raw $1 "0" $L0_IP
	fi

	if [ "$measure_L1" == 1 ]; then
		read_raw $1 "1" $L1_IP
	fi
}

function start_measurement {
	read_stat "PREV"
}

function end_measurement {
	read_stat "CURR"
}

function save_exits {
	echo "<---- exit stats from $1 ---->" >> $ALL_EXITS

	if [ "$1" == "L0" ]; then
		index=0
	elif [ "$1" == "L1" ]; then
		index=1
	else
		echo "Wrong argument for save_exits: $1"
		exit
	fi

	for exit in ${exits[@]}; do
		declare -n curr_ref="CURR_$exit"
		declare -n prev_ref="PREV_$exit"
		diff=$((curr_ref[$index] - prev_ref[$index]))
		if [ $diff != 0 ]; then
			echo "${exit}: $diff" >> $ALL_EXITS
		fi
	done
	echo "<---------------------------->" >> $ALL_EXITS
}

function save_stat {
	if [ "$measure_L0" == 1 ]; then
		save_exits "L0"
	fi

	if [ "$measure_L1" == 1 ]; then
		save_exits "L1"
	fi
}

# We just get the exit list from L0. We may do so in a function,
# but I don't know how to make array variables (PREV_*) global...
added_exits=$(ssh root@10.10.1.2 "ls /sys/kernel/debug/kvm/ | grep exits_")
exits=("${default_exits[@]}" "${added_exits[@]}")

for exit in ${exits[@]}; do
	declare -a PREV_$exit
	declare -a CURR_$exit
done

# The first argument is for the output file name
shift 1

while :
	do
	case "$1" in
	  L0)
	    echo "Collect stats from L0"
	    measure_L0=1
	    shift 1
	    ;;
	  L1)
	    echo "Collect stats from L1"
	    measure_L1=1
	    shift 1
	    ;;
	  --) # End of all options
	    shift
	    break
	    ;;
	  -*) # Unknown option
	    echo "Error: Unknown option: $1" >&2
	    exit 1
	    ;;
	  *) # ?
	    break
	    ;;
	esac
done
