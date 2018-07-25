#!/bin/bash

cd ~

if [ -d "tmp" ];then     
   mkdir /tmp
else
   rm /tmp/*.out; rm /tmp/*.txt
fi 


TIME_COMMAND="/usr/bin/time -p -o /tmp/time.out"

THREAD_FACTOR="1.0" # 2.0 4.0

CPU_LIST=("0" "0-1" "0-2" "0-3" "4" "4-5" "4-6" "4-7" "0,4" "0,4-5" "0,4-6" "0,4-7" "0-1,4" "0-1,4-5" "0-1,4-6" "0-1,4-7" "0-2,4" "0-2,4-5" "0-2,4-6" "0-2,4-7" "0-3,4" "0-3,4-5" "0-3,4-6" "0-3,4-7")

NUM_THREADS=("1" "2" "3" "4" "1" "2" "3" "4" "2" "3" "4" "5" "3" "4" "5" "6" "4" "5" "6" "7" "5" "6" "7" "8")


#PARSEC 

PARSEC3_BENCHMARK_FOLDER=/home/odroid/Workloads-ARMv7/parsec-armv7/parsec-3.0/pkgs/
APP_PARSEC3=("apps/fluidanimate/inst/arm-linux.gcc/bin")
APP_PARSEC3_NAMES=("fluidanimate")
FLAG_PARSEC3="True"


if [ $FLAG_PARSEC3 == 'True' ]; then
	for tf in `echo $THREAD_FACTOR`
        do  
	  for ((i = 0; i < ${#CPU_LIST[@]}; i++));
          do             
             cd $PARSEC3_BENCHMARK_FOLDER   #Path to all benchmarks
             for ((j = 0; j < ${#APP_PARSEC3[@]}; j++)); do
	          cd  ${APP_PARSEC3[$j]} #Path specific benchmark
                  

                  #all simlarge input:
                  case $j in
			0) printf "\n-- Running fluidanimate--\n\n"; $TIME_COMMAND ./fluidanimate $NUM_THREADS 500 ../../../inputs/in_500K.fluid out.fluid & pid_app=$!;;
	
			*) echo "INVALID NUMBER!" ;;
		  esac 

                  sleep 1;
          	  taskset -a -cp ${CPU_LIST[$i]} $pid_app
	          perf stat -o /tmp/perf.out -e instructions,cycles,cache-misses,cache-references,branches,branch-misses -p $pid_app & pid_perf=$!  #desempenho sumarizado!


           	  wait $pid_app
                  kill $pid_perf
                  
                  sleep 2
                  kill -9 $pid_perf 1> /dev/null 2>/dev/null 
                  
            
                  if [ -f "/tmp/perf.out" ]
		  then
		      mv /tmp/perf.out /tmp/"perf_${APP_PARSEC3_NAMES[$j]}.${CPU_LIST[$i]}.txt"
		  else
		      printf "\n !!! Perf didnt create perf.out to ${APP_PARSEC3_NAMES[$j]}.${CPU_LIST[$i]} !!! \n"
                  fi
                  
                  if [ -f "/tmp/time.out" ]
		  then
		      mv /tmp/time.out /tmp/"time_${APP_PARSEC3_NAMES[$j]}.${CPU_LIST[$i]}.txt"
		  else
		      printf "\n !!! Perf didnt create time.out to ${APP_PARSEC3_NAMES[$j]}.${CPU_LIST[$i]} !!! \n"
                  fi                  
             done		                        
          done
        done
fi


