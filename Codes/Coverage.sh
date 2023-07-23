Out_Dir=$1
bam_file=$2 
cancer=$3
sample=$4

mkdir -p $Out_Dir/Coverage/temp

if [ "$cancer" == "Any_Cancer" ];
then 
	cancer=""
fi

echo -e "Sample	Pathogen	TPM	Clinical_Trial_ID" > $Out_Dir/Report/$(echo $sample"_Overall_Pathogen.xls")

../Tools/bedtools coverage -counts -b $bam_file -a ../reference/reference.bed > $Out_Dir/Coverage/temp/$(echo $sample".Coverage")
	
awk -F"\t" 'length($1)<3 {print $0}' $Out_Dir/Coverage/temp/$(echo $sample".Coverage") > $Out_Dir/Coverage/temp/$(echo $sample"_gene.coverage.txt")
	
awk '{print $1"\t"$4"\t"($7 / ($3 - $2)) * 1000 }' $Out_Dir/Coverage/temp/$(echo $sample".Coverage") > $Out_Dir/Coverage/temp/$(echo $sample"_temp.coverage.txt")
	
Scaling_factor=$(awk -F"\t" '{ sum+=$3} END {print sum / 1000000 }' $Out_Dir/Coverage/temp/$(echo $sample"_temp.coverage.txt"))

awk -v x="$Scaling_factor" '($3>0){print $1"\t"$2"\t" $3/x }' $Out_Dir/Coverage/temp/$(echo $sample"_temp.coverage.txt") > $Out_Dir/Coverage/temp/$(echo $sample"_RPM.coverage.txt")
	
awk -F"\t" 'length($1)>2 {print $0}' $Out_Dir/Coverage/temp/$(echo $sample"_RPM.coverage.txt") > $Out_Dir/Coverage/$(echo $sample"_pathogen_RPM.coverage.txt")
	
if [[ -s $Out_Dir/Coverage/$(echo $sample"_pathogen_RPM.coverage.txt") ]]
then 
	while read Pathogens
	do
		path=$(echo $Pathogens | awk '{print $2}')
		grep "$path" ../database/ClinOme_database_clinicaltrials.txt | grep "$cancer" | awk '{print $1}' > temp.txt
		paste <(echo $Pathogens | awk '{print $1}') <(echo $Pathogens | awk '{print $3}') <(cat temp.txt) >> $Out_Dir/Coverage/temp/Final_temp.txt
	done < $Out_Dir/Coverage/$(echo $sample"_pathogen_RPM.coverage.txt")
		paste <(echo $sample) <(cat $Out_Dir/Coverage/temp/Final_temp.txt) >> $Out_Dir/Report/$(echo $sample"_Overall_Pathogen.xls")
		rm *.txt
else
	paste <(echo $sample) <(echo "No Pathogen Found") >> $Out_Dir/Report/Overall_Pathogen.xls
fi

awk -F"\t" '{print $4}' $Out_Dir/Coverage/temp/$(echo $sample"_gene.coverage.txt") | uniq -c | awk '{print $2"\t"$1}' > $Out_Dir/Coverage/temp/gene.txt
total=$(wc -l $Out_Dir/Coverage/temp/gene.txt | awk '{print $1}')
echo -e "Gene	Read Count" > $Out_Dir/Report/$(echo $sample"_gene_read_avg.coverage.txt")
while read genes
do
	gene_count=$(echo $genes | awk '{print $2}')
	gene_name=$(echo $genes | awk '{print $1}')
	gene_avg=$(grep "$gene_name" $Out_Dir/Coverage/temp/$(echo $sample"_gene.coverage.txt") | awk -v x="$gene_count" '{ sum+=$7} END {print sum /x }')
	echo $gene_name	$gene_avg >> $Out_Dir/Report/$(echo $sample"_gene_read_avg.coverage.txt")
done < $Out_Dir/Coverage/temp/gene.txt

Overall_avg=$(awk -v x="$total" '{ sum+=$2} END {print sum /x }' $Out_Dir/Report/$(echo $sample"_gene_read_avg.coverage.txt"))		
echo $sample	$Overall_avg > $Out_Dir/Report/$(echo $sample"_overall_coverage.csv")

