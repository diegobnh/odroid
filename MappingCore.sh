#!/bin/bash

PID=$1 
while true; 
do 
    cat /proc/4702/task/*/stat | awk '{ print $3 }' >> MappingCore.log ; 
done 
