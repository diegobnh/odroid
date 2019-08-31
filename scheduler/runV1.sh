#!/bin/sh

rm *.csv


#remove files existentes
FOLDERS=`ls -d */`
for i in $FOLDERS ;
do  
    cd $i; 
    echo "analisando:"$i
    rm times.txt
    cd ..
done
    

#utiliza o script que junta os pmcs em um único arquivo
FOLDERS=`ls -d 4b_* 4b4l_A15*`
for i in $FOLDERS ;
do  
    cd $i
    #echo "Folder:"$i
    bash ../../postprocess_experiment.sh "big"
    cat times.txt | tr "." "," | datamash sstdev 1 > desv
    cd .. ; 
done


FOLDERS=`ls -d 4l_* 4b4l_A7*`
for i in $FOLDERS ;
do  
    cd $i
    #echo "Folder:"$i
    bash ../../postprocess_experiment.sh "little"       
    cat times.txt | tr "." "," | datamash sstdev 1 > desv
    cd .. ; 
done


#After calculate the average,confirm if the results are corrects using the command below:
#cat 4b4l_A7*/consolidated-pmc-little.csv.average
#cat 4b4l_A15*/consolidated-pmc-little.csv.average

echo ""
cat */desv
read -p "Veja se alguma aplicação possui um desvio padrão alto(>3). Se tiver, altere a media na mão."


#Get the execution time from each config
cat 4b4l_A7*/exec_time.average > 4b4l_1
cat 4b4l_A15*/exec_time.average > 4b4l_2
cat 4b_*/exec_time.average > 4b
cat 4l_*/exec_time.average > 4l

paste 4b4l_1 4b4l_2 | awk '{print ($1+$2)*0.50}' > 4b4l

paste 4b4l 4b 4l | awk '{printf "%.6f,%.6f\n", $3/$1, $3/$2}' > speedup_4l
paste 4b4l 4b 4l | awk '{printf "%.6f,%.6f\n", $2/$1, $2/$3}' > speedup_4b
paste 4b4l 4b 4l | awk '{printf "%.6f,%.6f\n", $1/$2, $1/$3}' > speedup_4b4l 

rm 4b4l 4b4l_1 4b4l_2 4b 4l 


#Calculate dataset for 4little
#Replace the last column with the speedup

var=1
FOLDERS=`ls -d 4l_bots*`
for i in $FOLDERS ;
do  
    cd $i 

    cat ../speedup_4l | tr "," " " | awk  -v c=$var 'NR==c {print $1}' > ../to_4b4l
    cat ../speedup_4l | tr "," " " | awk  -v c=$var 'NR==c {print $2}' > ../to_4b
    cat consolidated-pmc-little.csv.average | tr "," " " | awk '{$34=""; print}' | tr " " "," > ../average_samples
    paste ../average_samples ../to_4b4l -d "" >> ../4l_to_4b4l.csv
    paste ../average_samples ../to_4b -d "" >> ../4l_to_4b.csv
    var=$((var+1)) #vai iterando e permitindo que o awk possa pegar linha a linha
    cd ..    
done

rm to_* average_samples            


#Calculate dataset for 4big
var=1
FOLDERS=`ls -d 4b_bots*`
for i in $FOLDERS ;
do  
    cd $i 

    cat ../speedup_4b | tr "," " " | awk  -v c=$var 'NR==c {print $1}' > ../to_4b4l
    cat ../speedup_4b | tr "," " " | awk  -v c=$var 'NR==c {print $2}' > ../to_4l
    cat consolidated-pmc-big.csv.average | tr "," " " | awk '{$57=""; print}' | tr " " "," > ../average_samples
    paste ../average_samples ../to_4b4l -d "" >> ../4b_to_4b4l.csv
    paste ../average_samples ../to_4l -d "" >> ../4b_to_4l.csv
    var=$((var+1)) #vai iterando e permitindo que o awk possa pegar linha a linha
    cd ..    
done

rm to_* average_samples  

#Calculate dataset for 4b4l
FOLDERS=`ls -d 4b4l_A15*`
for i in $FOLDERS ;
do  
    cd $i  

    cat consolidated-pmc-big.csv.average | tr "," " " | awk '{$57=""; print}' | tr " " "," >> ../average_samples_A15
    cd ..    
done

FOLDERS=`ls -d 4b4l_A7*`
for i in $FOLDERS ;
do  
    cd $i     

    cat consolidated-pmc-little.csv.average | tr "," " " | awk '{$34=""; print}' | tr " " "," >> ../average_samples_A7
    cd ..    
done


cat speedup_4b4l | tr "," " " | awk '{print $1}' > to_4b
cat speedup_4b4l | tr "," " " | awk '{print $2}' > to_4l

paste average_samples_A7 average_samples_A15 to_4b -d "" > 4b4l_to_4b.csv
paste average_samples_A7 average_samples_A15 to_4l -d "" > 4b4l_to_4l.csv

rm to_* average_samples_* 
