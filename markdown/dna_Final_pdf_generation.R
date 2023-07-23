# Install from CRAN
#install.packages('rmarkdown')
#install.packages('devtools')
#sudo dnf install libxml2-devel (on terminal) [for fedora]
#sudo apt install libxml2-dev (on terminal) [for ubuntu]
#library(devtools)
#devtools::install_github("r-lib/xml2")
#install.packages("kableExtra")
#install.packages("htmlTable")

library(dplyr)
#args <- commandArgs(trailingOnly = TRUE)
args <- c("/mnt/e/My_Work/ClinOme_WaterHose/TechTransfer_4baseCare/ClinOme_4baseCare/EA256_S1_all.vcf_format.vcf.txt", "Any cancer/Solid tumor/Lung Cancer/Non-Small Cell Lung Cancer/Lung Adenocarcinoma", "/mnt/e/My_Work/ClinOme_WaterHose/TechTransfer_4baseCare/ClinOme_4baseCare/markdown", "/mnt/e/My_Work/ClinOme_WaterHose/TechTransfer_4baseCare/ClinOme_4baseCare/EA256_S1_all.vcf_Final.html")
setwd(args[3])
db=read.csv("../database/Clinome_database.txt",sep="\t",header = FALSE)
if (file.size(args[1]) > 0){
  snp_info=read.table(args[1])
  merge_snp_db=merge(snp_info,db,by="V1")
  colnames(merge_snp_db)=c("SNP","DP","AF","Cancer","Drug","Response","FDA_Status")
  cancer=args[2]
  cancer <- gsub(' ', '_', cancer)
  Responsive_data=subset(merge_snp_db,merge_snp_db$Response == "Responsive")
  Resistant_data=subset(merge_snp_db,merge_snp_db$Response == "Resistant")
  Responsive_data=Responsive_data[-c(6)]
  Resistant_data=Resistant_data[-c(6)]
  Responsive_data=anti_join(Responsive_data,Resistant_data, by = c("Cancer","Drug"))
  
  cancer_path=strsplit(as.character(cancer),"/")
  query=Responsive_data[, "Cancer"]
  
  Resp_1=subset(Responsive_data,is.element(query,cancer_path[[1]])=="TRUE" & Responsive_data$FDA_Status == "Approved",select = c("SNP","Drug","Cancer"))
  Resp_2=subset(Responsive_data,is.element(query,cancer_path[[1]])=="FALSE" & Responsive_data$FDA_Status == "Approved",select = c("SNP","Drug","Cancer"))
  Resp_3=subset(Responsive_data,Responsive_data$FDA_Status == "Clinical_trial",select = c("SNP","Drug","Cancer"))
  Resp_4=subset(Responsive_data,Responsive_data$FDA_Status == "Pre_clinical",select = c("SNP","Drug","Cancer"))
  
  cancer_path_2=strsplit(as.character(cancer),"/")
  query_2=Resistant_data[, "Cancer"]
  Resis_1=subset(Resistant_data,is.element(query_2,cancer_path_2[[1]])=="TRUE" & Resistant_data$FDA_Status == "Approved" ,select = c("SNP","Drug","Cancer"))
  Resis_2=subset(Resistant_data,is.element(query_2,cancer_path_2[[1]])=="FALSE" & Resistant_data$FDA_Status == "Approved",select = c("SNP","Drug","Cancer"))
  Resis_3=subset(Resistant_data,Resistant_data$FDA_Status == "Clinical_trial",select = c("SNP","Drug","Cancer"))
  Resis_4=subset(Resistant_data,Resistant_data$FDA_Status == "Pre_clinical",select = c("SNP","Drug","Cancer"))
  
  if (nrow(Resp_1)>0){
    Resp_1$Drug=paste(Resp_1$Drug,"(",Resp_1$Cancer,")")
  }
  if (nrow(Resp_2)>0){
    Resp_2$Drug=paste(Resp_2$Drug,"(",Resp_2$Cancer,")")
  }
  if (nrow(Resp_3)>0){
    Resp_3$Drug=paste(Resp_3$Drug,"(",Resp_3$Cancer,")")
  }
  if (nrow(Resp_4)>0){
    Resp_4$Drug=paste(Resp_4$Drug,"(",Resp_4$Cancer,")")
  }
  if (nrow(Resis_1)>0){
    Resis_1$Drug=paste(Resis_1$Drug,"(",Resis_1$Cancer,")")
  }
  if (nrow(Resis_2)>0){
    Resis_2$Drug=paste(Resis_2$Drug,"(",Resis_2$Cancer,")")
  }
  if (nrow(Resis_3)>0){
    Resis_3$Drug=paste(Resis_3$Drug,"(",Resis_3$Cancer,")")
  }
  if (nrow(Resis_4)>0){
    Resis_4$Drug=paste(Resis_4$Drug,"(",Resis_4$Cancer,")")
  }
  
  Resp_1=Resp_1[-c(3)]
  Resp_2=Resp_2[-c(3)]
  Resp_3=Resp_3[-c(3)]
  Resp_4=Resp_4[-c(3)]
  
  Resis_1=Resis_1[-c(3)]
  Resis_2=Resis_2[-c(3)]
  Resis_3=Resis_3[-c(3)]
  Resis_4=Resis_4[-c(3)]
  
  colnames(Resp_1)=c("SNP","US.FDA.approved")
  colnames(Resp_2)=c("SNP","US.FDA.approved.off.label.")
  colnames(Resp_3)=c("SNP","Ongoing.Clinical.trial")
  colnames(Resp_4)=c("SNP","Experimental")

  colnames(Resis_1)=c("SNP","US.FDA.Approved")
  colnames(Resis_2)=c("SNP","US.FDA.Approved.Off.Label.")
  colnames(Resis_3)=c("SNP","Ongoing.Clinical.Trial ")
  colnames(Resis_4)=c("SNP","Experimental ")
  colnames(snp_info)=c("SNP","DP","AF")
  
  data=distinct(Reduce(function(x, y) merge(x, y, all=TRUE), list(snp_info,Resp_1,Resp_2,Resp_3,Resp_4,Resis_1,Resis_2,Resis_3,Resis_4)))  
}else{
 data=data.frame("SNP"="No Clinically Relevant Mutations Found","DP"=" ","AF"=" ","US.FDA.approved"=" ","US.FDA.approved.off.label."=" ","Ongoing.Clinical.trial"=" ","Experimental"="","US.FDA.Approved"=" ","US.FDA.Approved.Off.Label."=" ","Ongoing.Clinical.Trial "=" ","Experimental"=" ")
 
}
write.table(data,"finaloutput.csv",sep="\t",row.names=FALSE)
library(rmarkdown)
library(kableExtra)
render("test3.Rmd", output_format = "html_document", output_file = args[4])


