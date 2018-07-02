APP=${1:-"noapp"}
ALL_EXITS=$APP-exits-all.txt

#These are default ones from KVM
default_exits=(exits io_exits irq_exits halt_exits mmio_exits)

# $1: address
# $2: username
function init_exits {
	added_exits=$(ssh $2@$1 "ls /sys/kernel/debug/kvm/ | grep exits_")
	exits=("${default_exits[@]}" "${added_exits[@]}")

	for exit in ${exits[@]}; do
		declare -a PREV_$exit
		declare -a CURR_$exit
	done
}

function read_raw {
	for exit in ${exits[@]}; do
		declare -n ref="$4_$exit"
		ref[$1]=$(ssh $3@$2 "sudo cat /sys/kernel/debug/kvm/$exit")
	done
}

function save_prev {
	read_raw $1 $2 $3 "PREV"
}

function save_curr {
	read_raw $1 $2 $3 "CURR"
}

function print_title {
	for exit in ${exits[@]}; do
		echo -n "$exit," >> $ALL_EXITS
	done
	echo "" >> $ALL_EXITS
}

function save_diff {
	for exit in ${exits[@]}; do
		declare -n curr_ref="CURR_$exit"
		declare -n prev_ref="PREV_$exit"
		diff=$((curr_ref[$1] - prev_ref[$1]))
		echo -n "$diff," >> $ALL_EXITS
	done
	echo "" >> $ALL_EXITS
}
