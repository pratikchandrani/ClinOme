Raw_fastq_Processing() {
bash pre_QC_report.sh $Raw_fastq_1 $Raw_fastq_2 $Out_Dir  
}

trimmomatic() {
java -jar ../Tools/trimmomatic-0.36.jar PE -threads 10 -phred33 $Raw_fastq_1 $Raw_fastq_2 $Out_Dir/$(echo $sample"_R1_pair.fastq.gz") $Out_Dir/$(echo $sample"_R1_unpair.fastq.gz") $Out_Dir/$(echo $sample"_R2_pair.fastq.gz") $Out_Dir/$(echo $sample"_R2_unpair.fastq.gz") SLIDINGWINDOW:10:15 MINLEN:50
}

Paired_fastq_Processing() {
bash post_QC_report.sh $Out_Dir/$(echo $sample"_R1_pair.fastq.gz") $Out_Dir/$(echo $sample"_R2_pair.fastq.gz") $Out_Dir
} 

BWA() {
../Tools/bwa-0.7.17/bwa mem  -t 10 -R "@RG\tID:$sample\tPL:ILLUMINA\tLB:TruSeq\tSM:$sample\tPI:200" $reference $Out_Dir/$(echo $sample"_R1_pair.fastq.gz") $Out_Dir/$(echo $sample"_R2_pair.fastq.gz") -f $Out_Dir/Intermediatary_files/sam/$(echo $sample".sam")
}

Picard() {
java -Xmx10G -jar ../Tools/picard_2.17.6.jar FixMateInformation I=$Out_Dir/Intermediatary_files/sam/$(echo $sample".sam") o=$Out_Dir/Intermediatary_files/sam/$(echo $sample"_fxd.sam") VALIDATION_STRINGENCY=SILENT TMP_DIR=$Out_Dir/Intermediatary_files/sam/ 

java -Xmx10G -jar ../Tools/picard_2.17.6.jar SamFormatConverter I=$Out_Dir/Intermediatary_files/sam/$(echo $sample"_fxd.sam") o=$Out_Dir/Intermediatary_files/bam/$(echo $sample"_fxd.bam")  VALIDATION_STRINGENCY=SILENT TMP_DIR=$Out_Dir/Intermediatary_files/bam/ 
}

Picard_bam() {
java -Xmx10G -Djava.io.tmpdir=$Out_Dir/Intermediatary_files/bam/temp -jar ../Tools/picard_2.17.6.jar SortSam I=$Out_Dir/Intermediatary_files/bam/$(echo $sample"_fxd.bam")  o=$Out_Dir/Intermediatary_files/bam/$(echo $sample"_fxd_sorted.bam") SORT_ORDER=coordinate VALIDATION_STRINGENCY=SILENT 

java -Xmx10G -Djava.io.tmpdir=$Out_Dir/Intermediatary_files/bam/temp -jar ../Tools/picard_2.17.6.jar MarkDuplicates I=$Out_Dir/Intermediatary_files/bam/$(echo $sample"_fxd_sorted.bam") o=$Out_Dir/Intermediatary_files/bam/$(echo $sample"_fxd_sorted_DupRm.bam") METRICS_FILE=$Out_Dir/Intermediatary_files/bam/$(echo $sample"_fxd_sorted_DupRm_info.txt") REMOVE_DUPLICATES=true ASSUME_SORTED=true VALIDATION_STRINGENCY=SILENT 

java -Xmx10G -Djava.io.tmpdir=$Out_Dir/Intermediatary_files/bam/temp -jar ../Tools/picard_2.17.6.jar BuildBamIndex I=$Out_Dir/Intermediatary_files/bam/$(echo $sample"_fxd_sorted_DupRm.bam")  o=$Out_Dir/Intermediatary_files/bam/$(echo $sample"_fxd_sorted_DupRm.bam.bai") VALIDATION_STRINGENCY=SILENT  
}

