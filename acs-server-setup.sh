#!/bin/bash
set -x
echo "colorscheme desert" > /home/ubuntu/.vimrc
echo "Start apt-get update"
apt-get update 

DEBIAN_FRONTEND=noninteractive apt-get -y -o DPkg::options::="--force-confdef" -o DPkg::options::="--force-confold" upgrade
sleep 2
echo "Finished apt-get update"
