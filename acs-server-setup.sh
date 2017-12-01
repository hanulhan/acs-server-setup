#!/bin/bash -eux

PATH_TO_FILE=/home/ubuntu/acs-server-setup
LOGFILE=$PATH_TO_FILE/acs-server-setup.txt
UPDATE_STATE_FILE=$PATH_TO_FILE/update-state.txt


if [ ! -f $LOGFILE ];
then
    touch $LOGFILE
fi



function setUpdateState {
   UPDATE_STATE=$1
   echo $UPDATE_STATE > $UPDATE_STATE_FILE
}

function doLog {
   echo $1
   echo $1 >> $LOGFILE
}




if [ ! -f $UPDATE_STATE_FILE ];
then
    doLog "File does not exists. Create it"
    touch $UPDATE_STATE_FILE
    setUpdateState 0
    rm $LOGFILE
else
    UPDATE_STATE=$(< ${UPDATE_STATE_FILE})
    doLog "File exists. UpdateState= $UPDATE_STATE"
fi


if [ ! -f $LOGFILE ];
then
   touch $LOGFILE
   doLog "Restart script"
else
   doLog "Start script"
fi


case $UPDATE_STATE in
0)
   doLog "UpdateState is 0"
   setUpdateState 1
   echo "colorscheme desert" > /home/ubuntu/.vimrc

   # Disable the release upgrader
   doLog "==> Disabling the release upgrader"
   sed -i.bak 's/^Prompt=.*$/Prompt=never/' /etc/update-manager/release-upgrades

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


   echo "@reboot /home/ubuntu/acs-server-setup/acs-server-setup.sh" > mycron
   crontab mycron
   rm mycron


   apt-get -y update
   sleep 5
   doLog "==> Performing dist-upgrade (all packages and kernel)"
   DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" upgrade
   sleep 5

   doLog "Finished apt-get upgrade. Reboot now"
   setUpdateState 5
   reboot
   ;;

2)
   doLog "UPDATE FINISHED"
   touch $PATH_TO_FILE/UPDATE_FINISHED
   crontab -r
   setUpdateState 3
   ;;



esac



















