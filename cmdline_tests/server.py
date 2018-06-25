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

def boot_nvm(iovirt, level):

	mylevel = 0
	if iovirt == "vp":
		child.sendline('cd /srv/vm && ./run-guest-viommu.sh')
	elif iovirt == "pv":
		child.sendline('cd /srv/vm && ./run-guest.sh')
	elif iovirt == "pt":
		child.sendline('cd /srv/vm && ./run-guest-vfio.sh')
	#TODO: if we want to support recursive pass-through, we should run vfio-viommu here..

        child.expect('L1.*$')
	mylevel = 1

	while (mylevel < level):
		mylevel += 1

		#TODO: take care of pt case
		if iovirt == "vp":
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

def halt(level):
	if level > 2:
		os.system('ssh root@10.10.1.102 "halt -p"')
		child.expect('L2.*$')

	if level > 1:
		os.system('ssh root@10.10.1.101 "halt -p"')
		child.expect('L1.*$')

	os.system('ssh root@10.10.1.100 "halt -p"')
	child.expect('kvm-node.*')

def reboot(iovirt, level):
	halt(level)
	boot_nvm(iovirt, level)


level  = int(raw_input("Enter virtualization level [2]: ") or "2")
if level < 1:
	print ("We don't (need to) support L0")
	sys.exit(0)
if level > 3:
	print ("Are you sure to run virt level %d?" % level)
	sleep(5)

# iovirt: pv, pt(pass-through), or vp(virtual-passthough)
iovirt = raw_input("Enter I/O virtualization level [pv]: ") or "pv"
if iovirt not in ["pv", "pt", "vp"]:
	print ("Enter pv, pt, or vp")
	sys.exit(0)

child = pexpect.spawn('bash')
child.logfile = sys.stdout
child.timeout=None

child.sendline('')
child.expect('kvm-node.*')
boot_nvm(iovirt, level)

serversocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

print ("Try to bind...")
serversocket.bind(('', 8889))
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
		reboot(iovirt, level)
		connection.send("ready")
	elif buf == "halt":
		halt(level)
		break;
