import pexpect
import sys
import os
import datetime
import time
import socket

def read_last_line(filename):
	fileHandle = open ( filename ,"r" )
	lineList = fileHandle.readlines()
	fileHandle.close()
	return float(lineList[-1].rstrip())

def run_rr_once():
	os.system('ssh root@10.10.1.101 "sudo service netperf start"')
	time.sleep(1)
	os.system("./netperf.sh 10.10.1.101 TCP_RR netperf-rr.txt 1")
	os.system('ssh root@10.10.1.101 "sudo service netperf stop"')

def wait_for(sk, string):
	while True:
		buf = sk.recv(64)
		if buf == string:
			break

clientsocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
clientsocket.connect(('10.10.1.2', 8889))

target_score = 0
if len(sys.argv) > 1:
	target_score = int(sys.argv[1])

clientsocket.send('netperf-rr-start')
wait_for(clientsocket, 'netperf-rr-ready')
while 1:

	clientsocket.send('tcpdump-start')
	wait_for(clientsocket, 'tcpdump-ready')

	run_rr_once()
	clientsocket.send('tcpdump-stop')
	wait_for(clientsocket, 'tcpdump-done')

	if not target_score:
		break;

	val = read_last_line('netperf-rr.txt')
	if val > target_score:
		break;
	

clientsocket.send('netperf-rr-done')
