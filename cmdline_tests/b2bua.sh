#!/bin/bash

if [[ "`whoami`" != "root" ]]; then
	echo "Please run as root" >&2
	exit 1
fi

export LD_LIBRARY_PATH=/usr/local/lib
export SIPLOG_LVL=CRIT

b2bua_simple -f -n 10.10.1.3
