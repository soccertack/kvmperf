import pexpect
import sys
import os
import datetime
import time
import socket

def pin_vcpus():
	os.system('cd /srv/vm/qemu/scripts/qmp/ && sudo ./pin_vcpus.sh && cd -')
	os.system('ssh root@10.10.1.100 "cd vm/qemu/scripts/qmp/ && ./pin_vcpus.sh"')

serversocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
serversocket.bind(('', 8889))
serversocket.listen(1) # become a server socket.

connection, address = serversocket.accept()

while True:
    buf = connection.recv(64)
    if len(buf) > 0:
        print buf
	if buf == "reboot":
		print "rebootting.. "
		time.sleep(3)
		pin_vcpus()
		time.sleep(1)
		connection.send("ready")
