rm(list = ls())
# R 4.3.1.
suppressPackageStartupMessages(library(vegan))

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 3) {
  stop("Usage: Rscript 02_procrustes_analysis.R PROFILE1_TSV PROFILE2_TSV OUTPUT_PREFIX [TRANSPOSE]")
}

profile1 <- read.delim(args[1], row.names = 1, check.names = FALSE, stringsAsFactors = FALSE, quote = "")
profile2 <- read.delim(args[2], row.names = 1, check.names = FALSE, stringsAsFactors = FALSE, quote = "")
output_prefix <- args[3]
transpose <- length(args) >= 4 && tolower(args[4]) %in% c("true", "t", "1", "yes")
if (transpose) {
  profile1 <- t(profile1)
  profile2 <- t(profile2)
}

common_samples <- intersect(rownames(profile1), rownames(profile2))
if (length(common_samples) < 3) stop("Fewer than three shared samples were found.")
profile1 <- profile1[common_samples, , drop = FALSE]
profile2 <- profile2[common_samples, , drop = FALSE]

ordination1 <- monoMDS(vegdist(profile1, method = "bray"))
ordination2 <- monoMDS(vegdist(profile2, method = "bray"))
fit <- procrustes(ordination1, ordination2, symmetric = TRUE)
set.seed(1)
test <- protest(ordination1, ordination2, permutations = 999)

coordinates <- data.frame(
  Sample = common_samples,
  Profile1_Dim1 = fit$X[, 1], Profile1_Dim2 = fit$X[, 2],
  Profile2_Dim1 = fit$Yrot[, 1], Profile2_Dim2 = fit$Yrot[, 2]
)
statistics <- data.frame(
  Sum_of_squares = fit$ss,
  Correlation = test$t0,
  P_value = test$signif,
  Permutations = 999
)
write.table(coordinates, paste0(output_prefix, "_coordinates.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)
write.table(statistics, paste0(output_prefix, "_statistics.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)
