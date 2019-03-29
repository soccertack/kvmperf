#!/usr/bin/python

import pexpect
import sys
import os
import datetime
import time
import socket
import argparse

l0_migration_qemu  = ' --qemu /sdc/L0-qemu/'
l1_migration_qemu = ' --qemu /sdc/L1-qemu/'
mi_src = " -s"
mi_dest = " -t"
LOCAL_SOCKET = 8890
l1_addr='10.10.1.100'

###############################
#### set default here #########
mi_default = "no"
io_default = "vp"
###############################
def wait_for_prompt(child, hostname):
    child.expect('%s.*#' % hostname)

def pin_vcpus(level):
	os.system('cd /srv/vm/qemu/scripts/qmp/ && sudo ./pin_vcpus.sh && cd -')
	if level > 1:
		os.system('ssh root@%s "cd vm/qemu/scripts/qmp/ && ./pin_vcpus.sh"' % l1_addr)
	if level > 2:
		os.system('ssh root@10.10.1.101 "cd vm/qemu/scripts/qmp/ && ./pin_vcpus.sh"')
	print ("vcpu is pinned")

cmd_pv = './run-guest.sh'
cmd_vfio = './run-guest-vfio.sh'
cmd_viommu = './run-guest-viommu.sh'
cmd_vfio_viommu = './run-guest-vfio-viommu.sh'

def boot_l1(iovirt, posted, level, mi):

	l0_cmd = 'cd /srv/vm && '
	if iovirt == "vp":
		l0_cmd += cmd_viommu
		if mi == "l2":
			l0_cmd += l0_migration_qemu
	elif iovirt == "pv":
		l0_cmd += cmd_pv
	elif iovirt == "pt":
		if level == 1:
			l0_cmd += cmd_vfio
		else:
			l0_cmd += cmd_vfio_viommu

	if posted:
		l0_cmd += " --pi"
	
	child.sendline(l0_cmd)

	child.expect('L1.*$')

def handle_mi_options(lx_cmd, mi, mi_role):

	if mi == "l2":
		lx_cmd += l1_migration_qemu
		if mi_role == "src":
			lx_cmd += mi_src
		else:
			lx_cmd += mi_dest

	return lx_cmd

def boot_nvm(iovirt, posted, level, mi, mi_role):

	boot_l1(iovirt, posted, level, mi)

	mylevel = 1
	while (mylevel < level):
		mylevel += 1

		lx_cmd = 'cd ~/vm && '
		if iovirt == "vp" or iovirt == "pt":
			if mylevel == level:
				lx_cmd += cmd_vfio
				lx_cmd = handle_mi_options(lx_cmd, mi, mi_role)
			else:
				lx_cmd += cmd_vfio_viommu
		else:
			lx_cmd += cmd_pv

		child.sendline(lx_cmd)
		if mi == "l2":
			child.expect('\(qemu\)')
		else:
			child.expect('L' + str(mylevel) + '.*$')

	time.sleep(2)
	pin_vcpus(level)
	time.sleep(2)

def halt(level):
	if level > 2:
		os.system('ssh root@10.10.1.102 "halt -p"')
		child.expect('L2.*$')

	if level > 1:
		os.system('ssh root@10.10.1.101 "halt -p"')
		child.expect('L1.*$')

	os.system('ssh root@%s "halt -p"' % l1_addr)
	wait_for_prompt(child, hostname)

def reboot(iovirt, posted, level, mi, mi_role):
	halt(level)
	boot_nvm(iovirt, posted, level, mi, mi_role)

## MAIN

hostname = os.popen('hostname | cut -d . -f1').read().strip()
if hostname == "kvm-dest":
    l1_addr = "10.10.1.110"

level  = int(raw_input("Enter virtualization level [2]: ") or "2")
if level < 1:
	print ("We don't (need to) support L0")
	sys.exit(0)
if level > 3:
	print ("Are you sure to run virt level %d?" % level)
	sleep(5)

# iovirt: pv, pt(pass-through), or vp(virtual-passthough)
iovirt = raw_input("Enter I/O virtualization level [%s]: " % io_default) or io_default
if iovirt not in ["pv", "pt", "vp"]:
	print ("Enter pv, pt, or vp")
	sys.exit(0)

posted = False
if iovirt == "vp":
	posted = raw_input("Enable posted-interrupts in vIOMMU? [no]: ") or "no"
	if posted == "no":
		posted = False
	else:
		posted = True


mi_role = ""
mi = raw_input("Migration? [%s]: " % mi_default) or mi_default
if mi not in ["no", "l2"]:
	print ("Enter no or l2")
	sys.exit(0)
elif mi == "l2":
	if hostname == "kvm-dest":
		mi_role = 'dest'
	else:
		mi_role = 'src'


child = pexpect.spawn('bash')
#https://stackoverflow.com/questions/29245269/pexpect-echoes-sendline-output-twice-causing-unwanted-characters-in-buffer
#child.logfile = sys.stdout
child.logfile_read=sys.stdout
child.timeout=None

child.sendline('')
wait_for_prompt(child, hostname)
boot_nvm(iovirt, posted, level, mi, mi_role)

child.interact()
sys.exit(0)

serversocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

print ("Try to bind...")
try:
	serversocket.bind(('', 8889))
except socket.error:
	halt(level)
	sys.exit(0)
print ("Done.")

print ("Try to listen...")
serversocket.listen(1) # become a server socket.
print ("Done.")

print ("Try to accept...")
connection, address = serversocket.accept()
print ("Done.")

while True:
    print ("Waiting for incoming messages.")
    buf = connection.recv(64)
    if len(buf) > 0:
        print buf
	if buf == "reboot":
		reboot(iovirt, posted, level, mi)
		connection.send("ready")
	elif buf == "halt":
		halt(level)
		break;
