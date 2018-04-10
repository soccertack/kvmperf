#/usr/bin/python

import pexpect
import sys
import os
import time
import socket
from datetime import datetime

def run_stream():
	os.system('ssh root@10.10.1.101 "sudo service netperf start"')
	time.sleep(1)
	os.system("./netperf.sh 10.10.1.101 TCP_STREAM netperf-stream.txt")
	os.system('ssh root@10.10.1.101 "sudo service netperf stop"')

def run_apache():
	os.system('ssh root@10.10.1.101 "sudo service apache2 start"')
	time.sleep(1)
	os.system("./apache.sh 10.10.1.101")
	os.system('ssh root@10.10.1.101 "sudo service apache2 stop"')

def run_memcached(n_run, out_filename = "memcached.txt"):
	os.system('ssh root@10.10.1.101 "sudo service memcached start"')
	time.sleep(1)
	os.system("./memcached.sh 10.10.1.101 %d %s" % (n_run, out_filename))
	os.system('ssh root@10.10.1.101 "sudo service memcached stop"')

def move_data(experiment_name, i):
	os.system("mkdir -p %s/%d" % (experiment_name, i))
	os.system("mv *.txt %s/%d" % (experiment_name, i))
	return

print("Trying to connect to the server")
clientsocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
clientsocket.connect(('10.10.1.2', 8889))
print("Connected")

if len(sys.argv) > 1:
	experiment_name = sys.argv[1]
else:
	experiment_name = "default"

i = 0

while 1:
	i += 1

	print("start a test run")
	print(str(datetime.now()))

	run_stream()

	print("end a test run")
	print(str(datetime.now()))

	move_data(experiment_name, i)

	clientsocket.send('reboot')

	while True:
		print("Waiting to get a reboot message from the server")
		buf = clientsocket.recv(64)
		if len(buf) > 0:
			print buf
			if buf == "ready":
				print "ready is received"
				break


