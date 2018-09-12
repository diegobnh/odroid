#!/bin/bash

PID=$1 
while true; 
do 
    #ps -mo tid,psr -p $PID | grep -Eo '[0-9]' >> Mapping.log ;
    result=$(ps -mo tid,psr -p $PID)
    time=$(date +"%H:%M:%S:%N")
    if [[ $? != 1 ]]; then
        echo $time >> Mapping.log
        ps -mo tid,psr -p $PID >> Mapping.log
        echo "" >> Mapping.log
    else
        break;
    fi
    sleep 0.14
done
