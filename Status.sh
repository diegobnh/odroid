#!/bin/bash

rm Stat.log
PID=$1 
while true; 
do
    if [ -d "/proc/$PID/task/" ]; then
       result=$(cat /proc/$PID/task/*/stat | awk '{ print $1 " " $3 }')
       time=$(date +"%H:%M:%S")
       if [[ $? != 1 ]]; then
           echo $time " " $result >> Stat.log ;                           
       fi
    else
       break ;
    fi
done 
