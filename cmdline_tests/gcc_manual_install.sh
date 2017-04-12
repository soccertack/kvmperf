#!/bin/bash

if [[ ! -d "/var/www/html/gcc" ]]; then
	cd /var/www/html
	wget http://gcc.gnu.org/onlinedocs/gcc-4.4.7/gcc-html.tar.gz
	tar xvf gcc-html.tar.gz
fi
