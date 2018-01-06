import pexpect
import sys
import os
from datetime import datetime
import time
import socket

clientsocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
clientsocket.connect(('10.10.1.2', 8889))

TIMEOUT=60.0

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
			sys.exit() 
		if len(buf) > 0:
			print buf
			if buf == "ready":
				print "ready is received"
				break



