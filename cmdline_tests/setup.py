#!/usr/bin/python
import pexpect
import sys
import os
import datetime
import time
import socket

child = pexpect.spawn('bash')
child.logfile = sys.stdout
child.timeout=None

child.sendline('')
child.expect('kvm-node.*')
child.sendline('cd ~')
child.expect('kvm-node.*')
child.sendline('git clone https://github.com/soccertack/env.git')
child.expect('kvm-node.*')
child.sendline('pushd env')
child.expect('kvm-node.*')
child.sendline('./env.py -a')
child.expect('kvm-node.*')
child.sendline('sudo ./nested.py')
child.expect('kvm-node.*')
print("nested init done")
