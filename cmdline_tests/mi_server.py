#!/usr/bin/python

import select
import pexpect
import sys
import os
import datetime
import time
import socket
from sk_common import *
from mi_common import *

#Connection status fields
IDX_STATUS = 0
IDX_IP_ADDR = 1

#Server-Client status
SC_CONNECTED = 1
SC_WAIT_FOR_BOOT = 2
SC_NVM_READY = 3

#Server status
S_WAIT_FOR_BOOT = 1
S_NVM_READY = 2
S_MIGRAION_START = 3
S_MIGRAION_END = 4

def set_status(conn, st):
	conn_status[conn][IDX_STATUS] = st

def is_status(conn, st):
	if conn_status[conn][IDX_STATUS] == st:
		return True 
	return False

def get_ip(conn):
	return conn_status[conn][IDX_IP_ADDR]

def get_src_conn():

	for conn in clients:
		if get_ip(conn)  == "10.10.1.2":
			return conn
	return

def check_all_ready():
	src_ready = False
	dest_ready = False
	# Check if all connections are ready
	for conn in clients:
		if is_status(conn, SC_NVM_READY):
			if get_ip(conn)  == "10.10.1.2":
				src_ready = True
			if get_ip(conn)  == "10.10.1.3":
				dest_ready = True

	return src_ready and dest_ready

def terminate_all():
	for conn in clients:
		conn.send(MSG_TERMINATE)

def handle_recv(conn, data):
	global server_status
	print (data + " is received")

	# Per connection status
	if is_status(conn, SC_WAIT_FOR_BOOT):
		if data == MSG_BOOT_COMPLETED:
			set_status(conn, SC_NVM_READY)

	# Server state
	if (server_status == S_WAIT_FOR_BOOT) and check_all_ready():
		src_conn = get_src_conn()
		src_conn.send(MSG_MIGRATE)
		print("start migration")
		server_status = S_MIGRAION_START

	if server_status == S_MIGRAION_START:
		if data == MSG_MIGRATE_COMPLETED:
			print("migration is completed")
			print("Collect migration result")
			time.sleep(2)
			print("send messages to terminate VMs")
			terminate_all()
			

def boot_nvm(conn):
	conn.send(MSG_BOOT)
	conn_status[conn][IDX_STATUS] = SC_WAIT_FOR_BOOT

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

print ("Try to bind...")
try:
	s.bind(('', PORT))
except socket.error:
	print ("Bind error. Try again")
	sys.exit(0)
print ("Done.")

print ("Try to listen...")
s.listen(2) # become a server socket.
print ("Done.")

conn_status = {}
inputs = []
outputs = []
clients = []
inputs.append(s)

global server_status
server_status = S_WAIT_FOR_BOOT

while inputs:
	readable, writable, exceptional = select.select(inputs, outputs, inputs)

	for item in readable:
		if item == s:
			#handle connection
			conn, addr = s.accept()
			print 'Connected with ' + addr[0] + ':' + str(addr[1])
			inputs.append(conn)
			clients.append(conn)
			conn_status[conn] = [SC_CONNECTED, addr[0]]
			boot_nvm(conn)

		else:
			data = item.recv(size)
			if data:
				handle_recv(item, data)
			else:
				print(conn_status[item][IDX_IP_ADDR])
				print ('Connection closed')
				del conn_status[item]
				inputs.remove(item)
				clients.remove(item)
				item.close()
