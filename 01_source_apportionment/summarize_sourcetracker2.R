rm(list = ls())

# R 4.3.1. MIXING_PROPORTIONS contains sink samples in rows and source categories in columns.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 3) {
  stop(
    "Usage: Rscript summarize_sourcetracker2.R ",
    "MIXING_PROPORTIONS SINK_METADATA OUTPUT_PREFIX [GROUP_COLUMNS]\n",
    "Example GROUP_COLUMNS: Continent,Year,Group1,Group2"
  )
}

proportions_file <- args[1]
metadata_file <- args[2]
output_prefix <- args[3]
group_columns <- if (length(args) >= 4 && nzchar(args[4])) {
  strsplit(args[4], ",", fixed = TRUE)[[1]]
} else {
  character(0)
}

proportions <- read.delim(
  proportions_file,
  check.names = FALSE,
  stringsAsFactors = FALSE,
  quote = ""
)
metadata <- read.delim(
  metadata_file,
  check.names = FALSE,
  stringsAsFactors = FALSE,
  quote = ""
)

if (ncol(proportions) < 2) stop("The proportions table must contain a sample-ID column and at least one source column.")
if (ncol(metadata) < 1) stop("The metadata table is empty.")

names(proportions)[1] <- "Sample"
names(metadata)[1] <- "Sample"
source_columns <- setdiff(names(proportions), "Sample")

long <- data.frame(
  Sample = rep(proportions$Sample, times = length(source_columns)),
  Source = rep(source_columns, each = nrow(proportions)),
  Contribution = as.numeric(unlist(proportions[source_columns], use.names = FALSE)),
  stringsAsFactors = FALSE
)

long <- merge(long, metadata, by = "Sample", all.x = TRUE, sort = FALSE)
write.table(
  long,
  paste0(output_prefix, "_sample_long.tsv"),
  sep = "\t",
  quote = FALSE,
  row.names = FALSE
)

valid_groups <- intersect(group_columns, names(long))
if (length(valid_groups) > 0) {
  grouping <- c(valid_groups, "Source")
  mean_table <- aggregate(long$Contribution, long[grouping], mean, na.rm = TRUE)
  sd_table <- aggregate(long$Contribution, long[grouping], sd, na.rm = TRUE)
  n_table <- aggregate(long$Contribution, long[grouping], function(x) sum(!is.na(x)))
  names(mean_table)[ncol(mean_table)] <- "Mean_contribution"
  names(sd_table)[ncol(sd_table)] <- "SD_contribution"
  names(n_table)[ncol(n_table)] <- "N"
  summary_table <- Reduce(
    function(x, y) merge(x, y, by = grouping, all = TRUE, sort = FALSE),
    list(mean_table, sd_table, n_table)
  )
  write.table(
    summary_table,
    paste0(output_prefix, "_group_summary.tsv"),
    sep = "\t",
    quote = FALSE,
    row.names = FALSE
  )
}

cat("SourceTracker2 result summaries written with prefix:", output_prefix, "\n")
