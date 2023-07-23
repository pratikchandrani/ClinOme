library(stringr)
library(dplyr)
args <- commandArgs(trailingOnly = TRUE)
setwd(args[3])

if(file.info(args[1])$size==0)
{
  final_fusion_data=data.frame("Fusion"="No Clinically Relevant Fusion Found","JunctionReadCount"=" ","SpanningFragmentCount"=" ","US.FDA.approved"=" ","US.FDA.approved.off.label."=" ","ongoing.clinical.trial"=" ","experimental"=" ","US.FDA.Approved"=" ","US.FDA.Approved.Off.Label."=" ","Ongoing.Clinical.Trial "=" ","Experimental"=" " )
  
}else{
  data=read.csv(args[1],header = TRUE,sep="\t")
colnames(data)=c("FusionName","JunctionReadCount","SpanningFragCount")
data=data.frame(data,str_split_fixed(data$FusionName,"--",2))
data$X0 <- paste(data$X1,data$X2,sep="--")
data$X1 <- sub("$","--.",data$X1 )
data$X2 <- sub("$","--.",data$X2 )
data0=data.frame(ID=data$X0,Original_mut=data$FusionName,JunctionReadCount=data$JunctionReadCount,SpanningFragmentCount=data$SpanningFragCount)
data1=data.frame(ID=data$X1,Original_mut=data$FusionName,JunctionReadCount=data$JunctionReadCount,SpanningFragmentCount=data$SpanningFragCount)
data2=data.frame(ID=data$X2,Original_mut=data$FusionName,JunctionReadCount=data$JunctionReadCount,SpanningFragmentCount=data$SpanningFragCount)
data3=data.frame(ID=data$FusionName,Original_mut=data$FusionName,JunctionReadCount=data$JunctionReadCount,SpanningFragmentCount=data$SpanningFragCount)
final_data=rbind(data0,data1,data2,data3)
db=read.csv("../database/ClinOme_Fusion.txt",header = TRUE,sep="\t")
fusion_merge=merge(final_data,db,by="ID")
fusion_merge=fusion_merge[-c(1)]
colnames(fusion_merge)=c("Fusion","JunctionReadCount","SpanningFragmentCount","Cancer","Drug","Response","FDA_Status")

if(is.data.frame(fusion_merge) && nrow(fusion_merge)==0)
{
  final_fusion_data=data.frame("Fusion"="No Clinically Relevant Fusion Found","JunctionReadCount"=" ","SpanningFragmentCount"=" ","US.FDA.approved"=" ","US.FDA.approved.off.label."=" ","ongoing.clinical.trial"=" ","experimental"=" ","US.FDA.Approved"=" ","US.FDA.Approved.Off.Label."=" ","Ongoing.Clinical.Trial "=" ","Experimental"=" " )
  
}else{
  
  cancer=args[2]
  cancer_list=noquote(strsplit(cancer,"/"))[[1]]
  Responsive_data=subset(fusion_merge,fusion_merge$Response == "Responsive")
  Resistant_data=subset(fusion_merge,fusion_merge$Response == "Resistant")
  Responsive_data=Responsive_data[-c(6)]
  Resistant_data=Resistant_data[-c(6)]
  Responsive_data=anti_join(Responsive_data,Resistant_data, by = c("Cancer","Drug"))
  
  
  Resp_1=subset(Responsive_data,is.element(Responsive_data$Cancer,cancer_list)=="TRUE" & Responsive_data$FDA_Status == "Approved",select = c("Fusion","Drug","Cancer"))
  Resp_2=subset(Responsive_data,is.element(Responsive_data$Cancer,cancer_list)=="FALSE" & Responsive_data$FDA_Status == "Approved",select = c("Fusion","Drug","Cancer"))
  Resp_3=subset(Responsive_data,Responsive_data$FDA_Status == "Clinical_trial",select = c("Fusion","Drug","Cancer"))
  Resp_4=subset(Responsive_data,Responsive_data$FDA_Status == "Pre_clinical",select = c("Fusion","Drug","Cancer"))
  
  Resis_1=subset(Resistant_data,is.element(Resistant_data$Cancer,cancer_list)=="TRUE" & Resistant_data$FDA_Status == "Approved" ,select = c("Fusion","Drug","Cancer"))
  Resis_2=subset(Resistant_data,is.element(Resistant_data$Cancer,cancer_list)=="FALSE" & Resistant_data$FDA_Status == "Approved",select = c("Fusion","Drug","Cancer"))
  Resis_3=subset(Resistant_data,Resistant_data$FDA_Status == "Clinical_trial",select = c("Fusion","Drug","Cancer"))
  Resis_4=subset(Resistant_data,Resistant_data$FDA_Status == "Pre_clinical",select = c("Fusion","Drug","Cancer"))  

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
  
  colnames(Resp_1)=c("Fusion","US.FDA.approved")
  colnames(Resp_2)=c("Fusion","US.FDA.approved.off.label.")
  colnames(Resp_3)=c("Fusion","ongoing.clinical.trial")
  colnames(Resp_4)=c("Fusion","experimental")
  colnames(Resis_1)=c("Fusion","US.FDA.Approved")
  colnames(Resis_2)=c("Fusion","US.FDA.Approved.Off.Label.")
  colnames(Resis_3)=c("Fusion","Ongoing.Clinical.Trial ")
  colnames(Resis_4)=c("Fusion","Experimental ")

  fusion_info=data.frame("Fusion"=fusion_merge$Fusion,"JunctionReadCount"=fusion_merge$JunctionReadCount,"SpanningFragmentCount"=fusion_merge$SpanningFragmentCount)
  
  final_fusion_data=distinct(Reduce(function(x, y) merge(x, y, all=TRUE), list(fusion_info,Resp_1,Resp_2,Resp_3,Resp_4,Resis_1,Resis_2,Resis_3,Resis_4)))
  
}
}
setwd(args[3])
write.table(final_fusion_data,"finaloutput.csv",sep="\t",row.names=FALSE)
library(rmarkdown)
library(kableExtra)
render("test3.Rmd", output_format = "html_document", output_file = args[4])
