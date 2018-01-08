#!/usr/bin/python

import pexpect
import sys
import os
from datetime import datetime
import time
import socket

TIMEOUT=60.0
EXPERIMENT_NAME=""
if len(sys.argv) > 1:
	EXPERIMENT_NAME = sys.argv[1]

MSG_SEND_CMD="ssh jintack@128.59.19.13 '/home/jintack/send_tg.sh [%s]L2-boot-failed'" % (EXPERIMENT_NAME)

clientsocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
clientsocket.connect(('10.10.1.2', 8889))

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
			os.system(MSG_SEND_CMD)
			sys.exit()

		if len(buf) > 0:
			print buf
			if buf == "ready":
				print "ready is received"
				break



