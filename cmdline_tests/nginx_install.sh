#!/bin/bash

which nginx > /dev/null
if [[ $? != 0 ]]; then
	apt-get install -y nginx 
	update-rc.d nginx disable
	sed -i '/ipv6only/d' /etc/nginx/sites-available/default
fi

which siege > /dev/null
if [[ $? != 0 ]]; then
	sudo apt-get install -y siege
fi

echo "host start"
echo $PWD
source "${BASH_SOURCE%/*}/gcc_manual_install.sh"
echo "host end"
