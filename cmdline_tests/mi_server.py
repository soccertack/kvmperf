#!/usr/bin/python

import select
import pexpect
import sys
import os
import datetime
import time
import socket
from sk_common import *

#Connection status fields
IDX_STATUS = 0
IDX_IP_ADDR = 1

#Server-Client status
SC_CONNECTED = 1
SC_WAIT_FOR_BOOT = 2

#Server status

def handle_recv(data):
	print (data + "is received")

def boot_nvm(conn):
	conn.send("Boot nVM")
	conn_status[conn][IDX_STATUS] = SC_WAIT_FOR_BOOT

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

print ("Try to bind...")
try:
	s.bind(('', PORT))
except socket.error:
	halt(level)
	sys.exit(0)
print ("Done.")

print ("Try to listen...")
s.listen(2) # become a server socket.
print ("Done.")

conn_status = {}
inputs = []
outputs = []
inputs.append(s)

while inputs:
	readable, writable, exceptional = select.select(inputs, outputs, inputs)

	for item in readable:
		if item == s:
			#handle connection
			conn, addr = s.accept()
			print 'Connected with ' + addr[0] + ':' + str(addr[1])
			inputs.append(conn)
			conn_status[conn] = [addr[0], SC_CONNECTED]
			boot_nvm(conn)

		else:
			data = item.recv(size)
			if data:
				handle_recv(data)
			else:
				print(conn_status[item][IDX_IP_ADDR])
				print ('Connection closed')
				del conn_status[item]
				inputs.remove(item)
				item.close()
