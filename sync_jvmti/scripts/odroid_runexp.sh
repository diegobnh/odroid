#!/bin/bash
#set -e
TIME_BETWEEN_RUNS=3s
TASKSET_CONFIG=(
    "0-3,4-7" # 4b4L
    "4-7"     # 4b0L
    "0-3"     # 0b4L
)

echo "Cleaning old experiments..."
#rm sync_jvmti.* &>/dev/null
#rm exp_*.csp &>/dev/null
#rm log.txt &>/dev/null

# Log everything that happens on stdout/stderr to a logfile.
#echo $@ >log.txt
echo $@ >>log.txt
exec > >(tee -ai log.txt)
exec 2>&1

# Warm up once
cmd="time $@"
echo "Running warm-up..."
echo $cmd
$cmd

for config in "${TASKSET_CONFIG[@]}"; do
    rm sync_jvmti.*
    sleep $TIME_BETWEEN_RUNS
    cmd="taskset -c $config time $@"
    echo $cmd
    $cmd
    mv sync_jvmti.* "exp_c${config}_t8_n1.csp"

    #rm sync_jvmti.*
    #sleep $TIME_BETWEEN_RUNS
    #cmd="taskset -c $config time $@ -n 5"
    #echo $cmd
    #$cmd
    #mv sync_jvmti.* "exp_c${config}_t8_n5.csp"
done
