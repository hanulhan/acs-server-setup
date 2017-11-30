#!/bin/bash -eux

echo "colorscheme desert" > /home/ubuntu/.vimrc
echo "Start apt-get update"

#ucf --purge /boot/grub/menu.lst
#apt-get update
#unset UCF_FORCE_CONFFOLD
#export UCF_FORCE_CONFFNEW=YES
#export DEBIAN_FRONTEND=noninteractive
#apt-get upgrade -y


# Disable the release upgrader
echo "==> Disabling the release upgrader"
sed -i.bak 's/^Prompt=.*$/Prompt=never/' /etc/update-manager/release-upgrades

echo "==> Checking version of Ubuntu"
. /etc/lsb-release

if [[ $DISTRIB_RELEASE == 16.04 ]]; then
  systemctl disable apt-daily.service # disable run when system boot
  systemctl disable apt-daily.timer   # disable timer run
fi 

echo "==> Updating list of repositories"
ucf --purge /boot/grub/menu.lst
# apt-get update does not actually perform updates, it just downloads and indexes the list of packages
#echo "${SSH_PASS}" | sudo -S dpkg --configure -a 
apt-get -y update
UPDATE=yes
if [[ $UPDATE  =~ true || $UPDATE =~ 1 || $UPDATE =~ yes ]]; then
    echo "==> Performing dist-upgrade (all packages and kernel)"
    export UCF_FORCE_CONFFNEW=YES
    apt-get -y upgrade
#    reboot
    sleep 60
fi


sleep 2
echo "Finished apt-get update"
