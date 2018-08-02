#!/bin/bash


#PERF_COMMAND="perf stat -a -o /tmp/perf.out -I 1000 -e instructions,cycles,cache-misses,cache-references,branches,branch-misses"
TIME_COMMAND="/usr/bin/time -p -o /tmp/time.out"

ITERACOES="1 2 3 4 5"
#CPU_LIST=("0-3,4-7" "0-2,4" "0-1,4-5" "0,4-6" "4-7" "0-3" "0,4" "0-1" "4-5" "0" "4")
CPU_LIST=("0-3,4-7" "4-7")
#NUM_THREADS=("8" "4" "4" "4" "4" "4" "2" "2" "2" "1" "1") 
NUM_THREADS=("8" "4")

#PARSEC 

PARSEC3_BENCHMARK_FOLDER=/home/odroid/Workloads-ARMv7/parsec-armv7/parsec-3.0/pkgs/
APP_PARSEC3=("apps/fluidanimate/inst/arm-linux.gcc/bin")
APP_PARSEC3_NAMES=("fluidanimate")
FLAG_PARSEC3="True"


if [ $FLAG_PARSEC3 == 'True' ]; then
	for it in `echo $ITERACOES`
        do  
          cd ~   
          if [ -d "tmp" ];then     
          mkdir /tmp
          else
          rm /tmp/*.out; rm /tmp/*.perf; rm /tmp/*.time; rm /tmp/*.txt 
          fi 

	  for ((i = 0; i < ${#CPU_LIST[@]}; i++));
          do             
             cd $PARSEC3_BENCHMARK_FOLDER   #Path to all benchmarks
             for ((j = 0; j < ${#APP_PARSEC3[@]}; j++)); do
	          cd  ${APP_PARSEC3[$j]} #Path specific benchmark
                  

                  #all simlarge input:
                  case $j in
			0) printf "\n-- Running fluidanimate-- Config:${CPU_LIST[$i]}\n\n"; 
                           if [[ "${NUM_THREADS[$i]}" == "1" || "${NUM_THREADS[$i]}" == "2" || "${NUM_THREADS[$i]}" == "4" || "${NUM_THREADS[$i]}" == "8" ]]
                           then $TIME_COMMAND taskset -a -c ${CPU_LIST[$i]} perf stat -o /tmp/perf.out -a -C ${CPU_LIST[$i]} -e instructions,cycles,cache-misses,cache-references,branches,branch-misses ./fluidanimate ${NUM_THREADS[$i]} 50 ../../../inputs/in_500K.fluid out.fluid 
                           fi ;;

	
			*) echo "INVALID NUMBER!" ;;
		  esac 

                  #sleep 1;
          	  #taskset -a -cp ${CPU_LIST[$i]} $pid_app
	          #perf stat -o /tmp/perf.out -e instructions,cycles,cache-misses,cache-references,branches,branch-misses -p $pid_app & pid_perf=$!  #desempenho sumarizado!


           	  #wait $pid_app
                  #kill $pid_perf
                  
                  #sleep 2
                  #kill -9 $pid_perf 1> /dev/null 2>/dev/null 
                  
            
                  if [ -f "/tmp/perf.out" ]
		  then
		      mv /tmp/perf.out /tmp/"${CPU_LIST[$i]}.perf"
		  else
		      printf "\n !!! Perf didnt create perf.out to ${APP_PARSEC3_NAMES[$j]}.${CPU_LIST[$i]} !!! \n"
                  fi
                  
                  if [ -f "/tmp/time.out" ]
		  then
		      mv /tmp/time.out /tmp/"${CPU_LIST[$i]}.time"
		  else
		      printf "\n !!! Perf didnt create time.out to ${APP_PARSEC3_NAMES[$j]}.${CPU_LIST[$i]} !!! \n"
                  fi                  
             done		                        
          done

          cd /tmp/          
          tar -cf $it".tar" *.perf *.time
          mv $it".tar" ~/diego/git_folder

        done
fi


