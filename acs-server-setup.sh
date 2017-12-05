#!/bin/bash -eux


PATH_TO_FILE=/home/ubuntu/acs-server-setup
LOGFILE=$PATH_TO_FILE/acs-server-setup.log
UPDATE_STATE_FILE=$PATH_TO_FILE/update-state.txt



#export DEBIAN_FRONTEND=noninteractive
#export DEBIAN_PRIORITY=critical

exec >> $LOGFILE 2>&1


# Function do set the update state to a file
function setUpdateState {
   UPDATE_STATE=$1
   doLog "Set the update State to $1"
   echo $UPDATE_STATE > $UPDATE_STATE_FILE
}

function doLog {
   echo $1
   #echo $1 >> $LOGFILE
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
   #DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" upgrade
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

   doLog "==> 2.1.1 Edit .bashrc"
   cat $PATH_TO_FILE/bashrc >> /home/ubuntu/.bashrc
   setUpdateState 3
   # Fall through
   ;&


3) # Installation step 3: User specific config 2


   doLogUpdateState "UPDATE-STATE 3: User specific config 2"
   doLog "==> 2.1.2 Edit vi colorscheme"
   echo "colorscheme desert" > /home/ubuntu/.vimrc

   doLog "==> 2.2 change user rights for curl and wget"
   chmod 744 /usr/bin/curl
   chmod 744 /usr/bin/wget

   doLog "==> 2.3 install nfs-common"
   echo "User: $(whoami)"
   echo "Path: $PATH"
   mkdir /mnt/s3
   DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install s3fs
  
   if [ $? -ne 0 ];
   then
       doLog "error installing s3fs"
   else
       doLog "ok installing s3fs"
   fi
   s3fs acentic-playground-useast1 /mnt/s3 -o use_cache=/tmp,allow_other,iam_role=`curl http://169.254.169.254/latest/meta-data/iam/security-credentials/` 
   
   #DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install nfs-common
   if [ $? -ne 0 ];
   then
       doLog "error mounting"
   else
       doLog "ok mounting"
   fi
   #read -n1 -r -p "Press space to continue..." key

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

   if [ $( cat /proc/sys/net/ipv6/conf/all/disable_ipv6) -ne 1 ];
   then
       doLog "==> 2.5 disable ipv6"
       echo "net.ipv6.conf.all.disable_ipv6=1" >> /etc/sysctl.conf
       echo "net.ipv6.conf.default.disable_ipv6=1" >> /etc/sysctl.conf
       echo "net.ipv6.conf.lo.disable_ipv6=2" >> /etc/sysctl.conf
       sysctl -p
   fi



   doLog "==> 2.7 swap file "
   echo "/swapfile none swap sw 0 0" >> /etc/fstab


   doLog "==> 2.8 add user tomcat7"
   useradd -u 106 tomcat7
   groupadd -g 111 tomcat7
   
   setUpdateState 9
   sleep 2
   reboot
   ;;

4)
   doLogUpdateState "UPDATE-State 4:"
   ;; 


9)
   doLogUpdateState "UPDATE-State 9: UPDATE FINISHED"
   touch $PATH_TO_FILE/UPDATE_FINISHED

   doLog "==> delete crontab for ubuntu"
   crontab -r || true		# ignore error message
   setUpdateState 10
   ;;

10)
   ;;

esac



















