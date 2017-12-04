#!/bin/bash -eux

PATH_TO_FILE=/home/ubuntu/acs-server-setup
LOGFILE=$PATH_TO_FILE/acs-server-setup.txt
UPDATE_STATE_FILE=$PATH_TO_FILE/update-state.txt



# Function do set the update state to a file
function setUpdateState {
   UPDATE_STATE=$1
   doLog "Set the update State to $1"
   echo $UPDATE_STATE > $UPDATE_STATE_FILE
}

function doLog {
   echo $1
   echo $1 >> $LOGFILE
}

function doLogUpdateState {
    doLog "########## $1 ##########"
}

#Check if Logfile already exists. 
if [ ! -f $LOGFILE ];
then
   touch $LOGFILE
   doLog "Start script"
else
   doLog "Restart script"
fi


#Check if the update-state-file already exists
if [ ! -f $UPDATE_STATE_FILE ];
then
    doLog "UpdateState file does not exists. Create it"
    touch $UPDATE_STATE_FILE
    setUpdateState 1
else
    UPDATE_STATE=$(< ${UPDATE_STATE_FILE})
    doLog "UpdateState= $UPDATE_STATE"
fi





case $UPDATE_STATE in


1) #Installation step 1. Update packages
   doLogUpdateState "UPDATE-STATE 1: Update packages list"


   # install cronjob to procede execution after restart
   doLog "==> install cronjob"
   echo "@reboot /home/ubuntu/acs-server-setup/acs-server-setup.sh" > mycron
   crontab mycron
   rm mycron


   # Disable the release upgrader
   doLog "==> Disabling the release upgrader"
   sed -i.bak 's/^Prompt=.*$/Prompt=never/' /etc/update-manager/release-upgrades

   doLog "==> Checking version of Ubuntu"
   . /etc/lsb-release

   if [[ $DISTRIB_RELEASE == 16.04 ]]; then
      systemctl disable apt-daily.service # disable run when system boot
      systemctl disable apt-daily.timer   # disable timer run
   fi
   

   # get the ubuntu package list
   apt-get -y update
   sleep 5
   doLog "==> Performing upgrade (all packages and kernel)"
   DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" upgrade
   sleep 5

   doLog "==> Performing dist-upgrade (all packages and kernel)"
   DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" dist-upgrade
   sleep 5

   apt-get -y autoremove

   doLog "==> Finished apt-get upgrade. Reboot now"
   setUpdateState 2
   reboot
   ;;

2) # Installation step 2: User specific config
   doLogUpdateState "UPDATE-STATE 2: User specific config"

   doLog "==> delete crontab for ubuntu"
   crontab -r

   doLog "==> 2.1 Edit vi colorscheme"
   echo "colorscheme desert" > /home/ubuntu/.vimrc

   doLog "==> 2.1.2 Edit .bashrc"
   cat $PATH_TO_FILE/bashrc >> /home/ubuntu/.bashrc

   doLog "==> 2.2 change user rights for curl and wget"
   chmod 744 /usr/bin/curl
   chmod 744 /usr/bin/wget

   doLog "==> 2.3 install nfs-common"
   apt-get -y install nfs-common

   doLog "==> 2.4 Allow root only to add cron job"
   echo "root" > /etc/cron.allow
   echo "deamon
         bin
         smtp
         deamon
         nuucp
         listen
         nobody
         noaccess
         tomcat7
         ubunt" > /etc/cron.deny

   doLog "==> 2.5 disable ipv6"
   echo "net.ipv6.conf.all.disable_ipv6=1" >> /etc/sysctl.conf
   echo "net.ipv6.conf.default.disable_ipv6=1" >> /etc/sysctl.conf
   echo "net.ipv6.conf.lo.disable_ipv6=2" >> /etc/sysctl.conf
   sysctl -p


   doLog "IPV6 disables " | cat /proc/sys/net/ipv6/conf/all/disable_ipv6


   setUpdateState 3
   # Fall through
   ;&



3)
   doLogUpdateState "UPDATE-State 3: UPDATE FINISHED"
   touch $PATH_TO_FILE/UPDATE_FINISHED
   setUpdateState 4
   ;;



esac



















