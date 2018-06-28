#!/bin/bash



OUTPUT_FOLDER=~/Result/
PARSEC3_BENCHMARK_FOLDER=/home/odroid/Workloads-ARMv7/parsec-armv7/parsec-3.0/pkgs/

THREAD_FACTOR="1.0" # 2.0 4.0

CPU_LIST=("0" "0-1" "0-2" "0-3" "4" "4-5" "4-6" "4-7" "0,4" "0,4-5" "0,4-6" "0,4-7" "0-1,4" "0-1,4-5" "0-1,4-6" "0-1,4-7" "0-2,4" "0-2,4-5" "0-2,4-6" "0-2,4-7" "0-3,4" "0-3,4-5" "0-3,4-6" "0-3,4-7")

NUM_THREADS=("1" "2" "3" "4" "1" "2" "3" "4" "2" "3" "4" "5" "3" "4" "5" "6" "4" "5" "6" "7" "5" "6" "7" "8")

APP_PARSEC3=("apps/blackscholes/inst/arm-linux.gcc/bin" "apps/bodytrack/inst/arm-linux.gcc/bin" "apps/ferret/inst/arm-linux.gcc/bin" "apps/fluidanimate/inst/arm-linux.gcc/bin" "apps/freqmine/inst/arm-linux.gcc/bin" "apps/swaptions/inst/arm-linux.gcc/bin" "kernels/canneal/inst/arm-linux.gcc/bin" "kernels/dedup/inst/arm-linux.gcc/bin" "kernels/streamcluster/inst/arm-linux.gcc/bin")


APP_PARSEC3_NAMES=("blackscholes" "bodytrack" "ferret" "fluidanimate" "freqmine" "swaptions" "canneal" "dedup" "streamcluster")

FLAG_PARSEC3="True"



if [ $FLAG_PARSEC3 == 'True' ]; then
	 	     
     cd $PARSEC3_BENCHMARK_FOLDER   #Path to all benchmarks
     for ((j = 0; j < ${#APP_PARSEC3[@]}; j++)); do
          cd  ${APP_PARSEC3[$j]} #Path specific benchmark

          # start power monitor
          #sudo ~/wattsup/wattsup -t ttyUSB0 watts > /tmp/power.out & pid_power=$!

          # start perf monitor (needs sudo)
          sudo perf stat -a --per-core -o /tmp/perf.out -I 1000 & pid_perf=$!
         
          case $j in
		0) ./blackscholes 8 in_4K.txt /tmp/temp.out & pid_app=$!;;

		1) ./bodytrack sequenceB_1/ 4 1 1000 3 0 8 & pid_app=$!;;

		2) ./ferret corel lsh queries 10 20 8 output.txt & pid_app=$!;;

		3) ./fluidanimate 8 5 in_35K.fluid out.fluid & pid_app=$!;;

		4) ./freqmine kosarak_250k.dat 220 & pid_app=$!;;

		5) ./swaptions -ns 16 -sm 6000 -nt 8 & pid_app=$!;;

                6) ./canneal 8 10000 2000 10000.nets 32 & pid_app=$!;;

                7) ./dedup -c -p -v -t 8 -i media.dat -o output.dat.ddp & pid_app=$!;;

                8) ./streamcluster 10 20 32 4096 4096 1000 none output.txt 8 & pid_app=$!;;
		
		*) echo "INVALID NUMBER!" ;;
	   esac 

           sleep 1;
           taskset -a -cp 0-3,4-7 $pid_app
           wait $pid_app

           mv /tmp/perf.out /tmp/perf_${APP_PARSEC3_NAMES[$j]}.txt
           cd ../../../../../
               
           kill $pid_perf
           #kill $pid_power 
           sleep 20
     done
fi


