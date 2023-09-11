#!/usr/bin/env Rscript
library("tidyverse")
args = commandArgs(trailingOnly=TRUE)

coverage=read.table(args[1], sep="\t", header=F)

title= args[2]

# renames the header
coverage=rename(coverage,c("chr"="V1", "pos"="V2", "coverage"="V3"))

# Calculate mean
coverage <- coverage %>% group_by(chr) %>% mutate(mean = mean(coverage))

# Plot historgrams
p1<-ggplot(coverage,aes(x=coverage))+
    geom_histogram(binwidth=1)+
    geom_vline(aes(xintercept = mean, color ="red"))+
    facet_wrap(~chr) +
    ggtitle("Coverage distribution")

ggsave(p1, file= paste(title,".coverage_distribution.pdf",sep=""), width = 30, height = 30, units="cm")

# Plot coverage per position
p2<-ggplot(coverage,aes(x=pos, y=coverage))+
    geom_point()+
    geom_hline(aes(yintercept = mean, color ="red"))+
    facet_wrap(~chr, scales = "free_x") +
    ggtitle("Coverage per position")
ggsave(p2, file= paste(title,".coverage_position.pdf",sep=""), width = 30, height = 30, units="cm")

# Plot boxplot of mean coverage
cov_mean<-coverage%>%group_by(chr)%>%summarise(mean=mean(coverage))
p3<-ggplot(cov_mean, aes(x="",y=mean)) +
    geom_jitter(color=3)+
    geom_boxplot()+
    geom_hline(yintercept=1.5, color ="red")+
    geom_label(y=1.5,label=1.5,color="red")

ggsave(p3, file= paste(title,".mean_coverage.pdf",sep=""),,device="pdf",width=5,height=7)

### LOG files
sink(paste(title, "R_session.log", sep = '.'))
print(sessionInfo())
sink()

### VERSIONS
r.version <- strsplit(version[['version.string']], ' ')[[1]][3]
tidyverse.version <- as.character(packageVersion('tidyverse'))

sink("versions.yml")
cat('PLOTBEDCOVERAGE:',"\n")
cat(paste('    r-base:',r.version),"\n")
cat(paste('    tidyverse:', tidyverse.version ),"\n")
sink()
