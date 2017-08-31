import pexpect
import sys

def expect_shell():
	child.expect('.*master.*')

child = pexpect.spawn('bash')
child.logfile = sys.stdout
child.timeout=None

expect_shell()
child.sendline('ls')
expect_shell()

i = 0
# 6 is memcached
benchmark_num = 6
while 1:
	child.sendline('./run_all.sh')
	child.expect('Have you consumed memory.*')
	# Assume that we already did that.
	child.sendline('y')

	child.expect('Have you pinned vcpus.*')
	# Assume that we already did that.
	child.sendline('y')

	child.expect('Type test number:.*')
	# Select a benchmark. Repeat this line as many you want
	child.sendline(str(benchmark_num))

	child.expect('Type test number:.*')
	# That's all we want to run.
	child.sendline('')

	######################################
	# Memcached benchmarking in progress
	######################################

	expect_shell()
	# Ok. We're done. Save the result
	i += 1

	# rename the result file
	child.sendline('mv memcached.txt memcached-%d'% i)
	expect_shell()
