#!/bin/bash


rm Power2.log Stat.log Mapping.log

/home/odroid/meabo/./meabo.armv7 -C 8 -r 2048 -c 2048 -s 131072 -l 2097152 -p 131072 -R 262144  &

PidMeabo=`pgrep -f meabo`


sudo ./Status.sh $PidMeabo &
sudo ./Mapping.sh $PidMeabo &
grabserial -T -d /dev/ttyUSB0  >> Power2.log & 




PidPower=`pgrep -f grabserial`

 
echo "Pid Meabo="$PidMeabo
echo "Pid Power="$PidPower


wait $PidMeabo

echo "Killing Power"
sudo kill -9 $PidPower
echo "Killing Mapping"
sudo pkill Mapping 
echo "Killing Status"
sudo pkill Status



