#!/bin/bash

git clone -b v3.5.2  https://github.com/SIPp/sipp.git
apt-get update
sudo apt-get -y install pkg-config libsctp-dev libgsl0-dev libpcap-dev libssl-dev
cd sipp
./build.sh --full


