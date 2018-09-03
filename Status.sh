#!/bin/bash

PID=$1 
while true; 
do 
    ps -mo psr -p $PID | grep -Eo '[0-9]' >> Status.log ; 
done 
