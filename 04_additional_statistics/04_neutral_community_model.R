rm(list = ls())
# R 4.3.1.
suppressPackageStartupMessages(library(MicEco))

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) stop("Usage: Rscript 04_neutral_community_model.R ABUNDANCE_TSV OUTPUT_PREFIX")
abundance <- read.delim(args[1], row.names = 1, check.names = FALSE, stringsAsFactors = FALSE, quote = "")
output_prefix <- args[2]

filtered <- abundance[rowSums(abundance > 0, na.rm = TRUE) >= 5, , drop = FALSE]
filtered <- filtered[, colSums(filtered > 0, na.rm = TRUE) >= 10, drop = FALSE]
if (nrow(filtered) == 0 || ncol(filtered) == 0) stop("No features remain after prevalence filtering.")

fit <- neutral.fit(t(filtered))
model_parameters <- data.frame(
  Migration_rate = fit[[1]][1],
  Community_size = fit[[1]][4],
  Nm = fit[[1]][1] * fit[[1]][4],
  R2 = fit[[1]][3]
)
write.table(model_parameters, paste0(output_prefix, "_parameters.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)
write.table(fit[[2]], paste0(output_prefix, "_feature_predictions.tsv"), sep = "\t", quote = FALSE, row.names = TRUE, col.names = NA)
