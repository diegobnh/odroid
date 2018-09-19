#!/bin/bash


CPU_LIST=("0-3,4-7" "0-1,4-5" "4-7" "0-3")
NUM_THREADS=("8" "4" "4" "4") 
APP_BOTS=("nqueens" "uts" "knapsack" "health" "floorplan" "alignment" "fft" "fib" "sort" "sparselu" "strassen")



for ((i = 0; i < ${#CPU_LIST[@]}; i++));
do 
  rm Power2.log Stat.log Mapping.log
  for ((j = 0; j < ${#APP_BOTS[@]}; j++)); 
  do 
     case $j in
			0) printf "\n-- Running ${APP_BOTS[$j]} -- Config:${CPU_LIST[$i]}\n\n"; 
                           sudo taskset -a -c ${CPU_LIST[$i]} /home/odroid/bots/run/./run-nqueens.sh -c ${NUM_THREADS[$i]}  & pid_app=$! ;;
					 

			1) printf "\n-- Running ${APP_BOTS[$j]} -- Config:${CPU_LIST[$i]}\n\n"; 
                           sudo taskset -a -c ${CPU_LIST[$i]} /home/odroid/bots/run/./run-uts.sh -c ${NUM_THREADS[$i]} -i small.input & pid_app=$!  ;;

			2) printf "\n-- Running ${APP_BOTS[$j]} -- Config:${CPU_LIST[$i]}\n\n"; 
                           sudo taskset -a -c ${CPU_LIST[$i]} /home/odroid/bots/run/./run-knapsack.sh -c ${NUM_THREADS[$i]} -i knapsack-040.input & pid_app=$! ;;

			3) printf "\n-- Running ${APP_BOTS[$j]} -- Config:${CPU_LIST[$i]}\n\n"; 
                           sudo taskset -a -c ${CPU_LIST[$i]} /home/odroid/bots/run/./run-health.sh -c ${NUM_THREADS[$i]} -i medium.input & pid_app=$! ;;

			4) printf "\n-- Running ${APP_BOTS[$j]} -- Config:${CPU_LIST[$i]}\n\n"; 
                           sudo taskset -a -c ${CPU_LIST[$i]} /home/odroid/bots/run/./run-floorplan.sh -c ${NUM_THREADS[$i]} -i input.15 & pid_app=$! ;;

			5) printf "\n-- Running ${APP_BOTS[$j]} -- Config:${CPU_LIST[$i]}\n\n"; 
                           sudo taskset -a -c ${CPU_LIST[$i]} /home/odroid/bots/run/./run-alignment.sh -c ${NUM_THREADS[$i]} -i prot.100.aa & pid_app=$! ;;

			6) printf "\n-- Running ${APP_BOTS[$j]} -- Config:${CPU_LIST[$i]}\n\n"; 
                           sudo taskset -a -c ${CPU_LIST[$i]} /home/odroid/bots/run/./run-fft.sh -c ${NUM_THREADS[$i]} & pid_app=$! ;;

			7) printf "\n-- Running ${APP_BOTS[$j]} -- Config:${CPU_LIST[$i]}\n\n"; 
                           sudo taskset -a -c ${CPU_LIST[$i]} /home/odroid/bots/run/./run-fib.sh -c ${NUM_THREADS[$i]} & pid_app=$! ;;

			8) printf "\n-- Running ${APP_BOTS[$j]} -- Config:${CPU_LIST[$i]}\n\n"; 
                           sudo taskset -a -c ${CPU_LIST[$i]} /home/odroid/bots/run/./run-sort.sh -c ${NUM_THREADS[$i]} & pid_app=$! ;;

			9) printf "\n-- Running ${APP_BOTS[$j]} -- Config:${CPU_LIST[$i]}\n\n"; 
                           sudo taskset -a -c ${CPU_LIST[$i]} /home/odroid/bots/run/./run-sparselu.sh -c ${NUM_THREADS[$i]} & pid_app=$! ;;

			10)printf "\n-- Running ${APP_BOTS[$j]} -- Config:${CPU_LIST[$i]}\n\n"; 
                           sudo taskset -a -c ${CPU_LIST[$i]} /home/odroid/bots/run/./run-strassen.sh -c ${NUM_THREADS[$i]} & pid_app=$! ;;
	
			*) echo "INVALID NUMBER!" ;;
      esac 

      grabserial -T -d /dev/ttyUSB0  >> "Power_"${APP_BOTS[$j]}"_"${CPU_LIST[$i]}".log" & 
      PidPower=`pgrep -f grabserial` ;;
      
      wait $pid_app
      echo "Killing Power"
	 sudo kill -9 $PidPower
	 sleep 3
      if [ -d ${APP_BOTS[$i]} ];then     
         mkdir ${APP_BOTS[$i]}        
      fi 
    
      mv *.log ${APP_BOTS[$i]}/

  done #Fim do for que controla a execução de cada aplicação
done #Fim do for que ocntrole os diferentes configs para executar


