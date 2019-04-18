#!/usr/bin/python

import pexpect
import sys
import os
import time
import socket
from datetime import datetime
from sk_common import *
from mi_common import *
import mi_api

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

	while True:
		try:
			clientsocket.connect(('10.10.1.1', PORT))
			break;
		except:
			print ('connect error. Try again')
			time.sleep(1)


	print("Connected")
	return clientsocket

def handle_recv(c, buf):
	global status

	print buf + " is received"
	if status == C_WAIT_FOR_BOOT_CMD:
		if buf == MSG_BOOT:
			mi_api.init()
			mi_api.boot_vms()
			c.send(MSG_BOOT_COMPLETED)
			status = C_BOOT_COMPLETED
	elif status == C_BOOT_COMPLETED:
		if buf == MSG_MIGRATE:
			print "start migration"
			child = mi_api.get_child()
			mi = mi_api.get_mi_level()
#			child.sendline('migrate_set_speed 4095m')
#			child.expect('\(qemu\)')
			if mi == 'l2':
				child.sendline('migrate -d tcp:10.10.1.110:5555')
			elif mi == 'l1':
				child.sendline('migrate -d tcp:10.10.1.3:5555')
			else:
				print("Error: mi is " + mi)
				sys.exit(1)
			child.expect('\(qemu\)')

			while True:
				time.sleep(10)
				child.sendline('info migrate')
				child.expect('\(qemu\)')
				if "Migration status: completed" in child.before:
					break;

			print "migration completed"
			print "Wait for 15 more seconds"
			time.sleep(15)
			c.send(MSG_MIGRATE_COMPLETED)
			status = C_MIGRATION_COMPLETED

	if buf == MSG_TERMINATE:
		mi_api.terminate_vms()
		c.send(MSG_TERMINATED)
		status = C_TERMINATED

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
