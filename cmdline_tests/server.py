#!/usr/bin/python

import pexpect
import sys
import os
import datetime
import time
import socket
import argparse

LOCAL_SOCKET = 8890
def pin_vcpus():
	os.system('cd /srv/vm/qemu/scripts/qmp/ && sudo ./pin_vcpus.sh && cd -')
	os.system('ssh root@10.10.1.100 "cd vm/qemu/scripts/qmp/ && ./pin_vcpus.sh"')
	print ("vcpu is pinned")

def boot_nvm(pvpassthrough):

	if pvpassthrough:
		child.sendline('cd /srv/vm && ./run-guest-smmu.sh')
	else:
		child.sendline('cd /srv/vm && ./run-guest.sh')

        child.expect('L1.*$')

	if pvpassthrough:
		child.sendline('cd ~/vm && ./run-guest-vfio.sh')
	else:
		child.sendline('cd ~/vm && ./run-guest.sh')

        child.expect('L2.*$')
	time.sleep(2)
	pin_vcpus()
	time.sleep(2)

def reboot(pvpassthrough):
	
	# Kill VM. (we may do halt -p)
	os.system('pgrep qemu | xargs sudo kill -9')
	time.sleep(2)

	child.expect('kvm-node.*')
	boot_nvm(pvpassthrough)

parser = argparse.ArgumentParser()
parser.add_argument("-p", "--pvpassthrough", help="enable pv-passthrough", action='store_true')
args = parser.parse_args()

pvpassthrough = False
if args.pvpassthrough:
	pvpassthrough = True

child = pexpect.spawn('bash')
child.logfile = sys.stdout
child.timeout=None

child.sendline('')
child.expect('kvm-node.*')
boot_nvm(pvpassthrough)

serversocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
serversocket.bind(('', 8889))
serversocket.listen(1) # become a server socket.

connection, address = serversocket.accept()

while True:
    buf = connection.recv(64)
    if len(buf) > 0:
        print buf
	if buf == "reboot":
		reboot(pvpassthrough)
		connection.send("ready")
