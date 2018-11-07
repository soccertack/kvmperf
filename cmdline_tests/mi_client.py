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

def main():
	global status

	clientsocket = connect_to_server()
	status = C_WAIT_FOR_BOOT_CMD

	while 1:
		while True:
			print("Waiting to get a message from the server")
			buf = clientsocket.recv(size)
			if not buf:
				print("Server is disconnected")
				sys.exit(0)
			else:
				handle_recv(clientsocket, buf)
		

if __name__ == '__main__':
	main()
