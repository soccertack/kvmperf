#!/usr/bin/python

import pexpect
import sys
import os
import datetime
import time
import socket
import argparse

LOCAL_SOCKET = 8890
def pin_vcpus(level):
	os.system('cd /srv/vm/qemu/scripts/qmp/ && sudo ./pin_vcpus.sh && cd -')
	if level > 1:
		os.system('ssh root@10.10.1.100 "cd vm/qemu/scripts/qmp/ && ./pin_vcpus.sh"')
	if level > 2:
		os.system('ssh root@10.10.1.101 "cd vm/qemu/scripts/qmp/ && ./pin_vcpus.sh"')
	print ("vcpu is pinned")

def boot_nvm(pvpassthrough, level):

	mylevel = 0
	if pvpassthrough:
		child.sendline('cd /srv/vm && ./run-guest-viommu.sh')
	else:
		child.sendline('cd /srv/vm && ./run-guest.sh')

        child.expect('L1.*$')
	mylevel = 1

	while (mylevel < level):
		mylevel += 1

		if pvpassthrough:
			if mylevel == level:
				child.sendline('cd ~/vm && ./run-guest-vfio.sh')
			else:
				child.sendline('cd ~/vm && ./run-guest-vfio-viommu.sh')
		else:
			child.sendline('cd ~/vm && ./run-guest.sh')

		child.expect('L' + str(mylevel) + '.*$')

	time.sleep(2)
	pin_vcpus(level)
	time.sleep(2)

def halt(pvpassthrough, level):
	if level > 2:
		os.system('ssh root@10.10.1.102 "halt -p"')
		child.expect('L2.*$')

	if level > 1:
		os.system('ssh root@10.10.1.101 "halt -p"')
		child.expect('L1.*$')

	os.system('ssh root@10.10.1.100 "halt -p"')
	child.expect('kvm-node.*')

def reboot(pvpassthrough, level):
	halt(pvpassthrough, level)
	boot_nvm(pvpassthrough, level)

parser = argparse.ArgumentParser()
parser.add_argument("-p", "--pvpassthrough", help="enable pv-passthrough", action='store_true')
parser.add_argument("-l", "--level", help="set virtualization level")
args = parser.parse_args()

pvpassthrough = False
if args.pvpassthrough:
	pvpassthrough = True

level = 2
if args.level:
	level = int(args.level)

child = pexpect.spawn('bash')
child.logfile = sys.stdout
child.timeout=None

child.sendline('')
child.expect('kvm-node.*')
boot_nvm(pvpassthrough, level)

serversocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
serversocket.bind(('', 8889))
serversocket.listen(1) # become a server socket.

connection, address = serversocket.accept()

while True:
    buf = connection.recv(64)
    if len(buf) > 0:
        print buf
	if buf == "reboot":
		reboot(pvpassthrough, level)
		connection.send("ready")
	elif buf == "halt":
		halt(pvpassthrough, level)
		break;
