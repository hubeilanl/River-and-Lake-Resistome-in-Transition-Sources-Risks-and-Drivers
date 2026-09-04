rm(list = ls())
# R 4.3.1. Identifier and response columns are passed through unchanged.
suppressPackageStartupMessages(library(missForest))

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) {
  stop(
    "Usage: Rscript 02_impute_and_scale.R INPUT_TSV OUTPUT_PREFIX ",
    "[ID_COLUMNS] [PASSTHROUGH_COLUMNS] [MAX_MISSING_FRACTION] [SEED]\n",
    "Example: ID_COLUMNS=sample_id,Country,Year and PASSTHROUGH_COLUMNS=Risk_score"
  )
}

input_file <- args[1]
output_prefix <- args[2]
id_columns <- if (length(args) >= 3 && nzchar(args[3])) strsplit(args[3], ",", fixed = TRUE)[[1]] else "sample_id"
passthrough_columns <- if (length(args) >= 4 && nzchar(args[4])) strsplit(args[4], ",", fixed = TRUE)[[1]] else character(0)
max_missing_fraction <- if (length(args) >= 5) as.numeric(args[5]) else 0.30
seed <- if (length(args) >= 6) as.integer(args[6]) else 123L

dat <- read.delim(input_file, header = TRUE, sep = "\t", stringsAsFactors = FALSE, check.names = FALSE, quote = "")
missing_ids <- setdiff(id_columns, names(dat))
if (length(missing_ids) > 0) stop("Missing identifier column(s): ", paste(missing_ids, collapse = ", "))
missing_passthrough <- setdiff(passthrough_columns, names(dat))
if (length(missing_passthrough) > 0) stop("Missing passthrough column(s): ", paste(missing_passthrough, collapse = ", "))

fixed_columns <- unique(c(id_columns, passthrough_columns))
model_columns <- setdiff(names(dat), fixed_columns)
missing_fraction <- vapply(dat[model_columns], function(x) mean(is.na(x)), numeric(1))
removed_columns <- names(missing_fraction)[missing_fraction > max_missing_fraction]
retained_columns <- setdiff(model_columns, removed_columns)
if (length(retained_columns) == 0) stop("No model variables remain after missingness filtering.")

model_data <- dat[retained_columns]
convert_numeric_like <- function(x) {
  if (!is.character(x)) return(x)
  cleaned <- gsub(",", "", trimws(x), fixed = TRUE)
  parsed <- suppressWarnings(as.numeric(cleaned))
  observed <- !is.na(x) & nzchar(trimws(x))
  if (all(!observed | !is.na(parsed))) parsed else factor(x)
}
model_data[] <- lapply(model_data, convert_numeric_like)

set.seed(seed)
imputation <- missForest(model_data, ntree = 200, maxiter = 10, verbose = TRUE)
imputed_model <- imputation$ximp
imputed <- cbind(dat[fixed_columns], imputed_model, check.names = FALSE)

scaled_model <- imputed_model
numeric_columns <- names(imputed_model)[vapply(imputed_model, is.numeric, logical(1))]
scaling_parameters <- data.frame(
  Variable = numeric_columns,
  Mean = vapply(imputed_model[numeric_columns], mean, numeric(1)),
  SD = vapply(imputed_model[numeric_columns], sd, numeric(1)),
  stringsAsFactors = FALSE
)
zero_sd <- is.na(scaling_parameters$SD) | scaling_parameters$SD == 0
if (any(zero_sd)) warning("Variables with zero or undefined SD were left unscaled: ", paste(scaling_parameters$Variable[zero_sd], collapse = ", "))
for (variable in scaling_parameters$Variable[!zero_sd]) {
  scaled_model[[variable]] <- (imputed_model[[variable]] - mean(imputed_model[[variable]])) / sd(imputed_model[[variable]])
}
scaled <- cbind(dat[fixed_columns], scaled_model, check.names = FALSE)

write.table(imputed, paste0(output_prefix, "_imputed.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)
write.table(scaled, paste0(output_prefix, "_imputed_scaled.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)
write.table(scaling_parameters, paste0(output_prefix, "_scaling_parameters.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)
write.table(data.frame(Variable = removed_columns), paste0(output_prefix, "_removed_over_30pct_missing.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)
writeLines(capture.output(imputation$OOBerror), paste0(output_prefix, "_imputation_oob_error.txt"))

cat("Retained variables:", length(retained_columns), "\n")
cat("Removed variables:", length(removed_columns), "\n")
