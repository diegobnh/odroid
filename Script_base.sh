#!/bin/bash

#for i in 0 1 2 3 ; do echo 0 > /sys/devices/system/cpu/cpu${i}/online ; done #only small core


if [ -d "Result" ];then     
   mkdir ~/Result
else
   rm ~/Result/*.txt
fi 


OUTPUT_FOLDER=~/Result/
RODINIA_BENCHMARK_FOLDER=/home/diego/Downloads/rodinia_3.1/openmp
SPLASH3_BENCHMARK_FOLDER=/home/diego/Downloads/Splash-3/codes/apps

THREAD_FACTOR="1.0" # 2.0 4.0

CPU_LIST=("0" "0-1" "0-2" "0-3" "4" "4-5" "4-6" "4-7" "0,4" "0,4-5" "0,4-6" "0,4-7" "0-1,4" "0-1,4-5" "0-1,4-6" "0-1,4-7" "0-2,4" "0-2,4-5" "0-2,4-6" "0-2,4-7" "0-3,4" "0-3,4-5" "0-3,4-6" "0-3, 4-7")

NUM_THREADS=("1" "2" "3" "4" "1" "2" "3" "4" "2" "3" "4" "5" "3" "4" "5" "6" "4" "5" "6" "7" "5" "6" "7" "8")

APPS_RODINIA=("backprop" "bfs" "b+tree" "cfd" "heartwall" "hotspot" "hotspot3D" "kmeans" "lavaMD" "lud" "myocyte" "nn" "nw" "particlefilter" "pathfinder" "srad" "streamcluster")
FLAG_RODINIA="True"

APPS_SPLASH3=("barnes" "fmm" "ocean" "radiosity" "raytrace" "volrend" "water-nsquared" "water-spatial")
FLAG_SPLASH3="True"


FLAG_COMPILATION="True"

if [ $FLAG_COMPILATION == 'True' ]; then

	cd $RODINIA_BENCHMARK_FOLDER	
        cd ..
	make OMP_clean
	make OMP

        cd $SPLASH3_BENCHMARK_FOLDER	
        cd ..
	make clean
	make 
fi



if [ $FLAG_RODINIA == 'True' ]; then
	for th_fact in `echo $THREAD_FACTOR`
        do  
	  for cpu in "${CPU_LIST[@]}"
          do
             FOLDERS=`ls -d */` $RODINIA_BENCHMARK_FOLDER
	     for i in $FOLDERS ;
             do
                cd $i
                echo "............................................................."
                echo "                     Executando $i                           "               
                echo "............................................................."
               
                sudo perf stat -o $OUTPUT_FOLDER/$cpu".perf" -I 100 -a -e cycles,instructions,cache-misses taskset -c $cpu ./run 
             done  
          done
        done
fi



