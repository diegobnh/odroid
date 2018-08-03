#!/bin/bash




PERF_CMD1="perf stat -o /tmp/perf.out -a -C "
PERF_CMD2=" -e instructions,cycles,cache-misses,cache-references,branches,branch-misses"
#TIME_COMMAND="/usr/bin/time -p -o /tmp/time.out"


RODINIA_BENCHMARK_FOLDER=/home/diego/Downloads/rodinia_3.1/openmp

ITERACOES="1 2 3 4 5"
THREAD_FACTOR="1.0" # 2.0 4.0
CPU_LIST=("0-3,4-7" "0-2,4" "0-1,4-5" "0,4-6" "4-7" "0-3" "0,4" "0-1" "4-5" "0" "4")
NUM_THREADS=("8" "4" "4" "4" "4" "4" "2" "2" "2" "1" "1") 



##################################################PARSEC############################################################# 
PARSEC3_BENCHAMRK_FOLDER=/home/odroid/Workloads-ARMv7/parsec-armv7/parsec-3.0/pkgs/
APP_PARSEC3=("apps/blackscholes/inst/arm-linux.gcc/bin" "apps/bodytrack/inst/arm-linux.gcc/bin" "apps/facesim/inst/arm-linux.gcc/bin" "apps/ferret/inst/arm-linux.gcc/bin" "apps/fluidanimate/inst/arm-linux.gcc/bin" "apps/freqmine/inst/arm-linux.gcc/bin" "apps/raytrace/inst/arm-linux.gcc/bin" "apps/swaptions/inst/arm-linux.gcc/bin" "apps/x264/inst/arm-linux.gcc/bin" "apps/vips/inst/arm-linux.gcc/bin" "kernels/canneal/inst/arm-linux.gcc/bin" "kernels/dedup/inst/arm-linux.gcc/bin" "kernels/streamcluster/inst/arm-linux.gcc/bin")
APP_PARSEC3_NAMES=("blackscholes" "bodytrack" "facesim" "ferret" "fluidanimate" "freqmine" "raytrace" "swaptions" "x264" "vips"  "canneal" "dedup" "streamcluster")
FLAG_PARSEC3="False"



##################################################SPLASH-3#############################################################

SPLASH3_BENCHMARK_FOLDER=~/diego/benchmarks/Splash-3-master/codes/
#APP_SPLASH3=("apps/ocean" "apps/radiosity" "apps/raytrace" "apps/volrend" "kernels/lu" "kernels/lu" "kernels/radix")
APP_SPLASH3=("apps/radiosity")

#APP_SPLASH3_NAMES=("ocean contiguous" "radiosity" "raytrace" "volrend" "lu contiguous" "lu nocontiguous" "radix")
APP_SPLASH3_NAMES=("radiosity")
FLAG_SPLASH3="True"


