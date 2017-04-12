#!/bin/bash

source gcc_manual_install.sh

which nginx > /dev/null
if [[ $? != 0 ]]; then
	apt-get install -y nginx 
	update-rc.d nginx disable
fi

which siege > /dev/null
if [[ $? != 0 ]]; then
	sudo apt-get install -y siege
fi
