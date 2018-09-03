#!/bin/bash

PERF_CMD1="perf stat -o /tmp/perf.out -I 1000 -a -C "
PERF_CMD2=" -e instructions,cycles,cache-misses,cache-references,branches,branch-misses"
#TIME_COMMAND="/usr/bin/time -p -o /tmp/time.out"
ITERACOES="1" # 2 3 4 5
THREAD_FACTOR="1.0" # 2.0 4.0
#CPU_LIST=("0-3,4-7" "0-2,4" "0-1,4-5" "0,4-6" "4-7" "0-3" "0,4" "0-1" "4-5")
CPU_LIST=("0-3,4-7")
#NUM_THREADS=("8" "4" "4" "4" "4" "4" "2" "2" "2") 
NUM_THREADS=("8")


rm *.log
cd /home/odroid/diego/benchmarks/bots/run
./run-nqueens.sh -c 8 & pid_app=$!

cd /home/odroid/diego/git/odroid/	
./Status.sh $pid_app & pid_status=$!
./Mapping.sh $pid_app & pid_mapping=$!

wait $pid_app

kill -9 $pid_status
kill -9 $pid_mapping


                 
           






