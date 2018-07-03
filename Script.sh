#!/bin/bash

#     $! contains the process ID of the most recently executed background pipeline


OUTPUT_FOLDER=~/Result/
PARSEC3_BENCHMARK_FOLDER=/home/odroid/Workloads-ARMv7/parsec-armv7/parsec-3.0/pkgs/

THREAD_FACTOR="1.0" # 2.0 4.0

CPU_LIST=("0" "0-1" "0-2" "0-3" "4" "4-5" "4-6" "4-7" "0,4" "0,4-5" "0,4-6" "0,4-7" "0-1,4" "0-1,4-5" "0-1,4-6" "0-1,4-7" "0-2,4" "0-2,4-5" "0-2,4-6" "0-2,4-7" "0-3,4" "0-3,4-5" "0-3,4-6" "0-3,4-7")

NUM_THREADS=("1" "2" "3" "4" "1" "2" "3" "4" "2" "3" "4" "5" "3" "4" "5" "6" "4" "5" "6" "7" "5" "6" "7" "8")

APP_PARSEC3=("apps/blackscholes/inst/arm-linux.gcc/bin" "apps/bodytrack/inst/arm-linux.gcc/bin" "apps/facesim/inst/arm-linux.gcc/bin" "apps/ferret/inst/arm-linux.gcc/bin" "apps/fluidanimate/inst/arm-linux.gcc/bin" "apps/swaptions/inst/arm-linux.gcc/bin"    "kernels/dedup/inst/arm-linux.gcc/bin" "kernels/streamcluster/inst/arm-linux.gcc/bin")


APP_PARSEC3_NAMES=("blackscholes" "bodytrack" "facesim" "ferret" "fluidanimate" "swaptions" "dedup" "streamcluster")

FLAG_PARSEC3="True"

NUM_THREADS=8


if [ $FLAG_PARSEC3 == 'True' ]; then
	 	     
     cd $PARSEC3_BENCHMARK_FOLDER   #Path to all benchmarks
     for ((j = 0; j < ${#APP_PARSEC3[@]}; j++)); do
          cd  ${APP_PARSEC3[$j]} #The case follows the order of the string APP_PARSEC3

          # start power monitor
          #sudo ~/wattsup/wattsup -t ttyUSB0 watts > /tmp/power.out & pid_power=$!
          echo $j
          case $j in
		0) printf "\n-- Running blackscholes--\n\n"; ./blackscholes $NUM_THREADS in_64K.txt /tmp/temp.out & pid_app=$!;;

		1) printf "\n-- Running bodytrack--\n\n"; ./bodytrack sequenceB_4/ 4 1 1000 3 0 $NUM_THREADS & pid_app=$!;;

                2) printf "\n-- Running facesim--\n\n"; ./facesim -timing -threads $NUM_THREADS & pid_app=$!;;

		3) printf "\n-- Running ferret--\n\n"; ./ferret corel lsh queries 10 20 $NUM_THREADS output.txt & pid_app=$!;;

		4) printf "\n-- Running fluidanimate--\n\n"; ./fluidanimate $NUM_THREADS 5 ../../../inputs/in_300K.fluid out.fluid & pid_app=$!;;

		5) printf "\n-- Running swaptions--\n\n"; ./swaptions -ns 64 -sm 40000 -nt $NUM_THREADS & pid_app=$!;;
                
                6) printf "\n-- Running dedup--\n\n"; ./dedup -c -p -v -t $NUM_THREADS -i media.dat -o output.dat.ddp & pid_app=$!;;
                7) printf "\n-- Running streamcluster--\n\n"; ./streamcluster 10 20 128 16384 16384 1000 none output.txt $NUM_THREADS & pid_app=$!;;
		
		*) echo "INVALID NUMBER!" ;;
	   esac 

           sleep 1;
           taskset -a -cp 0-3,4-7 $pid_app
           #start perf monitor (needs sudo)
	   #perf stat --per-thread -o /tmp/perf.out -I 200 -p $pid_app & pid_perf=$!
           perf stat -o /tmp/perf.out -I 200 -p $pid_app & pid_perf=$!  #desempenho sumarizado!

           wait $pid_app

           kill $pid_perf
           #kill $pid_power

           sleep 2
           kill -9 $pid_perf 1> /dev/null 2>/dev/null 
            
           
           if [ -f "/tmp/perf.out" ]
           then
	       mv /tmp/perf.out /tmp/"perf_${APP_PARSEC_NAMES[$j]}.txt"
           else
	       printf "\n!!!Perf didnt create perf.out to ${APP_PARSEC_NAMES[$j]} !!!\n"


           cd ../../../../../
               
           sleep 15
     done
fi


