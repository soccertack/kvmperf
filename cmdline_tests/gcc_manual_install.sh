#!/bin/bash

NGINX_ROOT="/usr/share/nginx/html"
if [[ "`whoami`" != "root" ]]; then
	echo "Please run as root" >&2
	exit 1
fi

if [[ ! -d "$NGINX_ROOT/gcc" ]]; then
	if [[ ! -d "$NGINX_ROOT" ]]; then
		echo "nginx root directory is missing."
		echo "installation incomplete"
		exit 1
	fi
	cd $NGINX_ROOT
	wget http://gcc.gnu.org/onlinedocs/gcc-4.4.7/gcc-html.tar.gz
	tar xvf gcc-html.tar.gz
fi
