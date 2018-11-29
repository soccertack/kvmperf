#!/usr/bin/python

import pexpect
import sys
import os
import datetime
import time
import socket
import argparse
import struct

LOCAL_SOCKET = 8890

serversocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

unpacker = struct.Struct('I 6s f')

print ("Try to bind...")
try:
	serversocket.bind(('', LOCAL_SOCKET))
except socket.error:
	halt(level)
	sys.exit(0)
print ("Done.")

print ("Try to listen...")
serversocket.listen(1) # become a server socket.
print ("Done.")

print ("Try to accept...")
connection, address = serversocket.accept()
print ("Done.")

while True:
    print ("Waiting for incoming messages.")
    buf = connection.recv(unpacker.size)
    if not buf:
	    print ('connection closed')
	    break;
    unpacked_data = unpacker.unpack(buf)
    if unpacked_data[1] != '0xbeef':
    	print (unpacked_data[1])

