#!/usr/bin/python

import pexpect
import sys
import os
import time
import socket
from datetime import datetime
import argparse

L0_IP="10.10.1.2"
L1_IP="10.10.1.100"
L2_IP="10.10.1.101"
L3_IP="10.10.1.102"


def setup_experiments(ip_addr):
	setup_nginx(ip_addr)
	setup_apache(ip_addr)

def run_mysql(ip_addr):
	os.system("./mysql.sh run %s root /root/kvmperf/cmdline_tests" % ip_addr)

def setup_nginx(ip_addr):
	nginx_cfg_cmd = "sed -i 's|access_log.*|access_log /dev/null;|g' /etc/nginx/nginx.conf"
	os.system('ssh root@%s "%s"' % (ip_addr, nginx_cfg_cmd))

	nginx_rm_access_log = "rm -f /var/log/nginx/access.log*"
	os.system('ssh root@%s "%s"' % (ip_addr, nginx_rm_access_log))

def setup_apache(ip_addr):
	apache_cfg_cmd = "find /etc/apache2/sites-enabled/* -exec sed -i 's/#*[Cc]ustom[Ll]og/#CustomLog/g' {} \;"
	os.system('ssh root@%s "%s"' % (ip_addr, apache_cfg_cmd))

	apache_rm_access_log = "rm -f /var/log/apache2/access.log*"
	os.system('ssh root@%s "%s"' % (ip_addr, apache_rm_access_log))

def run_nginx(ip_addr):
	os.system('ssh root@%s "sudo service nginx start"' % ip_addr)
	time.sleep(1)
	os.system("./nginx.sh %s" % ip_addr)
	os.system('ssh root@%s "sudo service nginx stop"' % ip_addr)

def run_netperf(name, ip_addr):

	filename = "netperf-" + name + ".txt"
	if name == "stream":
		testname = "TCP_STREAM"
	elif name == "maerts":
		testname = "TCP_MAERTS"
	elif name == "rr":
		testname = "TCP_RR"
	else:
		return
	
	os.system('ssh root@%s "sudo service netperf start"' % ip_addr)
	time.sleep(1)
	os.system("./netperf.sh %s %s %s" % (ip_addr, testname, filename))
	os.system('ssh root@%s "sudo service netperf stop"' % ip_addr)

def run_stream(ip_addr):
	run_netperf("stream", ip_addr)

def run_maerts(ip_addr):
	run_netperf("maerts", ip_addr)

def run_rr(ip_addr):
	run_netperf("rr", ip_addr)

def run_apache(ip_addr):
	os.system('ssh root@%s "sudo service apache2 start"' % ip_addr)
	time.sleep(1)
	os.system("./apache.sh %s" % ip_addr)
	os.system('ssh root@%s "sudo service apache2 stop"' % ip_addr)

def run_memcached(ip_addr, n_run = 40, out_filename = "memcached.txt"):
	os.system('ssh root@%s "sudo service memcached start"' % ip_addr)
	time.sleep(1)
	os.system("./memcached.sh %s %d %s" % (ip_addr, n_run, out_filename))
	os.system('ssh root@%s "sudo service memcached stop"' % ip_addr)

def move_data(experiment_name, i):
	os.system("mkdir -p %s/%d" % (experiment_name, i))
	os.system("mv *.txt %s/%d" % (experiment_name, i))
	return

def run_tests(ip_addr):
	print("start a test run")
	print(str(datetime.now()))

	run_memcached(ip_addr)
	run_apache(ip_addr)
	run_rr(ip_addr)
	run_mysql(ip_addr)
	run_stream(ip_addr)
	run_maerts(ip_addr)
	run_nginx(ip_addr)

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
	parser.add_argument("-l", "--level", help="virt level")
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

	ip_addr = L2_IP
	if args.level and int(args.level) == 0:
		ip_addr = L0_IP
	if args.level and int(args.level) == 1:
		ip_addr = L1_IP
	if args.level and int(args.level) == 3:
		ip_addr = L3_IP

	print ('Name: %s, iterations: %d, reboot: %d' % (experiment_name, iterations, reboot))

	os.system("rm *.txt")

	reboot_cnt = 0

	clientsocket = ""
	if ip_addr != L0_IP:
		clientsocket = connect_to_server()

	setup_experiments(ip_addr)

	while 1:
		# We want to start from idx 1
		start = reboot_cnt * iterations + 1
		end = start + iterations
		for i in range(start, end):
			run_tests(ip_addr)
			move_data(experiment_name, i)

		if reboot <= reboot_cnt :
			break

		# We don't reboot using the script for the L0 case
		if ip_addr == L0_IP:
			sys.exit(0)

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

	if ip_addr != L0_IP:
		clientsocket.send('halt')

if __name__ == '__main__':
	main()
