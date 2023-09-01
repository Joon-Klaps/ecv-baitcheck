#!/usr/bin/env Rscript

args = commandArgs(trailingOnly=TRUE)

library("tidyverse")

text=read_file(args[1])
title = args[2]
# remove the wierd text annotation of some columns
text_modified=gsub("\t#[a-zA-Z \\-\\+\\/\\(\\)\\=0]+\t","\t", text, perl=TRUE)

df=read.table(text=text_modified, header=FALSE, sep="\t")

# Remove those values that are the same across all
df_unique<-df%>%group_by(V1,V2)%>%filter(n()!=length(unique(df$V4)))%>%ungroup()

df_wide=pivot_wider(df,names_from="V1",values_from="V2")

# Include factors so that all texts are close to each other
V4_levels <-df_unique%>%arrange(V3)%>%select(V4)%>%unlist()%>%as.character()%>%unique()
df_unique$V4<-factor(df_unique$V4, levels=V4_levels)

# plotting it
ggplot(df_unique, aes(x=V4,y=V2,fill=as.factor(V3)))+
    geom_bar(position = "dodge", stat = "identity")+
    facet_wrap(~V1,scales="free")+
    scale_fill_brewer(name = "Lineage", palette="Set3")+
    ggtitle(paste(title))+
    theme(plot.title = element_text(hjust = 0.5),
        axis.title.y=element_blank(),
        axis.title.x=element_blank(),
        axis.text.x=element_blank())
ggsave(paste(title,"./sam_summary.",".pdf",sep=""), width = 20, height = 17, units="cm")

# storign the other table as well
write.table(df_wide,file = paste(title,"./sam_summary."".tsv",sep=""), sep="\t", row.names=FALSE, quote=FALSE)

writeLines(
    c(
        '"${task.process}":',
        paste('    r-base:'   ,r.version        ),
        paste('    tidyverse:',tidyverse.version),
    ),
    'versions.yml')

