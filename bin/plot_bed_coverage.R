#!/usr/bin/env Rscript
library("tidyverse")
args = commandArgs(trailingOnly=TRUE)

coverage=read.table(args[1], sep="\t", header=F)

title= args[2]

# renames the header
coverage=rename(coverage,c("Chr"="V1", "locus"="V2", "depth"="V3"))

p1<-ggplot(coverage, aes(x=locus, y=depth)) +
    geom_point(colour="red", size=1, shape=20, alpha=1/3) +
    scale_y_continuous(trans = scales::log10_trans(), breaks = scales::trans_breaks("log10", function(x) 10^x))+
    ggtitle("Genome-wide coverage")

p2<-ggplot(coverage, aes(x= depth)) +
    geom_histogram(binwidth=1)+
    ggtitle("Coverage distribution")

plot<- ggarrange(p1, p2, ncol = 2, nrow = 1, )
ggsave(plot, file= paste(title,".pdf",sep=""), width = 20, height = 10, units="cm")

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
