APP=${1:-"noapp"}
ALL_EXITS=$APP-exits-all.txt
USER=root
L0_IP=10.10.1.2
L1_IP=10.10.1.100
L2_IP=10.10.1.101

#These are default ones from KVM
default_exits=(exits io_exits irq_exits halt_exits mmio_exits)

function print_title {
	for exit in ${exits[@]}; do
		echo -n "$exit," >> $ALL_EXITS
	done
	echo "" >> $ALL_EXITS
}

function read_raw {
	# Prepare to Read all exit stat at once
	cmd="ssh $USER@$3 cd /sys/kernel/debug/kvm/ && cat"
	for exit in ${exits[@]}; do
		cmd="$cmd $exit"
	done

	all_exits=$($cmd)
	all_exits=( $all_exits )

	__i=0
	for exit in ${exits[@]}; do
		declare -n ref="$1_$exit"
		ref[$2]=${all_exits[$__i]}
		__i=$(($__i+1))
	done
}

function read_stat {
	for i in "${targets[@]}"; do
		IP=${i}_IP
		read_raw $1 "${i: -1}" ${!IP}
	done
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
	elif [ "$1" == "L2" ]; then
		index=2
	else
		echo "Wrong argument for save_exits: $1"
		exit
	fi

	for exit in ${exits[@]}; do
		declare -n curr_ref="CURR_$exit"
		declare -n prev_ref="PREV_$exit"
		diff=$((curr_ref[$index] - prev_ref[$index]))
		if [ $diff != 0 ]; then
			echo "${exit}, $diff" >> $ALL_EXITS
		fi
	done
	echo "<---------------------------->" >> $ALL_EXITS
}

function save_stat {
	for i in "${targets[@]}"; do
		save_exits $i
	break
done
}

# The first argument is for the output file name
shift 1

targets=()
while :
	do
	case "$1" in
	  L0 | L1 | L2)
	    echo "Collect stats from $1"
	    targets+=($1)
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

# This is to get the list of exits.
# Assume that all VMs have the same set of exit counters,
# and we just get the list from the first one.
for i in "${targets[@]}"; do
	IP=${i}_IP
	added_exits=$(ssh root@${!IP} "ls /sys/kernel/debug/kvm/ | grep exits_")
	break
done

# We don't use default exit stats from KVM any more since our framework
# has the same state
exits=("${added_exits[@]}")
#exits=("${default_exits[@]}" "${added_exits[@]}")

for exit in ${exits[@]}; do
	declare -a PREV_$exit
	declare -a CURR_$exit
done

