#!/bin/bash

cd ~

if [ -d "tmp" ];then     
   mkdir /tmp
else
   rm /tmp/*.out; rm /tmp/*.txt
fi 


RODINIA_BENCHMARK_FOLDER=/home/diego/Downloads/rodinia_3.1/openmp


THREAD_FACTOR="1.0" # 2.0 4.0

CPU_LIST=("0" "0-1" "0-2" "0-3" "4" "4-5" "4-6" "4-7" "0,4" "0,4-5" "0,4-6" "0,4-7" "0-1,4" "0-1,4-5" "0-1,4-6" "0-1,4-7" "0-2,4" "0-2,4-5" "0-2,4-6" "0-2,4-7" "0-3,4" "0-3,4-5" "0-3,4-6" "0-3,4-7")

NUM_THREADS=("1" "2" "3" "4" "1" "2" "3" "4" "2" "3" "4" "5" "3" "4" "5" "6" "4" "5" "6" "7" "5" "6" "7" "8")


#PARSEC 

PARSEC3_BENCHAMRK_FOLDER=/home/odroid/Workloads-ARMv7/parsec-armv7/parsec-3.0/pkgs/

APP_PARSEC3=("apps/blackscholes/inst/arm-linux.gcc/bin" "apps/bodytrack/inst/arm-linux.gcc/bin" "apps/facesim/inst/arm-linux.gcc/bin" "apps/ferret/inst/arm-linux.gcc/bin" "apps/fluidanimate/inst/arm-linux.gcc/bin" "apps/freqmine/inst/arm-linux.gcc/bin" "apps/raytrace/inst/arm-linux.gcc/bin" "apps/swaptions/inst/arm-linux.gcc/bin" "apps/x264/inst/arm-linux.gcc/bin" "apps/vips/inst/arm-linux.gcc/bin" "kernels/canneal/inst/arm-linux.gcc/bin" "kernels/dedup/inst/arm-linux.gcc/bin" "kernels/streamcluster/inst/arm-linux.gcc/bin")

APP_PARSEC3_NAMES=("blackscholes" "bodytrack" "facesim" "ferret" "fluidanimate" "freqmine" "raytrace" "swaptions" "x264" "vips"  "canneal" "dedup" "streamcluster")

FLAG_PARSEC3="False"



#SPLASH-3 

SPLASH3_BENCHMARK_FOLDER=~/diego/benchmarks/Splash-3-master/codes/
#SPLASH3_BENCHMARK_FOLDER=/home/diego/Downloads/Salvador-Vinicius/Benchmarks/Splash-3-master/codes


APP_SPLASH3=("apps/ocean" "apps/radiosity" "apps/raytrace" "apps/volrend" "kernels/lu" "kernels/lu" "kernels/radix")

APP_SPLASH3_NAMES=("ocean contiguous" "radiosity" "raytrace" "volrend" "lu contiguous" "lu nocontiguous" "radix")

FLAG_SPLASH3="True"


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
                           then ./contiguous_partitions/OCEAN -p ${NUM_THREADS[$i]} -n 2050 & pid_app=$!
                           fi ;;

			1) printf "\n-- Running ${APP_SPLASH3_NAMES[$j]}--\n\n"; ./RADIOSITY -p ${NUM_THREADS[$i]} -room -batch & pid_app=$!;;

			2) printf "\n-- Running ${APP_SPLASH3_NAMES[$j]}--\n\n"; ./RAYTRACE -p${NUM_THREADS[$i]} -a1600 -m100 inputs/car.env & pid_app=$!;;

			3) printf "\n-- Running ${APP_SPLASH3_NAMES[$j]}--\n\n"; ./VOLREND ${NUM_THREADS[$i]} inputs/head 512 & pid_app=$!;;		

			4) printf "\n-- Running ${APP_SPLASH3_NAMES[$j]}--\n\n"; ./contiguous_blocks/LU -n4096 -p${NUM_THREADS[$i]} -b512 & pid_app=$!;;

			5) printf "\n-- Running ${APP_SPLASH3_NAMES[$j]}--\n\n"; ./non_contiguous_blocks/LU -n4096 -p${NUM_THREADS[$i]} -b512 & pid_app=$!;;

			6) printf "\n-- Running ${APP_SPLASH3_NAMES[$j]}--\n\n"; 
                           if [[ "${NUM_THREADS[$i]}" == "1" || "${NUM_THREADS[$i]}" == "2" || "${NUM_THREADS[$i]}" == "4" || "${NUM_THREADS[$i]}" == "8" ]]
                           then ./RADIX -p${NUM_THREADS[$i]} -n134217728 -r4096 & pid_app=$!
                           fi ;;

	
			*) echo "INVALID NUMBER!" ;;
		  esac 

                  sleep 1;
          	  taskset -a -cp ${CPU_LIST[$i]} $pid_app
	          #start perf monitor (needs sudo)
	          #perf stat --per-thread -o /tmp/perf.out -I 200 -p $pid_app & pid_perf=$!
                  perf stat -o /tmp/perf.out -I 200 -e cycles,instructions,cache-misses,LLC-load-misses -p $pid_app & pid_perf=$!  #desempenho sumarizado!

           	  wait $pid_app

                  kill $pid_perf
                  #kill $pid_power

                  sleep 2
                  kill -9 $pid_perf 1> /dev/null 2>/dev/null 
            
                  if [ -f "/tmp/perf.out" ]
		  then
		      mv /tmp/perf.out /tmp/"perf_${APP_SPLASH3_NAMES[$j]}.${CPU_LIST[$i]}.txt"
		  else
		      printf "\n !!! Perf didnt create perf.out to ${APP_SPLASH3_NAMES[$j]} !!! \n"
                  fi
                  cd ../../
               
                  sleep 15
             done		                        
          done
        done
fi


if [ $FLAG_PARSEC == 'True' ]; then
	for tf in `echo $THREAD_FACTOR`
        do  
	  for ((i = 0; i < ${#CPU_LIST[@]}; i++));
          do             
             cd $SPLASH3_BENCHMARK_FOLDER   #Path to all benchmarks
             for ((j = 0; j < ${#APP_PARSEC3[@]}; j++)); do
	          cd  ${APP_PARSEC[$j]} #Path specific benchmark
 
                  # start power monitor
                  #sudo ./wattsup/wattsup -t ttyUSB0 watts > /tmp/power.out & pid_power=$!

                  #all simlarge input:
                  case $j in
			0) printf "\n-- Running blackscholes--\n\n"; ./blackscholes $NUM_THREADS in_64K.txt /tmp/temp.out & pid_app=$!;;

			1) printf "\n-- Running bodytrack--\n\n"; ./bodytrack sequenceB_4/ 4 1 1000 3 0 $NUM_THREADS & pid_app=$!;;

			2) printf "\n-- Running facesim--\n\n"; ./facesim -timing -threads $NUM_THREADS & pid_app=$!;;

			3) printf "\n-- Running ferret--\n\n"; ./ferret corel lsh queries 10 20 $NUM_THREADS output.txt & pid_app=$!;;

			4) printf "\n-- Running fluidanimate--\n\n"; ./fluidanimate $NUM_THREADS 5 ../../../inputs/in_300K.fluid out.fluid & pid_app=$!;;

			5) printf "\n-- Running freqmine--\n\n"; export OMP_NUM_THREADS=$NTHREADS; ./freqmine ../../../inputs/kosarak_990k.dat 790 & pid_app=$!;;

			6) printf "\n-- Running raytrace--\n\n"; ./raytrace rtview happy_buddha.obj -automove -nthreads $NUM_THREADS -frames 3 -res 1920 1080 & pid_app=$!;;

			7) printf "\n-- Running swaptions--\n\n"; ./swaptions -ns 64 -sm 40000 -nt $NUM_THREADS & pid_app=$!;;

			8) printf "\n-- Running x264--\n\n"; ./x264 --quiet --qp 20 --partitions b8x8,i4x4 --ref 5 --direct auto --b-pyramid --weightb --mixed-refs --no-fast-pskip --me umh --subme 7 --analyse b8x8,i4x4 --threads $NUM_THREADS -o eledream.264 ../../../inputs/eledream_640x360_128.y4m & pid_app=$!;;

			9) printf "\n-- Running vips--\n\n"; export IM_CONCURRENCY=$NTHREADS; ./vips im_benchmark bigben_2662x5500.v output.v & pid_app=$!;;

			10) printf "\n-- Running canneal--\n\n"; ./canneal $NUM_THREADS 15000 2000 400000.nets 32 & pid_app=$!;;

			11) printf "\n-- Running dedup--\n\n"; ./dedup -c -p -v -t $NUM_THREADS -i media.dat -o output.dat.ddp & pid_app=$!;;

			12) printf "\n-- Running streamcluster--\n\n"; ./streamcluster 10 20 128 16384 16384 1000 none output.txt $NUM_THREADS & pid_app=$!;;
	
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
		      printf "\n !!! Perf didnt create perf.out to ${APP_PARSEC_NAMES[$j]} !!! \n"
                  fi
                  
                  cd ../../../../../
               
                  sleep 15
             done		                        
          done
        done
fi


