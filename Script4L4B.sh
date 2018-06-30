#!/bin/bash

#     $! contains the process ID of the most recently executed background pipeline


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
         
          case $j in
		1) ./blackscholes ${NUM_THREADS[$i]} in_64K.txt /tmp/temp.out & pid_app=$!;;

		2) ./bodytrack sequenceB_4/ 4 1 1000 3 0 ${NUM_THREADS[$i]} ;;

                3) ./facesim -timing -threads ${NUM_THREADS[$i]}

		4) ./ferret corel lsh queries 10 20 ${NUM_THREADS[$i]} output.txt ;;

		5) ./fluidanimate ${NUM_THREADS[$i]} 5 in_300K.fluid out.fluid ;;

		6) export OMP_NUM_THREADS=${NTHREADS}; ./freqmine kosarak_990k.dat 790 ;;

                7) ./raytrace rtview happy_buddha.obj -automove -nthreads ${NUM_THREADS[$i]} -frames 3 -res 1920 1080

		8) ./swaptions -ns 64 -sm 40000 -nt ${NUM_THREADS[$i]} ;;

		9) ./x264 --quiet --qp 20 --partitions b8x8,i4x4 --ref 5 --direct auto --b-pyramid --weightb --mixed-refs --no-fast-pskip --me umh --subme 7 --analyse b8x8,i4x4 --threads ${NUM_THREADS[$i]} -o eledream.264 eledream_640x360_128.y4m

		10) export IM_CONCURRENCY=${NTHREADS}; ./vips im_benchmark bigben_2662x5500.v output.v

                11) ./canneal ${NUM_THREADS[$i]} 15000 2000 400000.nets 32 ;;

                12) ./dedup -c -p -v -t ${NUM_THREADS[$i]} -i media.dat -o output.dat.ddp

                13) ./streamcluster 10 20 128 16384 16384 1000 none output.txt ${NUM_THREADS[$i]}
		
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
            
           mv /tmp/perf.out /tmp/perf_${APP_PARSEC3_NAMES[$j]}.txt
           cd ../../../../../
               
           sleep 15
     done
fi


