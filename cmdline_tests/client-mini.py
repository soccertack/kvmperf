#!/usr/bin/python

import pexpect
import sys
import os
import time
import socket
import struct
from datetime import datetime

#https://pymotw.com/2/socket/binary.html
values = (1, '0xbeef', 2.7)
packer = struct.Struct('I 6s f')
packed_data = packer.pack(*values)

print (sys.getsizeof(packed_data))

LOCAL_SOCKET = 8890
clientsocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
clientsocket.connect(('10.10.1.1', LOCAL_SOCKET))

i = 0
while 1:
	clientsocket.send(packed_data)
	i += 1
	if i > 10:
		break;
