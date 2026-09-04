rm(list = ls())
# R 4.3.1.
suppressPackageStartupMessages(library(vegan))

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) {
  stop("Usage: Rscript 06_nmds.R ABUNDANCE_TSV OUTPUT_PREFIX [TRANSPOSE] [SEED]")
}

abundance <- read.delim(
  args[1], row.names = 1, check.names = FALSE,
  stringsAsFactors = FALSE, quote = ""
)
output_prefix <- args[2]
transpose <- length(args) >= 3 && tolower(args[3]) %in% c("true", "t", "1", "yes")
seed <- if (length(args) >= 4) as.integer(args[4]) else 123L

if (transpose) abundance <- t(abundance)
if (!all(vapply(as.data.frame(abundance), is.numeric, logical(1)))) {
  stop("Abundance values must be numeric.")
}
if (nrow(abundance) < 3) stop("At least three samples are required for NMDS.")

set.seed(seed)
fit <- metaMDS(
  abundance,
  distance = "bray",
  k = 2,
  trymax = 100,
  autotransform = FALSE,
  trace = FALSE
)

coordinates <- data.frame(
  Sample = rownames(abundance),
  NMDS1 = scores(fit, display = "sites")[, 1],
  NMDS2 = scores(fit, display = "sites")[, 2],
  row.names = NULL
)
statistics <- data.frame(
  Stress = fit$stress,
  Converged = fit$converged,
  Tries = fit$tries,
  Distance = "Bray-Curtis",
  Dimensions = 2
)

write.table(
  coordinates, paste0(output_prefix, "_coordinates.tsv"),
  sep = "\t", quote = FALSE, row.names = FALSE
)
write.table(
  statistics, paste0(output_prefix, "_statistics.tsv"),
  sep = "\t", quote = FALSE, row.names = FALSE
)
