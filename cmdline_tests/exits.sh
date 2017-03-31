APP=${1:-"noapp"}
ALL_EXITS=$APP-exits-all.txt

PREV_EXIT=0
PREV_IO_EXIT=0
PREV_IRQ_EXIT=0
PREV_HALT_EXIT=0
PREV_MMIO_EXIT=0
PREV_VMCS_EXIT=0
PREV_MSR_EXIT=0

CURR_EXIT=0
CURR_IO_EXIT=0
CURR_IRQ_EXIT=0
CURR_HALT_EXIT=0
CURR_MMIO_EXIT=0
CURR_VMCS_EXIT=0
CURR_MSR_EXIT=0

function save_prev {
	PREV_EXIT=$(ssh jintackl@10.10.1.2 'sudo cat /sys/kernel/debug/kvm/exits')
	PREV_IO_EXIT=$(ssh jintackl@10.10.1.2 'sudo cat /sys/kernel/debug/kvm/io_exits')
	PREV_IRQ_EXIT=$(ssh jintackl@10.10.1.2 'sudo cat /sys/kernel/debug/kvm/irq_exits')
	PREV_HALT_EXIT=$(ssh jintackl@10.10.1.2 'sudo cat /sys/kernel/debug/kvm/halt_exits')
	PREV_MMIO_EXIT=$(ssh jintackl@10.10.1.2 'sudo cat /sys/kernel/debug/kvm/mmio_exits')
	PREV_VMCS_EXIT=$(ssh jintackl@10.10.1.2 'sudo cat /sys/kernel/debug/kvm/vmcs')
	PREV_MSR_EXIT=$(ssh jintackl@10.10.1.2 'sudo cat /sys/kernel/debug/kvm/msr')
}

function save_curr {
	CURR_EXIT=$(ssh jintackl@10.10.1.2 'sudo cat /sys/kernel/debug/kvm/exits')
	CURR_IO_EXIT=$(ssh jintackl@10.10.1.2 'sudo cat /sys/kernel/debug/kvm/io_exits')
	CURR_IRQ_EXIT=$(ssh jintackl@10.10.1.2 'sudo cat /sys/kernel/debug/kvm/irq_exits')
	CURR_HALT_EXIT=$(ssh jintackl@10.10.1.2 'sudo cat /sys/kernel/debug/kvm/halt_exits')
	CURR_MMIO_EXIT=$(ssh jintackl@10.10.1.2 'sudo cat /sys/kernel/debug/kvm/mmio_exits')
	CURR_VMCS_EXIT=$(ssh jintackl@10.10.1.2 'sudo cat /sys/kernel/debug/kvm/vmcs')
	CURR_MSR_EXIT=$(ssh jintackl@10.10.1.2 'sudo cat /sys/kernel/debug/kvm/msr')
}

function print_title {
	echo "total,io,irq,halt,mmio,vmcs,msr" >> $ALL_EXITS
}

function save_diff {
	N_IO_EXIT=$((CURR_IO_EXIT - PREV_IO_EXIT))
	N_IRQ_EXIT=$((CURR_IRQ_EXIT - PREV_IRQ_EXIT))
	N_HALT_EXIT=$((CURR_HALT_EXIT - PREV_HALT_EXIT))
	N_MMIO_EXIT=$((CURR_MMIO_EXIT - PREV_MMIO_EXIT))
	N_VMCS_EXIT=$((CURR_VMCS_EXIT - PREV_VMCS_EXIT))
	N_MSR_EXIT=$((CURR_MSR_EXIT - PREV_MSR_EXIT))
	N_EXIT=$((CURR_EXIT - PREV_EXIT))
	echo "Number of exits: $N_EXIT"

	echo $N_EXIT,$N_IO_EXIT,$N_IRQ_EXIT,$N_HALT_EXIT,$N_MMIO_EXIT,$N_VMCS_EXIT,$N_MSR_EXIT >>$ALL_EXITS
}
