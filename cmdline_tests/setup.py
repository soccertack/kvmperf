#!/usr/bin/python
import pexpect
import sys
import os
import datetime
import time
import socket

def wait_for_prompt():
	child.expect('kvm-node.*\r\n')

child = pexpect.spawn('bash')
child.logfile = sys.stdout
child.timeout=None

wait_for_prompt()

child.sendline('cd ~')
wait_for_prompt()

child.sendline('git clone https://github.com/soccertack/env.git')
wait_for_prompt()

child.sendline('pushd env')
wait_for_prompt()

child.sendline('./env.py -a')
wait_for_prompt()

child.sendline('sudo ./nested.py')
wait_for_prompt()

print("nested init done")
