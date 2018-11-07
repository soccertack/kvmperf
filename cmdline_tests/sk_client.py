#!/usr/bin/python

import pexpect
import sys
import os
import time
import socket
from datetime import datetime
from sk_common import *

def connect_to_server():
	print("Trying to connect to the server")
	clientsocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
	clientsocket.connect(('10.10.1.1', PORT))
	print("Connected")
	return clientsocket

def main():

	clientsocket = connect_to_server()

	while 1:
		clientsocket.send('ping')
		time.sleep(1)

		while True:
			print("Waiting to get a message from the server")
			buf = clientsocket.recv(size)
			if not buf:
				print("Server is disconnected")
				sys.exit(0)
			else:
				print buf
		

if __name__ == '__main__':
	main()