GATK() {
java -Xmx10G -jar ../Tools/GenomeAnalysisTK_3.8.1.jar -T RealignerTargetCreator  -nt 10 -R $reference -I $Out_Dir/Intermediatary_files/bam/$(echo $sample"_fxd_sorted_DupRm.bam") -o $Out_Dir/Intermediatary_files/bam/$(echo $sample"_fxd_sorted_DupRm_IndelRealigner.intervals")

java -Xmx10G -jar ../Tools/GenomeAnalysisTK_3.8.1.jar -T IndelRealigner   -R $reference -I $Out_Dir/Intermediatary_files/bam/$(echo $sample"_fxd_sorted_DupRm.bam") -targetIntervals $Out_Dir/Intermediatary_files/bam/$(echo $sample"_fxd_sorted_DupRm_IndelRealigner.intervals") -o $Out_Dir/Intermediatary_files/bam/$(echo $sample"_fxd_sorted_DupRm_realn.bam") -log $Out_Dir/Intermediatary_files/bam/$(echo $sample"_fxd_sorted_DupRm_realn.bam.log") 

java -Xmx10G -jar ../Tools/GenomeAnalysisTK_3.8.1.jar -T BaseRecalibrator  -R $reference -knownSites:dbsnp,VCF ../reference/dbSNP149_GRCh37p13_GATK_common_all_20161121.vcf -I $Out_Dir/Intermediatary_files/bam/$(echo $sample"_fxd_sorted_DupRm_realn.bam") -o  $Out_Dir/Intermediatary_files/bam/$(echo $sample"_fxd_sorted_DupRm_realn_recal.grp") -cov ReadGroupCovariate -cov QualityScoreCovariate -cov CycleCovariate -cov ContextCovariate 

java -Xmx10G -jar ../Tools/GenomeAnalysisTK_3.8.1.jar -T PrintReads  -R $reference -BQSR $Out_Dir/Intermediatary_files/bam/$(echo $sample"_fxd_sorted_DupRm_realn_recal.grp") -I $Out_Dir/Intermediatary_files/bam/$(echo $sample"_fxd_sorted_DupRm_realn.bam") -o $Out_Dir/Output/bam/$(echo $sample"_fxd_sorted_DupRm_realn_recal.bam") -baq RECALCULATE 
}

coverage_cal() {
bash Coverage.sh $Out_Dir $Out_Dir/Output/bam/$(echo $sample"_fxd_sorted_DupRm_realn_recal.bam") "$cancer_query" $sample 
}

Unified_Genotyper() {
java -Djava.io.tmpdir=$Out_Dir/Output/temp -jar ../Tools/GenomeAnalysisTK_3.8.1.jar -T UnifiedGenotyper  -R $reference -I $Out_Dir/Output/bam/$(echo $sample"_fxd_sorted_DupRm_realn_recal.bam") -o $Out_Dir/Output/vcf/$(echo $sample"_fxd_sorted_DupRm_realn_recal_UG.vcf") --genotype_likelihoods_model BOTH --annotateNDA -l INFO -log $Out_Dir/Output/vcf/$(echo $sample"_fxd_sorted_DupRm_realn_recal_UG.log") -L $bed_file

java -jar ../Tools/GenomeAnalysisTK_3.8.1.jar -T VariantsToAllelicPrimitives -R $reference -V $Out_Dir/Output/vcf/$(echo $sample"_fxd_sorted_DupRm_realn_recal_UG.vcf") -o $Out_Dir/Output/vcf/$(echo $sample"_fxd_sorted_DupRm_realn_recal_mordified_UG.vcf")

java -jar ../Tools/GenomeAnalysisTK_3.8.1.jar -T VariantsToTable -R $reference -V $Out_Dir/Output/vcf/$(echo $sample"_fxd_sorted_DupRm_realn_recal_mordified_UG.vcf") -o $Out_Dir/Output/vcf/$(echo $sample"_fxd_sorted_DupRm_realn_recal_mordified_UG.table") --splitMultiAllelic --showFiltered -F CHROM -F POS -F REF -F ALT -GF AD

}

