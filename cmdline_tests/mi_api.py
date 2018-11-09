#!/usr/bin/python

import pexpect
import sys
import os
import datetime
import time
import socket
import argparse
import os.path
import pickle

class Params:
	def __init__(self):
		self.level = 0
		self.iovirt = "none"
		self.posted = False
		mi = "none"
		mi_role = "none"

	def __str__(self):
		return str(self.__class__) + ": " + str(self.__dict__)

l0_migration_qemu  = ' --qemu /sdc/L0-qemu/'
l1_migration_qemu = ' --qemu /sdc/L1-qemu/'
mi_src = " -s"
mi_dest = " -t"
LOCAL_SOCKET = 8890
l1_addr='10.10.1.100'

###############################
#### set default here #########
mi_default = "l2"
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

def boot_l1(params):
	iovirt = params.iovirt
	posted = params.posted
	level = params.level
	mi = params.mi

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

def boot_nvm(params):
	iovirt = params.iovirt
	posted = params.posted
	level = params.level
	mi = params.mi
	mi_role = params.mi_role

	boot_l1(params)

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

def reboot(params):
	halt(params.level)
	boot_nvm(params)

def str_to_bool(s):
	if s == 'True':
		return True
	elif s == 'False':
		return False
	else:
		print (s)
		raise ValueError

EXP_PARAMS_PKL="./.exp_params.pkl"
def get_params(hostname):
	if os.path.exists(EXP_PARAMS_PKL):

		with open(EXP_PARAMS_PKL, 'rb') as input:
			params = pickle.load(input)
			print(params)
			level = params.level
			iovirt = params.iovirt
			posted = params.posted
			mi = params.mi
			mi_role = params.mi_role
			return params

	else:
		print ("We don't have param file")
		new_params = Params()

		level  = int(raw_input("Enter virtualization level [2]: ") or "2")
		if level < 1:
			print ("We don't (need to) support L0")
			sys.exit(0)
		if level > 3:
			print ("Are you sure to run virt level %d?" % level)
			sleep(5)
		new_params.level = level

# iovirt: pv, pt(pass-through), or vp(virtual-passthough)
		iovirt = raw_input("Enter I/O virtualization level [%s]: " % io_default) or io_default
		if iovirt not in ["pv", "pt", "vp"]:
			print ("Enter pv, pt, or vp")
			sys.exit(0)
		new_params.iovirt = iovirt

		posted = False
		if iovirt == "vp":
			posted = raw_input("Enable posted-interrupts in vIOMMU? [no]: ") or "no"
			if posted == "no":
				posted = False
			else:
				posted = True
		new_params.posted = posted


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
		new_params.mi = mi
		new_params.mi_role = mi_role

		with open(EXP_PARAMS_PKL, 'wb') as output:
			pickle.dump(new_params, output)

		return new_params


## MAIN

hostname = os.popen('hostname | cut -d . -f1').read().strip()
if hostname == "kvm-dest":
    l1_addr = "10.10.1.110"

params = get_params(hostname)

child = pexpect.spawn('bash')
#https://stackoverflow.com/questions/29245269/pexpect-echoes-sendline-output-twice-causing-unwanted-characters-in-buffer
#child.logfile = sys.stdout
child.logfile_read=sys.stdout
child.timeout=None

child.sendline('')
wait_for_prompt(child, hostname)
#boot_nvm(iovirt, posted, level, mi, mi_role)

