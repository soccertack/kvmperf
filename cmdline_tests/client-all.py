#!/usr/bin/python

import pexpect
import sys
import os
import time
import socket
from datetime import datetime
import argparse

def run_nginx():
	os.system('ssh root@10.10.1.101 "sudo service nginx start"')
	time.sleep(1)
	os.system("./nginx.sh 10.10.1.101")
	os.system('ssh root@10.10.1.101 "sudo service nginx stop"')

def run_netperf(name):

	filename = "netperf-" + name + ".txt"
	if name == "stream":
		testname = "TCP_STREAM"
	elif name == "maerts":
		testname = "TCP_MAERTS"
	elif name == "rr":
		testname = "TCP_RR"
	else:
		return
	
	os.system('ssh root@10.10.1.101 "sudo service netperf start"')
	time.sleep(1)
	os.system("./netperf.sh 10.10.1.101 %s %s" % (testname, filename))
	os.system('ssh root@10.10.1.101 "sudo service netperf stop"')

def run_stream():
	run_netperf("stream")

def run_maerts():
	run_netperf("maerts")

def run_rr():
	run_netperf("rr")

def run_apache():
	os.system('ssh root@10.10.1.101 "sudo service apache2 start"')
	time.sleep(1)
	os.system("./apache.sh 10.10.1.101")
	os.system('ssh root@10.10.1.101 "sudo service apache2 stop"')

def run_memcached(n_run = 40, out_filename = "memcached.txt"):
	os.system('ssh root@10.10.1.101 "sudo service memcached start"')
	time.sleep(1)
	os.system("./memcached.sh 10.10.1.101 %d %s" % (n_run, out_filename))
	os.system('ssh root@10.10.1.101 "sudo service memcached stop"')

def move_data(experiment_name, i):
	os.system("mkdir -p %s/%d" % (experiment_name, i))
	os.system("mv *.txt %s/%d" % (experiment_name, i))
	return

def run_tests():
	print("start a test run")
	print(str(datetime.now()))

	run_stream()
	run_maerts()
	run_rr()
	run_memcached()
	run_apache()
	run_nginx()

	print("end a test run")
	print(str(datetime.now()))

def connect_to_server():
	print("Trying to connect to the server")
	clientsocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
	clientsocket.connect(('10.10.1.2', 8889))
	print("Connected")
	return clientsocket


def main():
	parser = argparse.ArgumentParser()
	parser.add_argument("-n", "--name", help="setup experiment name")
	parser.add_argument("-i", "--iterations", help="setup per-reboot iterations")
	parser.add_argument("-r", "--reboot", help="setup number of reboot")
	args = parser.parse_args()

	experiment_name = "default"
	if args.name:
		experiment_name = args.name

	reboot = 0 
	if args.reboot:
		reboot = int(args.reboot)

	iterations = 1 
	if args.iterations:
		iterations = int(args.iterations)

	print ('Name: %s, iterations: %d, reboot: %d' % (experiment_name, iterations, reboot))

	os.system("rm *.txt")

	reboot_cnt = 0

	clientsocket = connect_to_server()

	while 1:
		# We want to start from idx 1
		start = reboot_cnt * iterations + 1
		end = start + iterations
		for i in range(start, end):
			run_tests()
			move_data(experiment_name, i)

		if reboot <= reboot_cnt :
			break

		clientsocket.send('reboot')

		while True:
			print("Waiting to get a reboot message from the server")
			buf = clientsocket.recv(64)
			if len(buf) > 0:
				print buf
				if buf == "ready":
					print "ready is received"
					break
		
		reboot_cnt += 1


if __name__ == '__main__':
	main()
