rm(list = ls())

# R 4.3.1. Both input tables use Country and Year as matching fields.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 3) {
  stop(
    "Usage: Rscript 01_merge_country_year_data.R ",
    "SAMPLE_TABLE COUNTRY_YEAR_PREDICTORS OUTPUT_FILE ",
    "[COUNTRY_COLUMN] [YEAR_COLUMN]"
  )
}

sample_file <- args[1]
predictor_file <- args[2]
output_file <- args[3]
country_column <- if (length(args) >= 4) args[4] else "Country"
year_column <- if (length(args) >= 5) args[5] else "Year"

samples <- read.delim(sample_file, check.names = FALSE, stringsAsFactors = FALSE, quote = "")
predictors <- read.delim(predictor_file, check.names = FALSE, stringsAsFactors = FALSE, quote = "")
keys <- c(country_column, year_column)

missing_sample_keys <- setdiff(keys, names(samples))
missing_predictor_keys <- setdiff(keys, names(predictors))
if (length(missing_sample_keys) > 0) stop("Missing sample-table key(s): ", paste(missing_sample_keys, collapse = ", "))
if (length(missing_predictor_keys) > 0) stop("Missing predictor-table key(s): ", paste(missing_predictor_keys, collapse = ", "))
if (anyDuplicated(predictors[keys])) stop("Country-year predictor keys are not unique.")

merged <- merge(samples, predictors, by = keys, all.x = TRUE, sort = FALSE)
predictor_names <- setdiff(names(predictors), keys)
unmatched <- rowSums(is.na(merged[predictor_names])) == length(predictor_names)

write.table(merged, output_file, sep = "\t", quote = FALSE, row.names = FALSE)
cat("Rows written:", nrow(merged), "\n")
cat("Rows without matched country-year predictors:", sum(unmatched), "\n")
