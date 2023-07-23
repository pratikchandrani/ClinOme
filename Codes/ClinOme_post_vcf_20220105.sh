#Run this script as follows
#sudo pip3 install nltk
#sudo pip3 install nltk.corpus
#sudo pip3 install fuzzywuzzy
#python
#import nltk
#nltk.download('stopwords')
#nltk.download('punkt')
#In_Dir="/mnt/e/My_Work/ClinOme_WaterHose/TechTransfer_4baseCare/ClinOme_4baseCare/"
#VCF_file="EA256_S1_all.vcf"
#sample="sample1"
#cancer_query="Lung adenocarcinoma"
#ref_dir="../reference"
#reference=$ref_dir/reference.fasta
#bash ClinOme_post_vcf.sh full_path_output_directory input_vcf_file sample_name cancer_type

Post_vcf_Processing() {

java -jar ../Tools/GenomeAnalysisTK_3.8.1.jar -T VariantsToAllelicPrimitives -R $reference -V $In_Dir/$VCF_file -o $In_Dir/$(echo $VCF_file"_mordified.vcf")

java -jar ../Tools/GenomeAnalysisTK_3.8.1.jar -T VariantsToTable -R $reference -V $In_Dir/$(echo $VCF_file"_mordified.vcf") -o $In_Dir/$(echo $VCF_file"_mordified.table") --splitMultiAllelic --showFiltered -F CHROM -F POS -F REF -F ALT -GF AD

sed 's/,/\t/g' $In_Dir/$VCF_file*_mordified*.table | grep -v "^CHROM" | awk '($6>0) && ($5+$6)>0 {print $1"_"$2"_"$3"_"$4"\t"$5+$6"\t"$6/($5+$6)}' | sed 's/ /\t/g' | sort -k1,1 -k2,2nr |  awk '!($1 in a){a[$1]; print}' > $In_Dir/$(echo $VCF_file"_temp.txt")

awk 'NR==FNR { n[$1]=$0;next } ($1 in n) { print n[$1],$2,$3 }' ../database/New_gene_mut_ref.txt $In_Dir/$(echo $VCF_file"_temp.txt") | awk '{print $2"\t"$3"\t"$4}' > $In_Dir/$(echo $VCF_file"_format.vcf.txt")

python cancer_string.py "$cancer_query" >> $In_Dir/Cancer_path.txt 
cancer=$(cut -f2 $In_Dir/Cancer_path.txt)
echo $cancer
dir=$(pwd | sed 's/Codes/markdown/g')
Rscript ../markdown/dna_Final_pdf_generation.R "$In_Dir/$(echo $VCF_file"_format.vcf.txt")" "$cancer" "$dir" "$In_Dir/$(echo $VCF_file"_Final.html")"
cp ../markdown/finaloutput.csv $In_Dir/$(echo $VCF_file"_finaloutput.csv")
rm $dir/*.csv
} 

In_Dir=$1
VCF_file=$2
sample=$3
cancer_query=$4
ref_dir="../reference"
reference=$ref_dir/reference.fasta
echo "using reference file "$reference

#echo "$sample	$cancer_query" > $In_Dir/sample_info.csv

mkdir -p $In_Dir/Report

date >> $In_Dir/time.log
 # Raw_fastq_Processing trimmomatic Paired_fastq_Processing  BWA Picard Picard_bam GATK Unified_Genotyper Mutect varscan dv varscan coverage_cal
for i in Post_vcf_Processing
#
do
	echo "Start" $i date >> $In_Dir/time.log
	$i
	echo "End" $i date >> $In_Dir/time.log

done
date >> $In_Dir/time.log
