#!/bin/sh


if [ $1 = "little" ]; then
	OUTPUT_FILE_NAME="consolidated-pmc-little.csv"

	[ -e $OUTPUT_FILE_NAME ] && rm $OUTPUT_FILE_NAME


	files=`ls *.csv`
	for file in $files ;
	do  
           cat $file | awk 'END{print $1}' | tr "," " " | awk '{print $1*0.001}' >> times.txt
           wc -l $file | awk '{print $1}' >> num_lines.txt

	   pmcs=${file%.csv}

	   #remove the first two lines and the last two lines
	   num_lines=`cat $file |wc -l`
	   x=$((num_lines-2)) 
	   sed -e "$x,\$d" $file > temp1
	   sed -e "1,2d" temp1 > temp2
	   
	   #remove the time column and the columns 11,12 that means utilization
	   cat temp2 | tr "," " " | awk '{$1=$7=$8=$9=$10=""; print}' > temp3

	   #calculates pmcs normalizing by instructions
	   cat temp3 | awk '{printf "%.6f,%.6f,%.6f,%.6f\n", $2/$1, $3/$1, $4/$1, $5/$1}' > $pmcs".post_process"	  

	   #save the num_lines
	   cat $pmcs".post_process" | wc -l  > $pmcs".lines"

	   rm temp*

	done

	paste *.post_process -d "," > all_pmus

	NUM_LINHAS_COMUM=1000000
	FILES=$(ls *.lines)      
	for i in $FILES;
	do  
		atual=$(cat $i)
		if [ $atual -lt $NUM_LINHAS_COMUM ]
		then
		    NUM_LINHAS_COMUM=$atual
		fi
	done	       
	  
	rm *.lines

	sed -n "1,$NUM_LINHAS_COMUM p" all_pmus > $OUTPUT_FILE_NAME

	#add new line with subtitle for each column
	#sed -i -e '1i0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x0f,0x10,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x1D,0x60,0x61,0x86,0x87,0xc0,0xc1,0xc2,0xc3,0xc4,0xc5,0xc6,0xc7,0xc8,0xc9,0xca\' $OUTPUT_FILE_NAME
        sed -i -e '1iinst_fetch_refill,inst_fetch_tlb_refill,data_read_write_refill,data_read_write_refill,data_read_write_tlb_refill,data_read_exec,data_write_exec,ins_exec,excep_taken,excep_exec,context_retir,change_pc,imed_branch_exec,proc_return,un_load_store,branch_predic,branch,data_mem_access,inst_cache_access,data_cache_evic,l2_data_cache_access,l2_data_cache_refill,l2_data_cache_write,bus_access,bus_cycle,bus_access_read,bus_access_write,irq_excep,fiq_excep,ext_mem_req,no_cache_ext_mem_req,linefill,prefetch,enter_read_alloc_mode,read_alloc_mode,reserved,etm_0,etm_1,data_write_stalls,data_snooped\' $OUTPUT_FILE_NAME


