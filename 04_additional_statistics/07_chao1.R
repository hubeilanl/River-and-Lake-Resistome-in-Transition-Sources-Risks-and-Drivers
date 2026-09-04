rm(list = ls())
# R 4.3.1.
suppressPackageStartupMessages(library(vegan))

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) {
  stop("Usage: Rscript 07_chao1.R ABUNDANCE_TSV OUTPUT_TSV [TRANSPOSE]")
}

abundance <- read.delim(
  args[1], row.names = 1, check.names = FALSE,
  stringsAsFactors = FALSE, quote = ""
)
output_file <- args[2]
transpose <- length(args) >= 3 && tolower(args[3]) %in% c("true", "t", "1", "yes")

if (transpose) abundance <- t(abundance)
if (!all(vapply(as.data.frame(abundance), is.numeric, logical(1)))) {
  stop("Abundance values must be numeric.")
}
if (any(abundance < 0, na.rm = TRUE)) stop("Abundance values must be non-negative.")

# vegan::estimateR expects taxa in rows and samples in columns.
estimate <- t(estimateR(t(as.matrix(abundance))))
result <- data.frame(Sample = rownames(estimate), estimate, check.names = FALSE, row.names = NULL)

write.table(result, output_file, sep = "\t", quote = FALSE, row.names = FALSE)
