#!/usr/bin/env Rscript
library("dplyr")
library("ggrepel")
args = commandArgs(trailingOnly=TRUE)

coverage=read.table(args[1], sep="\t", header=F)

title= args[2]

# renames the header
coverage=rename(coverage,c("chr"="V1", "pos"="V2", "coverage"="V3"))

# Calculate mean
coverage <- coverage %>% group_by(chr) %>% mutate(mean = mean(coverage))

# Plot histograms
p1 <- ggplot(coverage, aes(x = coverage)) +
    geom_histogram(binwidth = 1) +
    geom_vline(aes(xintercept = mean, color = "Mean")) +
    scale_color_manual(values = c("Mean" = "red")) +
    facet_wrap(~chr) +
    ggtitle("Coverage distribution")

ggsave(p1, file = paste(title, ".coverage_distribution.pdf", sep = ""), width = 30, height = 30, units = "cm")

# Plot coverage per position
p2 <- ggplot(coverage, aes(x = pos, y = coverage)) +
    geom_point() +
    geom_hline(aes(yintercept = mean, color = "Mean")) +
    scale_color_manual(values = c("Mean" = "red")) +
    facet_wrap(~chr, scales = "free_x") +
    ggtitle("Coverage per position")

ggsave(p2, file = paste(title, ".coverage_position.pdf", sep = ""), width = 30, height = 30, units = "cm")

# Plot boxplot of mean coverage
cov_mean <- coverage %>% group_by(chr) %>% summarise(mean = mean(coverage))
plot_data <- cov_mean %>%
    mutate(
      x = jitter(rep(1, n()), amount = 0.3),  # Create jittered x positions
      below_threshold = mean < 1.5
    )

  p3 <- ggplot(plot_data, aes(x = x, y = mean)) +
    geom_point(aes(color = below_threshold)) +
    geom_boxplot(aes(x = 1), width = 0.5, alpha = 0.5, outlier.shape = NA) +
    geom_hline(aes(yintercept = 1.5, linetype = "Threshold"), color = "red") +
    geom_text_repel(
      data = subset(plot_data, below_threshold),
      aes(label = paste(chr, round(mean,2), sep=": ")),
      size = 3,
      box.padding = 0.5,
      point.padding = 0.5,
      force = 2
    ) +
    scale_color_manual(
      values = c("TRUE" = "red", "FALSE" = "blue"),
      labels = c("TRUE" = "Below Threshold", "FALSE" = "Above Threshold"),
      name = "Coverage Status"
    ) +
    scale_linetype_manual(values = c("Threshold" = "dashed")) +
    scale_x_continuous(breaks = 1, labels = "") +  # Remove x-axis label
    labs(
      title = "Mean Coverage Boxplot",
      y = "Mean Coverage",
      linetype = ""
    ) +
    theme_minimal() +
    theme(legend.position = "bottom")

ggsave(p3, file = paste(title, ".mean_coverage.pdf", sep = ""), device = "pdf", width = 5, height = 7)
### LOG files
sink(paste(title, "R_session.log", sep = '.'))
print(sessionInfo())
sink()

### VERSIONS
r.version <- strsplit(version[['version.string']], ' ')[[1]][3]
dplyr.version <- as.character(packageVersion('dplyr'))
ggrepel.version <- as.character(packageVersion('ggrepel'))

sink("versions.yml")
cat('PLOTBEDCOVERAGE:',"\n")
cat(paste('    r-base:',r.version),"\n")
cat(paste('    dplyr:', dplyr.version ),"\n")
cat(paste('    ggrepel:', ggrepel.version ),"\n")
sink()
