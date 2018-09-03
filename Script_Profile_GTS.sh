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


FLAG_PARSEC3="False"
##################################                 SPLASH-3              #############################################

SPLASH3_BENCHMARK_FOLDER=~/diego/benchmarks/Splash-3-master/codes/
APP_SPLASH3=("apps/radiosity")
APP_SPLASH3_NAMES=("radiosity")
FLAG_SPLASH3="True"



if [ $FLAG_SPLASH3 == 'True' ]; then
	for it in `echo $ITERACOES`
        do  
          cd ~
          if [ -d "tmp" ];then     
             mkdir /tmp
          else
             rm /tmp/*.out; rm /tmp/*.perf; rm /tmp/*.txt 
          fi 

	  for ((i = 0; i < ${#CPU_LIST[@]}; i++));
          do             
             cd $SPLASH3_BENCHMARK_FOLDER   #Path to all benchmarks
             for ((j = 0; j < ${#APP_SPLASH3[@]}; j++)); do
	          cd  ${APP_SPLASH3[$j]} #Path specific benchmark 
                 
                  case $j in

			0) printf "\n-- Running ${APP_SPLASH3_NAMES[$j]} -- Config:${CPU_LIST[$i]}\n\n"; taskset -a -c ${CPU_LIST[$i]} $PERF_CMD1 ${CPU_LIST[$i]} $PERF_CMD2 ./RADIOSITY -p ${NUM_THREADS[$i]} -room -batch & pid_app=$!;;

	
			*) echo "INVALID NUMBER!" ;;
		  esac 
            

            
	       ./Status.sh $pid_app & pid_status=$!
    	       ./MappingCore.sh $pid_app & pid_mapping=$!

            wait $pid_app

            kill -9 $pid_status
            kill -9 $pid_mapping


                 
            if [ -f "/tmp/perf.out" ]
		  then
		      mv /tmp/perf.out /tmp/"${APP_SPLASH3_NAMES[$j]}.${CPU_LIST[$i]}.perf"
		  else
		      printf "\n !!! Perf didnt create perf.out to ${APP_SPLASH3_NAMES[$j]} !!! \n"
                  fi
 
                  cd ../../
                                 
             done		                        
          done         
        done
fi

rm *.perf






