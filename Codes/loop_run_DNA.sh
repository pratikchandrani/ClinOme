Out_dir=$1
Cancer=$2

echo -e "clinically relevant SNP	AF	DP	US-FDA approved	US-FDA approved(off label)	Ongoing Clinical trial	US-FDA Approved	US-FDA Approved(Off Label)	Ongoing Clinical Trial" > $Out_dir/Overall_DNA.csv

echo -e "Sample	Coverage" > $Out_dir/Overall_coverage_DNA.csv  

for i in $Out_dir/*R1_001.fastq.gz
do
	file=$(basename $i)
	sample=$(echo $file | awk -F"_" '{print $1"_"$2"_"$3}')
	echo "###################$sample#######################" >> $Out_dir/time.log 
	bash DNA_processing.sh "$Out_dir" "$i" "${i/R1/R2}" "$sample" "../reference/reference.bed" "$Cancer"
	paste <(echo $sample) <(cat $Out_dir/Report/$(echo $sample"_finaloutput.csv") | sed '1d' | awk -F"\t" '{print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$8"\t"$9"\t"$10}' ) >> $Out_dir/Overall_DNA.csv
	cat $Out_dir/Report/$(echo $sample"_overall_coverage.csv") | sed 's/ /\t/g' >> $Out_dir/Overall_coverage_DNA.csv
done

