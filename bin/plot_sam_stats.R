#!/usr/bin/env Rscript

args = commandArgs(trailingOnly=TRUE)

library("tidyverse")

text=read_file(args[1])
title = args[2]

# stat_name, stat_value, sample_id, lineage
df=read.table(text=text, header=FALSE, sep="\t", col.names=c("stat_name", "stat_value", "sample_id", "lineage"))

# Remove those values that are the same across all
df_unique<-df%>%
    group_by(stat_name,stat_value)%>%
    filter(n()!=length(unique(df$sample_id)))%>% # number of members in combination is different from the unique number of sample_ids
    ungroup()

# Include factors so that all lineage are position adjecent
lineage_levels <-df_unique%>%arrange(lineage)%>%select(sample_id)%>%unlist()%>%as.character()%>%unique()
df_unique$sample_id<-factor(df_unique$sample_id, levels=lineage_levels)

# Get a color amount that is the same as the number of lineages
n_lin<-length(unique(df$lineage))
color <- grDevices::colors()[grep("gr(a|e)y", grDevices::colors(), invert = T)]

# plotting it
ggplot(df_unique, aes(x=sample_id,y=stat_value,fill=as.factor(lineage)))+
    geom_bar(position = "dodge", stat = "identity")+
    facet_wrap(~stat_name,scales="free")+
    scale_fill_manual(name = "Lineage", values = sample(color, n_lin))+
    ggtitle(paste(title))+
    theme(plot.title = element_text(hjust = 0.5),
        axis.title.y=element_blank(),
        axis.title.x=element_blank(),
        axis.text.x=element_blank())
ggsave(paste(title,"_sam_summary",".pdf",sep=""), width = 20, height = 17, units="cm")

# Storing a summary table as well (can also be gotten from multiqc)
df_wide=pivot_wider(df,names_from="stat_name",values_from="stat_value")
write.table(df_wide,file = paste(title,"_sam_summary.","tsv",sep=""), sep="\t", row.names=FALSE, quote=FALSE)

### VERSIONS
r.version <- strsplit(version[['version.string']], ' ')[[1]][3]
tidyverse.version <- as.character(packageVersion('tidyverse'))

sink("versions.yml")
cat('PLOTSAMTOOLSSTATS:',"\n")
cat(paste('    r-base:',r.version),"\n")
cat(paste('    tidyverse:', tidyverse.version ),"\n")
sink()
