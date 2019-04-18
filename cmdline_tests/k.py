#!/usr/bin/python

import pexpect
import sys
import os
import datetime
import time
import socket
import argparse

l1_addr='10.10.1.100'

def wait_for_prompt(child, hostname):
    child.expect('%s.*#' % hostname)

def pin_vcpus(level):
        if level == 0:
	        os.system('cd /srv/vm/qemu/scripts/qmp/ && sudo ./pin_vcpus.sh && cd -')
	if level == 1:
		os.system('ssh root@%s "cd vm/qemu/scripts/qmp/ && ./pin_vcpus.sh"' % l1_addr)
	if level == 2:
		os.system('ssh root@10.10.1.101 "cd vm/qemu/scripts/qmp/ && ./pin_vcpus.sh"')
	print ("vcpu is pinned")

cmd_cd = 'cd /srv/vm'
cmd_pv = './run-guest.sh'
cmd_vfio = './run-guest-vfio.sh'
cmd_viommu = './run-guest-viommu.sh'
cmd_vfio_viommu = './run-guest-vfio-viommu.sh'

pin_waiting='waiting for connection.*server'

hostname = os.popen('hostname | cut -d . -f1').read().strip()

child = pexpect.spawn('bash')
#https://stackoverflow.com/questions/29245269/pexpect-echoes-sendline-output-twice-causing-unwanted-characters-in-buffer
#child.logfile = sys.stdout
child.logfile_read=sys.stdout
child.timeout=None

child.sendline('')
wait_for_prompt(child, hostname)

child.sendline('echo 1 >/sys/kernel/debug/kvm/ipi_opt')
wait_for_prompt(child, hostname)

PI = ' --pi'
OV = ' -o' #overcommit
PIN = ' -w'

child.sendline(cmd_cd + ' && ' + cmd_viommu + PIN + PI)
child.expect(pin_waiting)

pin_vcpus(0)
child.expect('L1.*$')

child.sendline(cmd_cd + ' && ' + cmd_vfio_viommu + PIN + PI)
child.expect(pin_waiting)

pin_vcpus(1)
child.expect('L2.*$')

child.sendline(cmd_cd + ' && ' + cmd_vfio + PIN)
child.expect(pin_waiting)

pin_vcpus(2)
child.expect('L3.*$')

child.sendline('sleep 60')
child.expect('L3.*$')

child.sendline('ping -c 10 10.10.1.1')
child.interact()
sys.exit(0)
