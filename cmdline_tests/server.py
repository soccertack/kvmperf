import pexpect
import sys
import os
import datetime
import time
import socket

LOCAL_SOCKET = 8890
def pin_vcpus():
	os.system('cd /srv/vm/qemu/scripts/qmp/ && sudo ./pin_vcpus.sh && cd -')
	os.system('ssh root@10.10.1.100 "cd vm/qemu/scripts/qmp/ && ./pin_vcpus.sh"')
	print ("vcpu is pinned")

def boot_nvm():
        child.sendline('cd ~ && ./run.sh')

        child.expect('L1.*$')
        child.sendline('./run.sh')

        child.expect('L2.*$')
	time.sleep(2)
	pin_vcpus()
	time.sleep(2)

def reboot():
	
	# Kill VM. (we may do halt -p)
	os.system('pgrep qemu | xargs sudo kill -9')
	time.sleep(2)

	child.expect('kvm-node.*')
	boot_nvm()

child = pexpect.spawn('bash')
child.logfile = sys.stdout
child.timeout=None

child.sendline('')
child.expect('kvm-node.*')
boot_nvm()

serversocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
serversocket.bind(('', 8889))
serversocket.listen(1) # become a server socket.

connection, address = serversocket.accept()

while True:
    buf = connection.recv(64)
    if len(buf) > 0:
        print buf
	if buf == "reboot":
		reboot()
		connection.send("ready")