#!/bin/bash

while true; 
do 
    cat /sys/devices/system/cpu/cpu*/cpufreq/cpuinfo_cur_freq >> Freq.log
    echo "--------" >> Freq.log
done

