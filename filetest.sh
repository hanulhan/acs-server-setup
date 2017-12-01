#!/bin/bash -eux

if [ ! -f /home/ubuntu/acs-server-setup/update-state.txt ];
then
    echo "File does not exists. Create it"
    touch update-state.txt
    echo "0" > update-state.txt
    UPDATE_STATE=0
else
    UPDATE_STATE=$(< update-state.txt)
    echo "File exists. UpdateState= $UPDATE_STATE"
fi

case $UPDATE_STATE in
0)
   echo "UpdateState is 0"
   UPDATE_STATE=1
   ;&

1)
   echo "UpdateState is 1"
   UPDATE_STATE=2
   ;;

2)
   echo "UpdateState is 2"
   UPDATE_STATE=3
   ;;

3)
   echo "UpdateState is 3. Updates finished"
   ;;

esac


echo $UPDATE_STATE > update-state.txt

