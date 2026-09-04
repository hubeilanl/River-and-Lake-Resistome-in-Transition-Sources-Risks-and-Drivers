rm(list = ls())
# R 4.3.1.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 4) {
  stop("Usage: Rscript 05_pairwise_wilcoxon_fdr.R INPUT_TSV VALUE_COLUMN GROUP_COLUMN OUTPUT_TSV [STRATUM_COLUMN]")
}

data <- read.delim(args[1], stringsAsFactors = FALSE, check.names = FALSE, quote = "")
value_column <- args[2]
group_column <- args[3]
output_file <- args[4]
stratum_column <- if (length(args) >= 5) args[5] else NULL
required <- c(value_column, group_column)
if (!is.null(stratum_column)) required <- c(required, stratum_column)
if (length(setdiff(required, names(data))) > 0) stop("Input lacks one or more requested columns.")

run_pairwise <- function(subset, stratum = NA_character_) {
  groups <- unique(subset[[group_column]])
  if (length(groups) < 2) return(NULL)
  pairs <- combn(groups, 2, simplify = FALSE)
  result <- do.call(rbind, lapply(pairs, function(pair) {
    x <- subset[subset[[group_column]] == pair[1], value_column]
    y <- subset[subset[[group_column]] == pair[2], value_column]
    test <- wilcox.test(x, y, exact = FALSE)
    data.frame(Stratum = stratum, Group1 = pair[1], Group2 = pair[2], W = unname(test$statistic), P_value = test$p.value)
  }))
  result$FDR <- p.adjust(result$P_value, method = "fdr")
  result
}

if (is.null(stratum_column)) {
  results <- run_pairwise(data)
} else {
  results <- do.call(rbind, lapply(unique(data[[stratum_column]]), function(level) {
    run_pairwise(data[data[[stratum_column]] == level, , drop = FALSE], as.character(level))
  }))
}
write.table(results, output_file, sep = "\t", quote = FALSE, row.names = FALSE)
