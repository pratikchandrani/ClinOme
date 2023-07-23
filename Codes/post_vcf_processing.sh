#!/bin/bash

cancer=$2

awk '{print $1"\t"$2"\t"$3"\t"$4}' $1/Output/vcf/*_all.table | grep -v 'CHROM' > Filtered.vcf.txt

awk -F'\t' 'NR==FNR{c[$1$2$3$4]++;next};(c[$2$3$4$5])' Filtered.vcf.txt database/gene_mut_ref.txt | awk '{print $1"_p."$6}' > format.vcf.txt

if [ -s format.vcf.txt ]
then

	awk -F'\t' 'NR==FNR{c[$1]++;next};(c[$1])' format.vcf.txt database/Clinome_database.txt | awk '($4 == "Responsive"){print $1"\t"$2"\t"$3"\t"$5}' | sort -u > Responsive.vcf.txt

	awk -F'\t' 'NR==FNR{c[$1]++;next};(c[$1])' format.vcf.txt database/Clinome_database.txt | awk '($4 == "Resistant"){print $1"\t"$2"\t"$3"\t"$5}' | sort -u > Resistant.vcf.txt

	grep -Fxf Resistant.vcf.txt Responsive.vcf.txt > common.vcf.txt

	if [[ -s common.vcf.txt ]]; then awk 'NR==FNR{a[$0]=1;next}!a[$0]' common.vcf.txt Responsive.vcf.txt ; else mv Responsive.vcf.txt Filtered_Responsive.vcf.txt ; fi

	echo -e "clinically relevant SNP	US-FDA approved	US-FDA approved(off label)	Ongoing Clinical trial	US-FDA Approved	US-FDA Approved(Off Label)	Ongoing Clinical Trial" > temp2.vcf.txt

	num=0
	while read snp
	do
		if [[ $num > 0 ]]
		then
			for i in 1 2 3 4 5 6
			do
				rm $i
			done 
			rm snp.vcf.txt
		fi
		while read line1
		do
			snp_line1=$(echo $line1 | awk '{print $1}')
			echo $snp > snp.vcf.txt
			if [[ "$snp" == "$snp_line1" ]]	
			then
					echo $line1 | grep -w "$snp" | awk '($2 == $cancer ) && ($4 == "Approved") {print $1"\t"$3}'| sort -u >> 1 #Responsive approved
					echo $line1 | grep -w "$snp" | awk '($2 != $cancer ) && ($4 == "Approved") {print $1"\t"$3}' >> 2 #Responsive approved off label
					echo $line1 | grep -w "$snp" | awk '($4 != "Approved") {print $1"\t"$3}' >> 3 #Responsive in trial
			fi
		done < Filtered_Responsive.vcf.txt
		
		while read line2
		do
			snp_line2=$(echo $line2 | awk '{print $1}')
			echo $snp > snp.vcf.txt
			if [[ "$snp" == "$snp_line2" ]]	
			then
					echo $line2 | grep -w "$snp" | awk '($2 == $cancer ) && ($4 == "Approved") {print $1"\t"$3}' >> 4 #Resistant approved  
					echo $line2 | grep -w "$snp" | awk '($2 != $cancer ) && ($4 == "Approved") {print $1"\t"$3}' >> 5 #Resistant approved off label		
					echo $line2 | grep -w "$snp" | awk '($4 != "Approved") {print $1"\t"$3}' >> 6  #Resistant in trial
			fi
		done < Resistant.vcf.txt

		#if [[ -s 1 || -s 2 ]]; then : > 3 ; fi
		
		#if [[ -s 4 || -s 5 ]]; then : > 6 ; fi

		paste <(cut -f1 snp.vcf.txt) <(cut -f2 1 | sort -u) <(cut -f2 2 | sort -u) <(cut -f2 3 | sort -u) <(cut -f2 4 | sort -u) <(cut -f2 5 | sort -u) <(cut -f2 6 | sort -u) | tr ' ' '	' >> temp2.vcf.txt 
		num=$((num+1))
	done < format.vcf.txt
	for i in 1 2 3 4 5 6
		do
			rm $i
		done 
	sed 's/,/;/g' temp2.vcf.txt | sed 's/\t/,/g' > $1/Reports/finaloutput2.csv
	dir=$(pwd)
	cp $1/Reports/finaloutput2.csv $dir/Codes 
	pdflatex -interaction=nonstopmode $dir/Codes/final_version.tex -output-directory=$1/Reports
	
else

	echo "No therapeutically relevant mutations found in the genes tested. " > $1/Reports/finaloutput2.csv
	dir=$(pwd)
	cp $1/Reports/finaloutput2.csv $dir/Codes 
	pdflatex -interaction=nonstopmode $dir/Codes/no_result.tex -output-directory=$1/Reports

fi
rm *.vcf.txt
cp *.pdf $1/Reports
cp *.pdf $1/Reports


