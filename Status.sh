#!/bin/bash

PID=$1 
while true; 
do
    if [ -d "/proc/$PID/task/" ]; then
       #result=$(ps -p $PID -L  -o pid=,tid=,psr=,pcpu=,stat= | paste -d,  -s)
       result=$(ps -p $PID -L  -o psr=,pcpu=,stat= | paste -d,  -s)

       time=$(date +"%H:%M:%S:%N")
       if [[ $? != 1 ]]; then
           echo -n $time " " $result " " >> Stat.log ;          
           echo " " >> Stat.log
       fi
    else
       break ;
    fi
    sleep 0.14
done 
