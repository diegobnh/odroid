#!/bin/bash

PID=$1 
while true; 
do
    if [ -d "/proc/$PID/task/" ]; then
       result=$(cat /proc/$PID/task/*/stat | awk '{ print $1 " " $3 }')
       time=$(date +"%H:%M:%S:%N")
       if [[ $? != 1 ]]; then
           echo -n $time " " $result " " >> Stat.log ;
           echo -n $(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq) >> Stat.log ;
           echo -n " " >> Stat.log
           echo -n $(cat /sys/devices/system/cpu/cpu1/cpufreq/cpuinfo_cur_freq) >> Stat.log ;
           echo -n " " >> Stat.log
           echo -n $(cat /sys/devices/system/cpu/cpu2/cpufreq/cpuinfo_cur_freq) >> Stat.log ;
           echo -n " " >> Stat.log
           echo -n $(cat /sys/devices/system/cpu/cpu3/cpufreq/cpuinfo_cur_freq) >> Stat.log ;
           echo -n " " >> Stat.log
           echo -n $(cat /sys/devices/system/cpu/cpu4/cpufreq/cpuinfo_cur_freq) >> Stat.log ;
           echo -n " " >> Stat.log
           echo -n $(cat /sys/devices/system/cpu/cpu5/cpufreq/cpuinfo_cur_freq) >> Stat.log ;
           echo -n " " >> Stat.log
           echo -n $(cat /sys/devices/system/cpu/cpu6/cpufreq/cpuinfo_cur_freq) >> Stat.log ;           
           echo -n " " >> Stat.log
           echo $(cat /sys/devices/system/cpu/cpu7/cpufreq/cpuinfo_cur_freq) >>  Stat.log ;
       fi
    else
       break ;
    fi
    sleep 0.14
done 
