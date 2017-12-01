#!/bin/bash -eux

LOGFILE=/home/ubuntu/acs-server-setup/acs-server-setup.txt

if [ ! -f $LOGFILE ];
then
    touch $LOGFILE
fi



function setUpdateState {
   UPDATE_STATE=$1
   echo $UPDATE_STATE > update-state.txt
}

function doLog {
   #echo $1
   echo $1 >> $LOGFILE
}


if [ ! -f /home/ubuntu/acs-server-setup/acs-server-setup.txt ];
then
touch /home/ubuntu/acs-server-setup/acs-server-setup.txt
doLog "Start"
fi

if [ ! -f /home/ubuntu/acs-server-setup/update-state.txt ];
then
    doLog "File does not exists. Create it"
    touch update-state.txt
    setUpdateState 0
    rm acs-server-setup.txt
else
    UPDATE_STATE=$(< update-state.txt)
    doLog "File exists. UpdateState= $UPDATE_STATE"
fi

case $UPDATE_STATE in
0)
   doLog "UpdateState is 0"
   setUpdateState 1
   echo "colorscheme desert" > /home/ubuntu/.vimrc

   # Disable the release upgrader
   doLog "==> Disabling the release upgrader"
   #sed -i.bak 's/^Prompt=.*$/Prompt=never/' /etc/update-manager/release-upgrades

   doLog "==> Checking version of Ubuntu"
   . /etc/lsb-release

   if [[ $DISTRIB_RELEASE == 16.04 ]]; then
      systemctl disable apt-daily.service # disable run when system boot
      systemctl disable apt-daily.timer   # disable timer run
   fi


   # Fall through
   ;&

1)
   doLog "UpdateState is 1"


   echo "@reboot /home/ubuntu/acs-server-setup/on_reboot.sh && /home/ubuntu/acs-server-setup/acs-server-setup.sh" > mycron
   crontab mycron
   rm mycron


   apt-get -y update
   sleep 5
   doLog "==> Performing dist-upgrade (all packages and kernel)"
   #DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" upgrade
   sleep 5

   doLog "Finished apt-get update"
   setUpdateState 2
   #reboot
   ;;

2)
   doLog "UpdateState is 3. Finished"
   touch UPDATE_STATE_3.txt
   setUpdateState 3
   ;;



esac



















