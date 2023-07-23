#!/bin/bash

../Tools/FastQC/fastqc $1
../Tools/FastQC/fastqc $2

mkdir $3/QC_pre

dir=$(dirname $1)

mv $dir/*_fastqc.html $3/QC_pre
mv $dir/*_fastqc.zip $3/QC_pre

cd $3/QC_pre

echo -e "Sample\tRead Pair\tRead 1\tRead 2" > $3/Report/QC_Report_pre.output.csv  

for z in *_R1_001_fastqc.zip
do
	unzip -n $z -d $3/QC_pre > log
	unzip -n ${z/_R1_001_fastqc.zip/_R2_001_fastqc.zip} -d $3/QC_pre >> log
	total=$(grep "Total Sequences" ${z/_R1_001_fastqc.zip/_R1_001_fastqc}/fastqc_data.txt | awk '{print $3}')
	sample=$(echo $z | awk -F"_" '{print $1"_" $2}')
	

	#for file1 R1

	sed -n "13, 51p" ${z/_R1_001_fastqc.zip/_R1_001_fastqc}/fastqc_data.txt > temp_R1.txt

	col_R1=$(awk '{print $1"\t"$4}' temp_R1.txt |awk '{if($2 < 20) print $0}' |sort -n -k 1 | awk 'NR==1{print}' |awk '{print $1}')
	num_R1=$(awk '{print $1"\t"$4}' temp_R1.txt |awk '{if($2 < 20) print $0}' |sort -n -k 1 |awk 'NR==1{print}' |awk '{print $2}')
	
	if [ -n "$col_R1" ];
		then
			echo "its working"
			if [[ $col_R1 == *[-]* ]]
			then
				col_sub_R1=$(echo $col_R1 | awk -F"-" '{print $1}')
			else 
				col_sub_R1=$col_R1
			fi
			if [[ $col_sub_R1 -ge 140 && $col_sub_R1 -le 151 ]]
				then
					R1="Good"
			elif [[ $col_sub_R1 -ge 100 && $col_sub_R1 -lt 140 ]]
				then
					R1="Intermediate"
			elif [[ $col_sub_R1 -lt 100 ]]
				then
					R1="Poor"
			fi

	elif [ -z "$col_R1" ];
		then
			R1="Good"
			
	fi

	#for file2 R2

	sed -n "13, 51p" ${z/_R1_001_fastqc.zip/_R2_001_fastqc}/fastqc_data.txt > temp_R2.txt

	col_R2=$(awk '{print $1"\t"$4}' temp_R2.txt |awk '{if($2 < 20) print $0}' |sort -n -k 1 | awk 'NR==1{print}' |awk '{print $1}')
	num_R2=$(awk '{print $1"\t"$4}' temp_R2.txt |awk '{if($2 < 20) print $0}' |sort -n -k 1 |awk 'NR==1{print}' |awk '{print $2}')
	if [ -n "$col_R2" ];
		then
			if [[ $col_R2 == *[-]* ]]
			then
				col_sub_R2=$(echo $col_R2 | awk -F"-" '{print $1}')
			else 
				col_sub_R2=$col_R2
			fi
			if [[ $col_sub_R2 -ge 140 && $col_sub_R2 -le 151 ]]
				then
					R2="Good"
			elif [[ $col_sub_R2 -ge 100 && $col_sub_R2 -lt 140 ]]
				then
					R2="Intermediate"
			elif [[ $col_sub_R2 -lt 100 ]]
				then
					R2="Poor"
			fi	
	elif [ -z "$col_R2" ];
		then
			R2="Good"
	fi
	
	echo "$sample	$total	$R1	$R2" >> $3/Report/QC_Report_pre.output.csv 
done

