#!/usr/bin/python

import pexpect
import sys
import os
import time
import socket
from datetime import datetime
from sk_common import *
from mi_common import *

#Client status
C_NULL = 0
C_WAIT_FOR_BOOT_CMD = 1
C_BOOT_COMPLETED = 2
C_MIGRATION_COMPLETED = 3

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
			c.send(MSG_BOOT_COMPLETED)
			status = C_BOOT_COMPLETED
	elif status == C_BOOT_COMPLETED:
		if buf == MSG_MIGRATE:
			print "start migration"
			time.sleep(2)
			print "migration completed"
			c.send(MSG_BOOT_COMPLETED)
			status = C_MIGRATION_COMPLETED

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
			if status == C_MIGRATION_COMPLETED:
				print ("Job done. Terminating the script")
				break;

if __name__ == '__main__':
	main()
