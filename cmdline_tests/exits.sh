APP=${1:-"noapp"}
ALL_EXITS=$APP-exits-all.txt

declare -a PREV_EXIT
declare -a PREV_IO_KERNEL_EXIT
declare -a PREV_WFI_EXIT
declare -a PREV_WFE_EXIT
declare -a PREV_IO_USER_EXIT
declare -a PREV_HVC_EXIT

declare -a CURR_EXIT
declare -a CURR_IO_KERNEL_EXIT
declare -a CURR_WFI_EXIT
declare -a CURR_WFE_EXIT
declare -a CURR_IO_USER_EXIT
declare -a CURR_HVC_EXIT

function save_prev {
	PREV_EXIT[$1]=$(ssh $3@$2 'sudo cat /sys/kernel/debug/kvm/exits')
	PREV_IO_KERNEL_EXIT[$1]=$(ssh $3@$2 'sudo cat /sys/kernel/debug/kvm/mmio_exit_kernel')
	PREV_WFI_EXIT[$1]=$(ssh $3@$2 'sudo cat /sys/kernel/debug/kvm/wfi_exit_stat')
	PREV_WFE_EXIT[$1]=$(ssh $3@$2 'sudo cat /sys/kernel/debug/kvm/wfe_exit_stat')
	PREV_IO_USER_EXIT[$1]=$(ssh $3@$2 'sudo cat /sys/kernel/debug/kvm/mmio_exit_user')
	PREV_HVC_EXIT[$1]=$(ssh $3@$2 'sudo cat /sys/kernel/debug/kvm/hvc_exit_stat')
}

function save_curr {
	CURR_EXIT[$1]=$(ssh $3@$2 'sudo cat /sys/kernel/debug/kvm/exits')
	CURR_IO_KERNEL_EXIT[$1]=$(ssh $3@$2 'sudo cat /sys/kernel/debug/kvm/mmio_exit_kernel')
	CURR_WFI_EXIT[$1]=$(ssh $3@$2 'sudo cat /sys/kernel/debug/kvm/wfi_exit_stat')
	CURR_WFE_EXIT[$1]=$(ssh $3@$2 'sudo cat /sys/kernel/debug/kvm/wfe_exit_stat')
	CURR_IO_USER_EXIT[$1]=$(ssh $3@$2 'sudo cat /sys/kernel/debug/kvm/mmio_exit_user')
	CURR_HVC_EXIT[$1]=$(ssh $3@$2 'sudo cat /sys/kernel/debug/kvm/hvc_exit_stat')
}

function print_title {
	echo "total,io_kernel,io_user,wfi,wfe,hvc" >> $ALL_EXITS
}

function save_diff {
	N_IO_KERNEL_EXIT=$((CURR_IO_KERNEL_EXIT[$1] - PREV_IO_KERNEL_EXIT[$1]))
	N_IO_USER_EXIT=$((CURR_IO_USER_EXIT[$1] - PREV_IO_USER_EXIT[$1]))
	N_WFI_EXIT=$((CURR_WFI_EXIT[$1] - PREV_WFI_EXIT[$1]))
	N_WFE_EXIT=$((CURR_WFE_EXIT[$1] - PREV_WFE_EXIT[$1]))
	N_HVC_EXIT=$((CURR_HVC_EXIT[$1] - PREV_HVC_EXIT[$1]))
	N_EXIT=$((CURR_EXIT[$1] - PREV_EXIT[$1]))
	echo "Number of exits: $N_EXIT"

	echo $N_EXIT,$N_IO_KERNEL_EXIT,$N_IO_USER_EXIT,$N_WFI_EXIT,$N_WFE_EXIT,$N_HVC_EXIT >>$ALL_EXITS
}
