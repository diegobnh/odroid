#!/bin/bash

cd ~

if [ -d "tmp" ];then     
   mkdir /tmp
else
   rm /tmp/*.out; rm /tmp/*.txt
fi 


PERF_COMMAND="perf stat -o /tmp/perf.out -I 200 -e cycles,instructions,cache-misses,LLC-load-misses"
RODINIA_BENCHMARK_FOLDER=/home/diego/Downloads/rodinia_3.1/openmp


THREAD_FACTOR="1.0" # 2.0 4.0

CPU_LIST=("0" "0-1" "0-2" "0-3" "4" "4-5" "4-6" "4-7" "0,4" "0,4-5" "0,4-6" "0,4-7" "0-1,4" "0-1,4-5" "0-1,4-6" "0-1,4-7" "0-2,4" "0-2,4-5" "0-2,4-6" "0-2,4-7" "0-3,4" "0-3,4-5" "0-3,4-6" "0-3,4-7")

NUM_THREADS=("1" "2" "3" "4" "1" "2" "3" "4" "2" "3" "4" "5" "3" "4" "5" "6" "4" "5" "6" "7" "5" "6" "7" "8")


#PARSEC 

PARSEC3_BENCHMARK_FOLDER=/home/odroid/Workloads-ARMv7/parsec-armv7/parsec-3.0/pkgs/

APP_PARSEC3=("apps/fluidanimate/inst/arm-linux.gcc/bin")

APP_PARSEC3_NAMES=("fluidanimate")

FLAG_PARSEC3="True"


#SPLASH-3 

SPLASH3_BENCHMARK_FOLDER=~/diego/benchmarks/Splash-3-master/codes/
#SPLASH3_BENCHMARK_FOLDER=/home/diego/Downloads/Salvador-Vinicius/Benchmarks/Splash-3-master/codes


APP_SPLASH3=("apps/ocean" "apps/radiosity" "apps/raytrace" "apps/volrend" "kernels/lu" "kernels/lu" "kernels/radix")

APP_SPLASH3_NAMES=("ocean contiguous" "radiosity" "raytrace" "volrend" "lu contiguous" "lu nocontiguous" "radix")

FLAG_SPLASH3="False"


if [ $FLAG_SPLASH3 == 'True' ]; then
	for tf in `echo $THREAD_FACTOR`
        do  
	  for ((i = 0; i < ${#CPU_LIST[@]}; i++));
          do             
             cd $SPLASH3_BENCHMARK_FOLDER   #Path to all benchmarks
             for ((j = 0; j < ${#APP_SPLASH3[@]}; j++)); do
	          cd  ${APP_SPLASH3[$j]} #Path specific benchmark
 
                  # start power monitor
                  #sudo ./wattsup/wattsup -t ttyUSB0 watts > /tmp/power.out & pid_power=$!

                  #all simlarge input:
                  case $j in
			0) printf "\n-- Running ${APP_SPLASH3_NAMES[$j]}--\n\n"; 
                           if [[ "${NUM_THREADS[$i]}" == "1" || "${NUM_THREADS[$i]}" == "2" || "${NUM_THREADS[$i]}" == "4" || "${NUM_THREADS[$i]}" == "8" ]]
                           then $PERF_COMMAND ./contiguous_partitions/OCEAN -p ${NUM_THREADS[$i]} -n 2050 & pid_app=$!
                           fi ;;

			1) printf "\n-- Running ${APP_SPLASH3_NAMES[$j]}--\n\n"; $PERF_COMMAND ./RADIOSITY -p ${NUM_THREADS[$i]} -room -batch & pid_app=$!;;

			2) printf "\n-- Running ${APP_SPLASH3_NAMES[$j]}--\n\n"; $PERF_COMMAND ./RAYTRACE -p${NUM_THREADS[$i]} -a1600 -m100 inputs/car.env & pid_app=$!;;

			3) printf "\n-- Running ${APP_SPLASH3_NAMES[$j]}--\n\n"; $PERF_COMMAND ./VOLREND ${NUM_THREADS[$i]} inputs/head 512 & pid_app=$!;;		

			4) printf "\n-- Running ${APP_SPLASH3_NAMES[$j]}--\n\n"; $PERF_COMMAND ./contiguous_blocks/LU -n4096 -p${NUM_THREADS[$i]} -b512 & pid_app=$!;;

			5) printf "\n-- Running ${APP_SPLASH3_NAMES[$j]}--\n\n"; $PERF_COMMAND ./non_contiguous_blocks/LU -n4096 -p${NUM_THREADS[$i]} -b512 & pid_app=$!;;

			6) printf "\n-- Running ${APP_SPLASH3_NAMES[$j]}--\n\n"; 
                           if [[ "${NUM_THREADS[$i]}" == "1" || "${NUM_THREADS[$i]}" == "2" || "${NUM_THREADS[$i]}" == "4" || "${NUM_THREADS[$i]}" == "8" ]]
                           then $PERF_COMMAND ./RADIX -p${NUM_THREADS[$i]} -n134217728 -r4096 & pid_app=$!
                           fi ;;

	
			*) echo "INVALID NUMBER!" ;;
		  esac 

                  sleep 1;
          	  taskset -a -cp ${CPU_LIST[$i]} $pid_app
	          #start perf monitor (needs sudo)
	          #perf stat --per-thread -o /tmp/perf.out -I 200 -p $pid_app & pid_perf=$!
                  #perf stat -o /tmp/perf.out -I 200 -e cycles,instructions,cache-misses,LLC-load-misses -p $pid_app & pid_perf=$!  #desempenho sumarizado!

           	  wait $pid_app

                  #kill $pid_perf
                  #kill $pid_power

                  sleep 2
                  #kill -9 $pid_perf 1> /dev/null 2>/dev/null 
            
                  if [ -f "/tmp/perf.out" ]
		  then
		      mv /tmp/perf.out /tmp/"perf_${APP_SPLASH3_NAMES[$j]}.${CPU_LIST[$i]}.txt"
		  else
		      printf "\n !!! Perf didnt create perf.out to ${APP_SPLASH3_NAMES[$j]} !!! \n"
                  fi
                  cd ../../../../../
               
                  sleep 15
             done		                        
          done
        done
fi


if [ $FLAG_PARSEC3 == 'True' ]; then
	for tf in `echo $THREAD_FACTOR`
        do  
	  for ((i = 0; i < ${#CPU_LIST[@]}; i++));
          do             
             cd $PARSEC3_BENCHMARK_FOLDER   #Path to all benchmarks
             for ((j = 0; j < ${#APP_PARSEC3[@]}; j++)); do
	          cd  ${APP_PARSEC3[$j]} #Path specific benchmark
 
                  # start power monitor
                  #sudo ./wattsup/wattsup -t ttyUSB0 watts > /tmp/power.out & pid_power=$!

                  #all simlarge input:
                  case $j in
			0) printf "\n-- Running fluidanimate--\n\n"; $PERF_COMMAND ./fluidanimate $NUM_THREADS 500 ../../../inputs/in_500K.fluid out.fluid & pid_app=$!;;
	
			*) echo "INVALID NUMBER!" ;;
		  esac 

                  sleep 1;
          	  taskset -a -cp ${CPU_LIST[$i]} $pid_app
	          #start perf monitor (needs sudo)
	          #perf stat --per-thread -o /tmp/perf.out -I 200 -p $pid_app & pid_perf=$!
                  #perf stat -o /tmp/perf.out -I 200 -p $pid_app & pid_perf=$!  #desempenho sumarizado!

           	  wait $pid_app

                  #kill $pid_perf
                  #kill $pid_power

                  sleep 2
                  #kill -9 $pid_perf 1> /dev/null 2>/dev/null 
            
                  if [ -f "/tmp/perf.out" ]
		  then
		      mv /tmp/perf.out /tmp/"perf_${APP_PARSEC3_NAMES[$j]}.txt"
		  else
		      printf "\n !!! Perf didnt create perf.out to ${APP_PARSEC3_NAMES[$j]} !!! \n"
                  fi
                  
                  #cd ../../
               
                  #sleep 15
             done		                        
          done
        done
fi


