Raw_fastq_Processing() {
bash pre_QC_report.sh $Raw_fastq_1 $Raw_fastq_2 $Out_Dir  
}

trimmomatic() {
java -jar ../Tools/trimmomatic-0.36.jar PE -threads 4 -phred33 $Raw_fastq_1 $Raw_fastq_2 $Out_Dir/$(echo $sample"_R1_pair.fastq.gz") $Out_Dir/$(echo $sample"_R1_unpair.fastq.gz") $Out_Dir/$(echo $sample"_R2_pair.fastq.gz") $Out_Dir/$(echo $sample"_R2_unpair.fastq.gz") SLIDINGWINDOW:10:15 MINLEN:50
}

Paired_fastq_Processing() {
bash post_QC_report.sh $Out_Dir/$(echo $sample"_R1_pair.fastq.gz") $Out_Dir/$(echo $sample"_R2_pair.fastq.gz") $Out_Dir
} 

star_align() {
../Tools/STAR --genomeDir ../reference/ctat_genome_lib_build_dir/ref_genome.fa.star.idx  --outReadsUnmapped None  --chimSegmentMin 12  --chimJunctionOverhangMin 12  --chimOutJunctionFormat 1  --alignSJDBoverhangMin 10  --alignMatesGapMax 100000  --alignIntronMax 100000  --alignSJstitchMismatchNmax 5 -1 5 5  --runThreadN 10 --outSAMstrandField intronMotif  --outSAMunmapped Within  --outSAMtype BAM Unsorted  --readFilesIn $Out_Dir/$(echo $sample"_R1_pair.fastq.gz") $Out_Dir/$(echo $sample"_R2_pair.fastq.gz") --outSAMattributes All --chimMultimapScoreRange 10 --chimMultimapNmax 10 --chimNonchimScoreDropMin 10  --peOverlapNbasesMin 12 --peOverlapMMp 0.1  --genomeLoad NoSharedMemory  --twopassMode Basic  --readFilesCommand 'gunzip -c' --outFileNamePrefix $Out_Dir/Star/$(echo $sample"_Star")/Star
}

star_fusion() {
../Tools/STAR-Fusion-v1.5.0/STAR-Fusion --genome_lib_dir ../reference/ctat_genome_lib_build_dir --output_dir $Out_Dir/Star/$(echo $sample"_Star") --CPU 18 --J $Out_Dir/Star/$(echo $sample"_Star")/StarChimeric.out.junction
}

coverage_cal() {
bash Coverage.sh $Out_Dir $Out_Dir/Star/$(echo $sample"_Star")/StarAligned.out.bam "$cancer_query" $sample 
}

Output_generation() {
if [ -f $Out_Dir/Star/$(echo $sample"_Star")/star-fusion.fusion_predictions.tsv ]
then
	awk -F"\t" '($2>2){print $1"\t"$2"\t"$3}' $Out_Dir/Star/$(echo $sample"_Star")/star-fusion.fusion_predictions.tsv | sort -u | grep -v "^#" > $Out_Dir/Report/$(echo $sample"_filtered.txt")
else
	touch $Out_Dir/Report/$(echo $sample"_filtered.txt")
fi
sed 's/ /\t/g' $Out_Dir/Report/$(echo $sample"_gene_read_avg.coverage.txt") > ../markdown/gene.csv
cp $Out_Dir/sample_info.csv ../markdown
sed 's/ /\t/g' $Out_Dir/Report/$(echo $sample"_overall_coverage.csv") > ../markdown/overall_coverage.csv
echo $cancer_query
cancer=$(python cancer_string.py "$cancer_query" | sed 's/ \t/\t/g' | sed 's/ /_/g' | awk -F"\t" '{print $2}' )
echo $cancer
dir=$(pwd | sed 's/Code/markdown/g')
Rscript ../markdown/rna_Final_pdf_generation.R $Out_Dir/Report/$(echo $sample"_filtered.txt") $cancer $dir $Out_Dir/Report/$(echo $sample"_Final.html")
cp ../markdown/finaloutput.csv $Out_Dir/Report/$(echo $sample"_finaloutput.csv")
rm $dir/*.csv
}


Out_Dir=$1
Raw_fastq_1=$2
Raw_fastq_2=$3
sample=$4
cancer_query=$5
date >> $Out_Dir/time.log 
mkdir -p $Out_Dir/{Report,Star/$(echo $sample"_Star")}

echo "$sample	$cancer_query" > $Out_Dir/sample_info.csv
#  		      
for i in Raw_fastq_Processing trimmomatic Paired_fastq_Processing star_align coverage_cal star_fusion coverage_cal Output_generation
do
	echo "Start" $i date >> $Out_Dir/time.log 
	$i 
	echo "End" $i date >> $Out_Dir/time.log 
done
date >> $Out_Dir/time.log 

