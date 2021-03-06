#!/usr/bin/python

import pexpect
import sys
import os
from datetime import datetime
import time
import socket

TIMEOUT=60.0

def send_msg(msg):
	experiment_name=""
	if len(sys.argv) > 1:
		experiment_name = sys.argv[1]
	msg_send_cmd="ssh -o StrictHostKeyChecking=no jintack@128.59.18.193 '/home/jintack/send_tg.sh [%s]%s'" % (experiment_name, msg)
	os.system(msg_send_cmd)


clientsocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
clientsocket.connect(('10.10.1.2', 8889))

send_msg("L2-boot-test-start")
i = 0
while 1:
	i += 1

	print("Restart..%dth" % (i))
	print(str(datetime.now()))
	clientsocket.send('reboot')

	while True:
		clientsocket.settimeout(TIMEOUT);
		try:
			buf = clientsocket.recv(64)
		except socket.timeout as e:
			print type(e)
			print("The socket timed out, try it again.")
			send_msg("L2-boot-failed")
			sys.exit()

		if len(buf) > 0:
			print buf
			if buf == "ready":
				print "ready is received"
				break