Mutect() {
java -jar ../Tools/GenomeAnalysisTK_3.8.1.jar -T MuTect2 -R $reference -I:tumor $Out_Dir/Output/bam/$(echo $sample"_fxd_sorted_DupRm_realn_recal.bam") --dbsnp ../reference/dbSNP149_GRCh37p13_GATK_common_all_20161121.vcf --cosmic ../reference/CosmicCodingMutsSortd_79.vcf -o $Out_Dir/Output/vcf/$(echo $sample"_fxd_sorted_DupRm_realn_recal_mutect.vcf") -L $bed_file --maxReadsInRegionPerSample 90000

java -jar ../Tools/GenomeAnalysisTK_3.8.1.jar -T VariantsToAllelicPrimitives -R $reference -V $Out_Dir/Output/vcf/$(echo $sample"_fxd_sorted_DupRm_realn_recal_mutect.vcf") -o $Out_Dir/Output/vcf/$(echo $sample"_fxd_sorted_DupRm_realn_recal_mordified_mutect.vcf")

java -jar ../Tools/GenomeAnalysisTK_3.8.1.jar -T VariantsToTable -R $reference -V $Out_Dir/Output/vcf/$(echo $sample"_fxd_sorted_DupRm_realn_recal_mordified_mutect.vcf") -o $Out_Dir/Output/vcf/$(echo $sample"_fxd_sorted_DupRm_realn_recal_mordified_mutect.table") --splitMultiAllelic --showFiltered -F CHROM -F POS -F REF -F ALT -GF AD

}

dv() {
awk -F"\t" '{print $1"\t"$2"\t"$3}' $bed_file > $Out_Dir/Output/bam/3columns.bed 

export INPUT_DIR="$Out_Dir/Output/bam/"
export OUTPUT_DIR="$Out_Dir/Output/vcf/"
export Ref_DIR="$(dirname $reference)"
BIN_VERSION="0.8.0"
ref_file=$(basename $reference)
echo "input dir $INPUT_DIR"
echo "output dir $OUTPUT_DIR"
echo "ref dir $Ref_DIR"
echo "ref file $ref_file"

docker run -v "${INPUT_DIR}":"/input" -v "${OUTPUT_DIR}:/output" -v "${Ref_DIR}:/reference" gcr.io/deepvariant-docker/deepvariant:"${BIN_VERSION}" /opt/deepvariant/bin/run_deepvariant --model_type=WES --ref=/reference/$ref_file --reads=/input/$(echo $sample"_fxd_sorted_DupRm_realn_recal.bam") --regions /input/3columns.bed --output_vcf=/output/$(echo $sample"_fxd_sorted_DupRm_realn_recal_dv.vcf") --num_shards=8

java -jar ../Tools/GenomeAnalysisTK_3.8.1.jar -T VariantsToAllelicPrimitives -R $reference -V $Out_Dir/Output/vcf/$(echo $sample"_fxd_sorted_DupRm_realn_recal_dv.vcf") -o $Out_Dir/Output/vcf/$(echo $sample"_fxd_sorted_DupRm_realn_recal_mordified_dv.vcf")

java -jar ../Tools/GenomeAnalysisTK_3.8.1.jar -T VariantsToTable -R $reference -V $Out_Dir/Output/vcf/$(echo $sample"_fxd_sorted_DupRm_realn_recal_mordified_dv.vcf") -o $Out_Dir/Output/vcf/$(echo $sample"_fxd_sorted_DupRm_realn_recal_mordified_dv.table") --splitMultiAllelic --showFiltered -F CHROM -F POS -F REF -F ALT -GF AD


}

