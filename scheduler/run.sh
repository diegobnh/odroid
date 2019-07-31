#!/bin/sh


FOLDERS=`ls -d 4b_* 4b4l_A15*`
for i in $FOLDERS ;
do  
    cd $i
    #echo "Folder:"$i
    bash ../../postprocess_experiment.sh "big"
    cd .. ; 
done


FOLDERS=`ls -d 4l_* 4b4l_A7*`
for i in $FOLDERS ;
do  
    cd $i
    echo "Folder:"$i
    bash ../../postprocess_experiment.sh "little"       
    cd .. ; 
done


#After calculate the average,confirm if the results are corrects using the command below:
#cat 4b4l_A7*/consolidated-pmc-little.csv.average
#cat 4b4l_A15*/consolidated-pmc-little.csv.average

#Get the execution time from each config
cat 4b4l_A7*/exec_time.average > 4b4l_1
cat 4b4l_A15*/exec_time.average > 4b4l_2
cat 4b_*/exec_time.average > 4b
cat 4l_*/exec_time.average > 4l

paste 4b4l_1 4b4l_2 | awk '{print ($1+$2)*0.50}' > 4b4l
paste 4b4l 4b 4l | awk '{printf "%.6f,%.6f\n", $1/$3, $2/$3}' > speedup_4l
paste 4b4l 4b 4l | awk '{printf "%.6f,%.6f\n", $1/$2, $3/$2}' > speedup_4b
paste 4b4l 4b 4l | awk '{printf "%.6f,%.6f\n", $2/$1, $3/$1}' > speedup_4b4l 

read -p "verifique o speedup"

rm 4b4l* 4b 4l all_time.txt


#Replace the last column with the speedup
var=1
FOLDERS=`ls -d *little*`
rm speedup4b4l.csv
for i in $FOLDERS ;
do  
                  
    cd $i 
    cat ../speedup | tr "," " " | awk  -v c=$var 'NR==c {print $1}' > temp1
    cat consolidated-pmc-little.csv.average | tr "," " " | awk '{$34=""; print}' | tr " " "," > temp2
    paste temp2 temp1 -d "" >> ../speedup4b4l.csv
    rm temp*            
    var=$((var+1))
    cd ..    
done


var=1
FOLDERS=`ls -d *little*`
rm speedup4b.csv
for i in $FOLDERS ;
do  
                  
    cd $i 
    cat ../speedup | tr "," " " | awk  -v c=$var 'NR==c {print $2}' > temp1
    cat consolidated-pmc-little.csv.average | tr "," " " | awk '{$34=""; print}' | tr " " "," > temp2
    paste temp2 temp1 -d "" >> ../speedup4b.csv
    rm temp*                
    var=$((var+1))
    cd ..    
done


