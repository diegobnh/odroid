#!/bin/bash


CPU_LIST=("0-3,4-7" "0-1,4-5" "4-7" "0-3")
NUM_THREADS=("8" "4" "4" "4") 
#APP_BOTS=("uts" "knapsack" "health" "floorplan" "alignment" "fft" "fib" "sort" "sparselu" "strassen")
APP_BOTS=("nqueens")



for ((i = 0; i < ${#CPU_LIST[@]}; i++));
do 
  rm Power2.log Stat.log Mapping.log
  for ((j = 0; j < ${#APP_BOTS[@]}; j++)); 
  do 
     case $j in
			0) printf "\n-- Running ./run-nqueens.sh -- Config:${CPU_LIST[$i]}\n\n"; 
                           sudo taskset -a -c ${CPU_LIST[$i]} /home/odroid/bots/run/./run-nqueens.sh -c ${NUM_THREADS[$i]}  & pid_app=$!
                           sudo ./Status.sh $pid_app &
					  sudo ./Mapping.sh $pid_app &
					  grabserial -T -d /dev/ttyUSB0  >> Power2.log & 
                           PidPower=`pgrep -f grabserial` ;;

#			1) printf "\n-- Running bodytrack--\n\n"; ./bodytrack sequenceB_4/ 4 1 1000 3 0 ${NUM_THREADS[$i]} & pid_app=$!;;

#			2) printf "\n-- Running facesim--\n\n"; ./facesim -timing -threads ${NUM_THREADS[$i]} & pid_app=$!;;

#			3) printf "\n-- Running ferret--\n\n"; ./ferret corel lsh queries 10 20 ${NUM_THREADS[$i]} output.txt & pid_app=$!;;

#			4) printf "\n-- Running fluidanimate--\n\n"; ./fluidanimate ${NUM_THREADS[$i]} 5 ../../../inputs/in_300K.fluid out.fluid & pid_app=$!;;

#			5) printf "\n-- Running freqmine--\n\n"; export OMP_NUM_THREADS=$NTHREADS; ./freqmine ../../../inputs/kosarak_990k.dat 790 & pid_app=$!;;

#			6) printf "\n-- Running raytrace--\n\n"; ./raytrace rtview happy_buddha.obj -automove -nthreads ${NUM_THREADS[$i]} -frames 3 -res 1920 1080 & pid_app=$!;;

#			7) printf "\n-- Running swaptions--\n\n"; ./swaptions -ns 64 -sm 40000 -nt ${NUM_THREADS[$i]} & pid_app=$!;;

#			8) printf "\n-- Running x264--\n\n"; ./x264 --quiet --qp 20 --partitions b8x8,i4x4 --ref 5 --direct auto --b-pyramid --weightb --mixed-refs --no-fast-pskip --me umh --subme 7 --analyse b8x8,i4x4 --threads ${NUM_THREADS[$i]} -o eledream.264 ../../../inputs/eledream_640x360_128.y4m & pid_app=$!;;

#			9) printf "\n-- Running vips--\n\n"; export IM_CONCURRENCY=$NTHREADS; ./vips im_benchmark bigben_2662x5500.v output.v & pid_app=$!;;

#			10) printf "\n-- Running canneal--\n\n"; ./canneal ${NUM_THREADS[$i]} 15000 2000 400000.nets 32 & pid_app=$!;;
			
	
			*) echo "INVALID NUMBER!" ;;
      esac 

      wait $pid_app
      echo "Killing Power"
	 sudo kill -9 $PidPower
	 sudo pkill Mapping 
	 sudo pkill Status
      tar -cf CPU_LIST[$i]"_Bots.tar" *.log 

  done
done


