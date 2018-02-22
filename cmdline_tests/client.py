import pexpect
import sys
import os
import time
import socket
from datetime import datetime

FULL_TH = 50000
ONE_MORE_TH = 40000

def read_last_line(filename):
	fileHandle = open ( filename ,"r" )
	lineList = fileHandle.readlines()
	fileHandle.close()
	return float(lineList[-1].rstrip())

def run_memcached(n_run, out_filename = "memcached.txt"):
	os.system('ssh root@10.10.1.101 "sudo service memcached start"')
	time.sleep(1)
	os.system("./memcached.sh 10.10.1.101 %d %s" % (n_run, out_filename))

	time.sleep(1)
	val = read_last_line(out_filename)

	print ("running memcached")
	return int(val)

def run_full(out_filename):
	for x in range(0, 5):
		name = out_filename+"-"+str(x)
		run_memcached(40, name)

clientsocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
clientsocket.connect(('10.10.1.2', 8889))

i = 0
while 1:
	i += 1

	
	print("start a test run")
	print(str(datetime.now()))
	score = run_memcached(1)
	print("end a test run")
	print(str(datetime.now()))

	if score < FULL_TH and score > ONE_MORE_TH:
		print ("second chance")
		score = run_memcached(1)

	if score > FULL_TH:
		run_full("memcached-%d"%i)
	else:
		print ("score is %d. Restart..%dth" % (score, i))
		clientsocket.send('reboot')

		while True:
			buf = clientsocket.recv(64)
			if len(buf) > 0:
				print buf
				if buf == "ready":
					print "ready is received"
					break