if [ $FLAG_SPLASH3 == 'True' ]; then
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
             cd $SPLASH3_BENCHMARK_FOLDER   #Path to all benchmarks
             for ((j = 0; j < ${#APP_SPLASH3[@]}; j++)); do
	          cd  ${APP_SPLASH3[$j]} #Path specific benchmark
 
                  # start power monitor
                  #sudo ./wattsup/wattsup -t ttyUSB0 watts > /tmp/power.out & pid_power=$!

                  #all simlarge input:
                  case $j in
#			0) printf "\n-- Running ${APP_SPLASH3_NAMES[$j]} -- Config:${CPU_LIST[$i]}\n\n"; 
#                           if [[ "${NUM_THREADS[$i]}" == "1" || "${NUM_THREADS[$i]}" == "2" || "${NUM_THREADS[$i]}" == "4" || "${NUM_THREADS[$i]}" == "8" ]]
#                           then taskset -a -c ${CPU_LIST[$i]} $PERF_CMD1 ${CPU_LIST[$i]} $PERF_CMD2 ./contiguous_partitions/OCEAN -p ${NUM_THREADS[$i]} -n 2050 
#                           fi ;;

			0) printf "\n-- Running ${APP_SPLASH3_NAMES[$j]} -- Config:${CPU_LIST[$i]}\n\n"; taskset -a -c ${CPU_LIST[$i]} $PERF_CMD1 ${CPU_LIST[$i]} $PERF_CMD2 ./RADIOSITY -p ${NUM_THREADS[$i]} -room -batch;;

#			2) printf "\n-- Running ${APP_SPLASH3_NAMES[$j]} -- Config:${CPU_LIST[$i]}\n\n"; taskset -a -c ${CPU_LIST[$i]} $PERF_CMD1 ${CPU_LIST[$i]} $PERF_CMD2 ./RAYTRACE -p${NUM_THREADS[$i]} -a1600 -m100 inputs/car.env ;;

#			3) printf "\n-- Running ${APP_SPLASH3_NAMES[$j]} -- Config:${CPU_LIST[$i]}\n\n"; taskset -a -c ${CPU_LIST[$i]} $PERF_CMD1 ${CPU_LIST[$i]} $PERF_CMD2 ./VOLREND ${NUM_THREADS[$i]} inputs/head 512 ;;		

#			4) printf "\n-- Running ${APP_SPLASH3_NAMES[$j]} -- Config:${CPU_LIST[$i]}\n\n"; taskset -a -c ${CPU_LIST[$i]} $PERF_CMD1 ${CPU_LIST[$i]} $PERF_CMD2 ./contiguous_blocks/LU -n4096 -p${NUM_THREADS[$i]} -b512 ;;

#			5) printf "\n-- Running ${APP_SPLASH3_NAMES[$j]} -- Config:${CPU_LIST[$i]}\n\n"; taskset -a -c ${CPU_LIST[$i]} $PERF_CMD1 ${CPU_LIST[$i]} $PERF_CMD2 ./non_contiguous_blocks/LU -n4096 -p${NUM_THREADS[$i]} -b512;;

#			6) printf "\n-- Running ${APP_SPLASH3_NAMES[$j]} -- Config:${CPU_LIST[$i]}\n\n"; 
 #                          if [[ "${NUM_THREADS[$i]}" == "1" || "${NUM_THREADS[$i]}" == "2" || "${NUM_THREADS[$i]}" == "4" || "${NUM_THREADS[$i]}" == "8" ]]
#                          then taskset -a -c ${CPU_LIST[$i]} $PERF_CMD1 ${CPU_LIST[$i]} $PERF_CMD2 ./RADIX -p${NUM_THREADS[$i]} -n134217728 -r4096 
 #                          fi ;;

	
			*) echo "INVALID NUMBER!" ;;
		  esac 

                  #sleep 1;
          	  #taskset -a -cp ${CPU_LIST[$i]} $pid_app
	          #start perf monitor (needs sudo)
	          #perf stat --per-thread -o /tmp/perf.out -I 200 -p $pid_app & pid_perf=$!
                  #perf stat -o /tmp/perf.out -I 200 -e cycles,instructions,cache-misses,LLC-load-misses -p $pid_app & pid_perf=$!  #desempenho sumarizado!

           	  #wait $pid_app

                  #kill $pid_perf
                  #kill $pid_power

                  #sleep 2
                  #kill -9 $pid_perf 1> /dev/null 2>/dev/null 
            
                  if [ -f "/tmp/perf.out" ]
		  then
		      mv /tmp/perf.out /tmp/"${APP_SPLASH3_NAMES[$j]}.${CPU_LIST[$i]}.perf"
		  else
		      printf "\n !!! Perf didnt create perf.out to ${APP_SPLASH3_NAMES[$j]} !!! \n"
                  fi

                  #if [ -f "/tmp/time.out" ]
		  #then
		  #    mv /tmp/time.out /tmp/"${APP_SPLASH3_NAMES[$j]}.${CPU_LIST[$i]}.time"
		  #else
		  #    printf "\n !!! Perf didnt create time.out to ${APP_SPLASH3_NAMES[$j]}.${CPU_LIST[$i]} !!! \n"
                  #fi     

                  cd ../../
                                 
             done		                        
          done
          
          cd /tmp/          
          tar -cf "$it.tar" *.perf 
          mv "$it.tar" ~/diego/git
        done
fi

rm *.perf

#FALTA ADAPTAR !! SE BASEAR NO FLUIDANAMITE!!
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
			0) printf "\n-- Running blackscholes--\n\n"; ./blackscholes ${NUM_THREADS[$i]} in_64K.txt /tmp/temp.out & pid_app=$!;;

			1) printf "\n-- Running bodytrack--\n\n"; ./bodytrack sequenceB_4/ 4 1 1000 3 0 ${NUM_THREADS[$i]} & pid_app=$!;;

			2) printf "\n-- Running facesim--\n\n"; ./facesim -timing -threads ${NUM_THREADS[$i]} & pid_app=$!;;

			3) printf "\n-- Running ferret--\n\n"; ./ferret corel lsh queries 10 20 ${NUM_THREADS[$i]} output.txt & pid_app=$!;;

			4) printf "\n-- Running fluidanimate--\n\n"; ./fluidanimate ${NUM_THREADS[$i]} 5 ../../../inputs/in_300K.fluid out.fluid & pid_app=$!;;

			5) printf "\n-- Running freqmine--\n\n"; export OMP_NUM_THREADS=$NTHREADS; ./freqmine ../../../inputs/kosarak_990k.dat 790 & pid_app=$!;;

			6) printf "\n-- Running raytrace--\n\n"; ./raytrace rtview happy_buddha.obj -automove -nthreads ${NUM_THREADS[$i]} -frames 3 -res 1920 1080 & pid_app=$!;;

			7) printf "\n-- Running swaptions--\n\n"; ./swaptions -ns 64 -sm 40000 -nt ${NUM_THREADS[$i]} & pid_app=$!;;

			8) printf "\n-- Running x264--\n\n"; ./x264 --quiet --qp 20 --partitions b8x8,i4x4 --ref 5 --direct auto --b-pyramid --weightb --mixed-refs --no-fast-pskip --me umh --subme 7 --analyse b8x8,i4x4 --threads ${NUM_THREADS[$i]} -o eledream.264 ../../../inputs/eledream_640x360_128.y4m & pid_app=$!;;

			9) printf "\n-- Running vips--\n\n"; export IM_CONCURRENCY=$NTHREADS; ./vips im_benchmark bigben_2662x5500.v output.v & pid_app=$!;;

			10) printf "\n-- Running canneal--\n\n"; ./canneal ${NUM_THREADS[$i]} 15000 2000 400000.nets 32 & pid_app=$!;;

			11) printf "\n-- Running dedup--\n\n"; ./dedup -c -p -v -t ${NUM_THREADS[$i]} -i media.dat -o output.dat.ddp & pid_app=$!;;

			12) printf "\n-- Running streamcluster--\n\n"; ./streamcluster 10 20 128 16384 16384 1000 none output.txt ${NUM_THREADS[$i]} & pid_app=$!;;
	
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