varscan() {

../Tools/samtools-1.7/samtools mpileup -q 1 -f $reference $Out_Dir/Output/bam/$(echo $sample"_fxd_sorted_DupRm_realn_recal.bam") | java -jar ../Tools/VarScan.v2.4.3.jar mpileup2cns --output-vcf 1 --variants - > $Out_Dir/Output/vcf/$(echo $sample"_fxd_sorted_DupRm_realn_recal_varscan.vcf")

java -jar ../Tools/GenomeAnalysisTK_3.8.1.jar -T VariantsToAllelicPrimitives -R $reference -V $Out_Dir/Output/vcf/$(echo $sample"_fxd_sorted_DupRm_realn_recal_varscan.vcf") -o $Out_Dir/Output/vcf/$(echo $sample"_fxd_sorted_DupRm_realn_recal_mordified_varscan.vcf")

java -jar ../Tools/GenomeAnalysisTK_3.8.1.jar -T VariantsToTable -R $reference -V $Out_Dir/Output/vcf/$(echo $sample"_fxd_sorted_DupRm_realn_recal_mordified_varscan.vcf") -o $Out_Dir/Output/vcf/$(echo $sample"_fxd_sorted_DupRm_realn_recal_mordified_varscan.table") --splitMultiAllelic --showFiltered -F CHROM -F POS -F REF -F ALT -GF RD -GF AD


}


Post_vcf_Processing() {

java -jar ../Tools/GenomeAnalysisTK_3.8.1.jar -T VariantsToTable -R $reference -V $Out_Dir/Output/vcf/$(echo $sample"_fxd_sorted_DupRm_realn_recal_mordified_UG.vcf") -o $Out_Dir/Output/vcf/$(echo $sample"_fxd_sorted_DupRm_realn_recal_mordified_UG.table") --splitMultiAllelic --showFiltered -F CHROM -F POS -F REF -F ALT -GF AD

sed 's/,/\t/g' $Out_Dir/Output/vcf/$sample*_mordified*.table | grep -v "^CHROM" | awk '($6>0) && ($5+$6)>0 {print $1"_"$2"_"$3"_"$4"\t"$5+$6"\t"$6/($5+$6)}' | sed 's/ /\t/g' | sort -k1,1 -k2,2nr |  awk '!($1 in a){a[$1]; print}' > $Out_Dir/Report/$(echo $sample"_temp.txt")
 	
awk 'NR==FNR { n[$1]=$0;next } ($1 in n) { print n[$1],$2,$3 }' ../database/New_gene_mut_ref.txt $Out_Dir/Report/$(echo $sample"_temp.txt") | awk '{print $2"\t"$3"\t"$4}' > $Out_Dir/Report/$(echo $sample"_format.vcf.txt")

sed 's/ /\t/g' $Out_Dir/Report/$(echo $sample"_gene_read_avg.coverage.txt") > ../markdown/gene.csv
cp $Out_Dir/sample_info.csv ../markdown
sed 's/ /\t/g' $Out_Dir/Report/$(echo $sample"_overall_coverage.csv") > ../markdown/overall_coverage.csv
#python cancer_string.py "$cancer_query" >> $Out_Dir/Report/Cancer_path.txt 
cancer=(cut -f2 $Out_Dir/Report/Cancer_path.txt)
echo $cancer
dir=$(pwd | sed 's/Code/markdown/g')
Rscript ../markdown/dna_Final_pdf_generation.R "$Out_Dir/Report/$(echo $sample"_format.vcf.txt")" "$cancer" "$dir" "$Out_Dir/Report/$(echo $sample"_Final.html")"
cp ../markdown/finaloutput.csv $Out_Dir/Report/$(echo $sample"_finaloutput.csv")
rm $dir/*.csv
} 

Out_Dir=$1
#Raw_fastq_1=$2
Raw_fastq_2=$3
VCF_file=$2
sample=$4
bed_file=$5
cancer_query=$6
ref_dir="../reference/"
reference=$ref_dir/reference.fasta
#echo $reference

echo "$sample	$cancer_query" > $Out_Dir/sample_info.csv
#mkdir -p $Out_Dir/{Intermediatary_files/{sam,bam},Output/{bam,vcf},Report}

mkdir -p $Out_Dir/{Output/{bam,vcf},Report}

date >> $Out_Dir/time.log
 # Raw_fastq_Processing trimmomatic Paired_fastq_Processing  BWA Picard Picard_bam GATK Unified_Genotyper Mutect varscan dv varscan coverage_cal
for i in Post_vcf_Processing
#
do
	echo "Start" $i date >> $Out_Dir/time.log
	$i
	echo "End" $i date >> $Out_Dir/time.log

done
date >> $Out_Dir/time.log

