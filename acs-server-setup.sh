#!/bin/bash
set -x
echo "colorscheme desert" > /home/ubuntu/.vimrc
echo "Start apt-get update"
apt-get update && echo 'y' | sudo apt-get upgrade
sleep 2
echo "Finished apt-get update"
