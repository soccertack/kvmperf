import pexpect
import sys

child = pexpect.spawn('bash')
child.logfile = sys.stdout
child.timeout=None

child.sendline('')
child.expect('kvm-node.*')
child.sendline('./run.sh')

child.expect('L1.*')
child.sendline('./run.sh')

child.expect('L2.*')

while True:
    connection, address = serversocket.accept()
    buf = connection.recv(64)
    if len(buf) > 0:
        print buf
        break
