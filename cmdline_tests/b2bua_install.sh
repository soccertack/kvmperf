#!/bin/bash

if [[ "`whoami`" != "root" ]]; then
	echo "Please run as root" >&2
	exit 1
fi

git clone https://github.com/sobomax/libelperiodic.git
cd libelperiodic
./configure && make && make install

mkdir /usr/local/lib/python2.7/dist-packages/elperiodic/
cp python/* /usr/local/lib/python2.7/dist-packages/elperiodic/

cd ..
rm -rf libelperiodic

apt-get install python-dev
pip install git+https://github.com/columbia/b2bua
