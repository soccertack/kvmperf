APP=${1:-"noapp"}
ALL_EXITS=$APP-exits-all.txt

declare -a PREV_EXIT
declare -a PREV_IO_EXIT
declare -a PREV_IRQ_EXIT
declare -a PREV_HALT_EXIT
declare -a PREV_MMIO_EXIT
declare -a PREV_VMCS_EXIT
declare -a PREV_MSR_EXIT

declare -a CURR_EXIT
declare -a CURR_IO_EXIT
declare -a CURR_IRQ_EXIT
declare -a CURR_HALT_EXIT
declare -a CURR_MMIO_EXIT
declare -a CURR_VMCS_EXIT
declare -a CURR_MSR_EXIT

function save_prev {
	PREV_EXIT[$1]=$(ssh $3@$2 'sudo cat /sys/kernel/debug/kvm/exits')
	PREV_IO_EXIT[$1]=$(ssh $3@$2 'sudo cat /sys/kernel/debug/kvm/io_exits')
	PREV_IRQ_EXIT[$1]=$(ssh $3@$2 'sudo cat /sys/kernel/debug/kvm/irq_exits')
	PREV_HALT_EXIT[$1]=$(ssh $3@$2 'sudo cat /sys/kernel/debug/kvm/halt_exits')
	PREV_MMIO_EXIT[$1]=$(ssh $3@$2 'sudo cat /sys/kernel/debug/kvm/mmio_exits')
	PREV_VMCS_EXIT[$1]=$(ssh $3@$2 'sudo cat /sys/kernel/debug/kvm/vmcs')
	PREV_MSR_EXIT[$1]=$(ssh $3@$2 'sudo cat /sys/kernel/debug/kvm/msr')
}

function save_curr {
	CURR_EXIT[$1]=$(ssh $3@$2 'sudo cat /sys/kernel/debug/kvm/exits')
	CURR_IO_EXIT[$1]=$(ssh $3@$2 'sudo cat /sys/kernel/debug/kvm/io_exits')
	CURR_IRQ_EXIT[$1]=$(ssh $3@$2 'sudo cat /sys/kernel/debug/kvm/irq_exits')
	CURR_HALT_EXIT[$1]=$(ssh $3@$2 'sudo cat /sys/kernel/debug/kvm/halt_exits')
	CURR_MMIO_EXIT[$1]=$(ssh $3@$2 'sudo cat /sys/kernel/debug/kvm/mmio_exits')
	CURR_VMCS_EXIT[$1]=$(ssh $3@$2 'sudo cat /sys/kernel/debug/kvm/vmcs')
	CURR_MSR_EXIT[$1]=$(ssh $3@$2 'sudo cat /sys/kernel/debug/kvm/msr')
}

function print_title {
	echo "total,io,irq,halt,mmio,vmcs,msr" >> $ALL_EXITS
}

function save_diff {
	N_IO_EXIT=$((CURR_IO_EXIT[$1] - PREV_IO_EXIT[$1]))
	N_IRQ_EXIT=$((CURR_IRQ_EXIT[$1] - PREV_IRQ_EXIT[$1]))
	N_HALT_EXIT=$((CURR_HALT_EXIT[$1] - PREV_HALT_EXIT[$1]))
	N_MMIO_EXIT=$((CURR_MMIO_EXIT[$1] - PREV_MMIO_EXIT[$1]))
	N_VMCS_EXIT=$((CURR_VMCS_EXIT[$1] - PREV_VMCS_EXIT[$1]))
	N_MSR_EXIT=$((CURR_MSR_EXIT[$1] - PREV_MSR_EXIT[$1]))
	N_EXIT=$((CURR_EXIT[$1] - PREV_EXIT[$1]))
	echo "Number of exits: $N_EXIT"

	echo $N_EXIT,$N_IO_EXIT,$N_IRQ_EXIT,$N_HALT_EXIT,$N_MMIO_EXIT,$N_VMCS_EXIT,$N_MSR_EXIT >>$ALL_EXITS
}
