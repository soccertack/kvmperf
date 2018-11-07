#!/usr/bin/python

import pexpect
import sys
import os
import time
import socket
from datetime import datetime
from sk_common import *
from mi_common import *
from mi_api import *

#Client status
C_NULL = 0
C_WAIT_FOR_BOOT_CMD = 1
C_BOOT_COMPLETED = 2
C_MIGRATION_COMPLETED = 3
C_TERMINATED = 4

status = C_NULL

def connect_to_server():
	print("Trying to connect to the server")
	clientsocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
	clientsocket.connect(('10.10.1.1', PORT))
	print("Connected")
	return clientsocket

def handle_recv(c, buf):
	global status
	print buf + " is received"
	if status == C_WAIT_FOR_BOOT_CMD:
		if buf == MSG_BOOT:
			boot_nvm(iovirt, posted, level, mi, mi_role)
			c.send(MSG_BOOT_COMPLETED)
			status = C_BOOT_COMPLETED
	elif status == C_BOOT_COMPLETED:
		if buf == MSG_MIGRATE:
			print "start migration"
			child.sendline('migrate_set_speed 4095m')
			child.expect('\(qemu\)')
			child.sendline('migrate -d tcp:10.10.1.110:5555')
			child.expect('\(qemu\)')

			child.sendline('info migrate')
			child.expect('\(qemu\)')
			time.sleep(2)
			print "migration completed"
			c.send(MSG_MIGRATE_COMPLETED)
			status = C_MIGRATION_COMPLETED

	if buf == MSG_TERMINATE:
		print ("Terminate VM.")
		child.sendline('stop')
		child.expect('\(qemu\)')
		child.sendline('q')
		child.expect('L1.*$')
		child.sendline('h')
		status = C_TERMINATED
		wait_for_prompt(child, hostname)

def main():
	global status

	clientsocket = connect_to_server()
	status = C_WAIT_FOR_BOOT_CMD

	while True:
		buf = clientsocket.recv(size)
		if not buf:
			print("Server is disconnected")
			sys.exit(0)
		else:
			handle_recv(clientsocket, buf)
			if status == C_TERMINATED:
				break;

if __name__ == '__main__':
	main()
