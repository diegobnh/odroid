#!/bin/bash

sudo ./CPU_governor_performance.sh

#CPU_LIST=("0-3,4-7" "0-1,4-5" "4-7" "0-3")
CPU_LIST=("0-3,4-7")
#NUM_THREADS=("8" "4" "4" "4")
NUM_THREADS=("8")
#ITERACOES="1 2 3 4 5"
ITERACOES="1"
APP_BOTS=("nqueens" "uts" "knapsack" "health" "floorplan" "alignment" "fft" "fib" "sort" "sparselu" "strassen")


#Essa primeira parte vai criar pastas e subpastas para armzenar as saidas , já que elas posuem os mesmos nomes.

for ((j = 0; j < ${#CPU_LIST[@]}; j++));
do
  if [ -d ${CPU_LIST[$j]} ];then           
      cd ${CPU_LIST[$j]}
      for it in `echo $ITERACOES`
      do
        cd $it
        files=$(ls 2> /dev/null | wc -l)
        if [ "$files" != "0" ]; then
             rm *.*              
        fi
        cd ..
      done
      cd ..
  else
      mkdir ${CPU_LIST[$j]}
      echo "Criando o Folder "${CPU_LIST[$j]}
      cd ${CPU_LIST[$j]}
      for it in `echo $ITERACOES`
      do
        mkdir $it
      done
      cd ..
  fi
done


#Essa segunda etapa executa as aplcaçoes do Bots de modo que o número de threads seja igual ao número de cores disponibilizados.

for it in `echo $ITERACOES`
do
     echo "Iteracao "$it
	for ((i = 0; i < ${#CPU_LIST[@]}; i++));
	do 
	  for ((j = 0; j < ${#APP_BOTS[@]}; j++)); 
	  do 
		case $j in
				0) printf "\n-- Running ${APP_BOTS[$j]} -- Config:${CPU_LIST[$i]}\n\n";
		                      sudo taskset -a -c ${CPU_LIST[$i]} /home/odroid/bots/run/./run-nqueens.sh -c ${NUM_THREADS[$i]}  & pid_app=$!;;

				1) printf "\n-- Running ${APP_BOTS[$j]} -- Config:${CPU_LIST[$i]}\n\n";
		                      sudo taskset -a -c ${CPU_LIST[$i]} /home/odroid/bots/run/./run-uts.sh -c ${NUM_THREADS[$i]} -i small.input & pid_app=$!;;

				2) printf "\n-- Running ${APP_BOTS[$j]} -- Config:${CPU_LIST[$i]}\n\n";
		                      sudo taskset -a -c ${CPU_LIST[$i]} /home/odroid/bots/run/./run-knapsack.sh -c ${NUM_THREADS[$i]} -i knapsack-040.input & pid_app=$!;;

				3) printf "\n-- Running ${APP_BOTS[$j]} -- Config:${CPU_LIST[$i]}\n\n";
		                      sudo taskset -a -c ${CPU_LIST[$i]} /home/odroid/bots/run/./run-health.sh -c ${NUM_THREADS[$i]} -i medium.input & pid_app=$!;;

				4) printf "\n-- Running ${APP_BOTS[$j]} -- Config:${CPU_LIST[$i]}\n\n";
		                      sudo taskset -a -c ${CPU_LIST[$i]} /home/odroid/bots/run/./run-floorplan.sh -c ${NUM_THREADS[$i]} -i input.15 & pid_app=$!;;

				5) printf "\n-- Running ${APP_BOTS[$j]} -- Config:${CPU_LIST[$i]}\n\n";
		                      sudo taskset -a -c ${CPU_LIST[$i]} /home/odroid/bots/run/./run-alignment.sh -c ${NUM_THREADS[$i]} -i prot.100.aa & pid_app=$!;;

				6) printf "\n-- Running ${APP_BOTS[$j]} -- Config:${CPU_LIST[$i]}\n\n";
		                      sudo taskset -a -c ${CPU_LIST[$i]} /home/odroid/bots/run/./run-fft.sh -c ${NUM_THREADS[$i]} & pid_app=$!;;

				7) printf "\n-- Running ${APP_BOTS[$j]} -- Config:${CPU_LIST[$i]}\n\n";
		                      sudo taskset -a -c ${CPU_LIST[$i]} /home/odroid/bots/run/./run-fib.sh -c ${NUM_THREADS[$i]} & pid_app=$!;;

				8) printf "\n-- Running ${APP_BOTS[$j]} -- Config:${CPU_LIST[$i]}\n\n";
		                      sudo taskset -a -c ${CPU_LIST[$i]} /home/odroid/bots/run/./run-sort.sh -c ${NUM_THREADS[$i]} & pid_app=$!;;

				9) printf "\n-- Running ${APP_BOTS[$j]} -- Config:${CPU_LIST[$i]}\n\n";
		                      sudo taskset -a -c ${CPU_LIST[$i]} /home/odroid/bots/run/./run-sparselu.sh -c ${NUM_THREADS[$i]} & pid_app=$!;;

				10)printf "\n-- Running ${APP_BOTS[$j]} -- Config:${CPU_LIST[$i]}\n\n";
		                      sudo taskset -a -c ${CPU_LIST[$i]} /home/odroid/bots/run/./run-strassen.sh -c ${NUM_THREADS[$i]} & pid_app=$!;;
	
				*) echo "INVALID NUMBER!";;
		 esac 

		 grabserial -T -d /dev/ttyUSB0  >> "Power_"${APP_BOTS[$j]}"_"${CPU_LIST[$i]}".log" & 
		 PidPower=`pgrep -f grabserial` 
		 
		 wait $pid_app
		 echo " "
		 echo "Killing Power"
		 sudo kill -9 $PidPower
		 #sudo pkill grabserial
		 sleep 3

	    
		 mv *.log ${APP_BOTS[$j]}

	  done #Fim do for que controla a execução de cada aplicação
	done #Fim do for que ocntrole os diferentes configs para executar
done