elif [ $1 = "big" ]; then
	OUTPUT_FILE_NAME="consolidated-pmc-big.csv"

	[ -e $OUTPUT_FILE_NAME ] && rm $OUTPUT_FILE_NAME

	files=`ls *.csv`
	for file in $files ;
	do  
           cat $file | awk 'END{print $1}' | tr "," " " | awk '{print $1*0.001}' >> times.txt
           wc -l $file | awk '{print $1}' >> num_lines.txt

	   pmcs=${file%.csv}

	   #remove the first two lines and the last two lines
	   num_lines=`cat $file |wc -l`
	   x=$((num_lines-2)) 
	   sed -e "$x,\$d" $file > temp1
	   sed -e "1,2d" temp1 > temp2
	   
	   #remove the time column and the columns 9,10,11,12 that means cluster utilization and software counters
	   cat temp2 | tr "," " " | awk '{$1=$9=$10=$11=$12=""; print}' > temp3

	   #calculates pmcs normalizing by instructions
	   cat temp3 | awk '{printf "%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n", $2/$1, $3/$1, $4/$1, $5/$1, $6/$1, $7/$1}' > $pmcs".post_process"	  

	   #save the num_lines
	   cat $pmcs".post_process" | wc -l  > $pmcs".lines"

	   rm temp*

	done

	paste *.post_process -d "," > all_pmus

	NUM_LINHAS_COMUM=1000000
	FILES=$(ls *.lines)      
	for i in $FILES;
	do  
		atual=$(cat $i)
		if [ $atual -lt $NUM_LINHAS_COMUM ]
		then
		    NUM_LINHAS_COMUM=$atual
		fi
	done	       
	  
	rm *.lines

	sed -n "1,$NUM_LINHAS_COMUM p" all_pmus > $OUTPUT_FILE_NAME 

	#add new line with subtitle for each column
	#sed -i -e '1i0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x10,0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x1a,0x1b,0x1c,0x1d,0x40,0x41,0x42,0x43,0x46,0x47,0x48,0x4C,0x4D,0x50,0x51,0x52,0x53,0x56,0x57,0x58,0x60,0x61,0x62,0x63,0x64,0x65,0x66,0x67,0x68,0x69,0x6a,0x6c,0x6d,0x6e,0x70,0x71,0x72,0x73,0x74,0x75,0x76,0x78,0x79,0x7a,0x7c,0x7d,0x7e,0xe5,0xe6,0xe7,0xe8\' $OUTPUT_FILE_NAME 
        sed -i -e '1iins_exec_soft,l1_inst_cache_refill,l1_inst_cache_tlb_refill,l1_d_cache_refill,l1_d_cache_access,l1_data_tlb_refill,ins_exec,excep_taken,ins_exec_except,ins_exec_context,mispred_branch,pred_branch,data_mem_access,l1_inst_cache_access,l1_d_cache_write,l2_d_cache_access,l2_d_cache_refill,l2_d_cache_write,bus_access,local_mem_error,inst_espec_exec,inst_exec,bus_cycle,l1_d_cache_access_read,l1_d_cache_access_write,l1_d_cache_refill_read,l1_d_cache_refill_write,l1_d_cache_writeback_victim,l1_d_cache_writeback_clean,l1_d_cache_inv,l1_d_tlb_refill_read,l1_d_tlb_refill_write,l2_d_cache_access_read,l2_d_cache_access_write,l2_d_cache_refill_read,l2_d_cache_refill_write,l2_d_cache_writeback_victim,l2_d_cache_writeback_clean,l2_d_cache_inv,bus_access_read,bus_access_write,bus_access_norm1,bus_access_not_norm,bus_access_norm2,bus_access_perip,data_mem_access_read,data_mem_access_write,un_access_read,un_access_write,un_access,ldrex,strex_pass,strex_fail,load,store,load_or_store,integer_proc,simd,vfp,change_pc,branch_esp_imm,branch_esp_proc,branch_esp_ind,barrier_isb,barrier_dsb,barrier_dmb\' $OUTPUT_FILE_NAME

else
   echo "You need pass as argument cluster name: big or little"
   read -p "Press enter to exit!"
   exit 1
fi





cat times.txt | tr "." "," | datamash mean 1 | tr "," "." > exec_time.average

if [ $1 = "little" ]; then
   sed 1d $OUTPUT_FILE_NAME | tr "," "\t" | tr "." "," | datamash mean 1-66 | tr "," "." | tr "\t" "," > $OUTPUT_FILE_NAME".average"
   paste $OUTPUT_FILE_NAME".average" exec_time.average -d "," >  input.data
else
   sed 1d $OUTPUT_FILE_NAME | tr "," "\t" | tr "." "," | datamash mean 1-66 | tr "," "." | tr "\t" "," > $OUTPUT_FILE_NAME".average"
   paste $OUTPUT_FILE_NAME".average" exec_time.average -d "," >  input.data
fi

read -p "Check the files TIMES and NUM_LINES before the delete.."


rm all_pmus *.post_process times.txt num_lines.txt
