#!/usr/bin/python

import pexpect
import sys
import os
import datetime
import time
import socket
from datetime import datetime

def send_msg(msg):
	experiment_name=""
	if len(sys.argv) > 1:
		experiment_name = sys.argv[1]
	msg_send_cmd="ssh jintack@128.59.18.193 '/home/jintack/send_tg.sh [%s]%s'" % (experiment_name, msg)
	os.system(msg_send_cmd)

LOCAL_SOCKET = 8890
def pin_vcpus():
	os.system('cd /srv/vm/qemu/scripts/qmp/ && sudo ./pin_vcpus.sh && cd -')
	os.system('ssh root@10.10.1.100 "cd vm/qemu/scripts/qmp/ && ./pin_vcpus.sh"')
	print ("vcpu is pinned")

def boot_nvm():
        child.sendline('cd ~ && ./run.sh')
	try:
		child.expect('L1.*$', timeout=60)
		child.sendline('./run.sh')

	        child.expect('L2.*$', timeout=60)
		time.sleep(10)
		return 0
	except pexpect.TIMEOUT:
		return 1

child = pexpect.spawn('bash')
child.logfile = sys.stdout
child.timeout=None

child.sendline('')
child.expect('kvm-node.*')

i = 0
send_msg("Reboot-test-started")
while True:
	print("Restart..%dth" % (i))
	print(str(datetime.now()))
	ret = boot_nvm()
	if ret:
		msg = "Timeout! Quit testing. We've rebooted %d times" % (i)
		print(msg)
		send_msg("Reboot-test-failed")
		break
	
	i += 1

	# Kill VM. (we may do halt -p)
	os.system('pgrep qemu | xargs sudo kill -9')
	time.sleep(2)
	child.expect('kvm-node.*')


