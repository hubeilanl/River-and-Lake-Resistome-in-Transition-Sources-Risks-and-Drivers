rm(list = ls())
# R 4.3.1. The SEM input variables are checked below; host denotes ARG host range.
suppressPackageStartupMessages({
  library(lavaan)
  library(semPlot)
})

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) stop("Usage: Rscript 03_sem_final_model.R INPUT_TSV OUTPUT_DIR")
input_file <- args[1]
output_dir <- args[2]
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

data <- read.delim(input_file, sep = "\t", header = TRUE, stringsAsFactors = FALSE, check.names = FALSE, quote = "")
if (!"host_range" %in% names(data) && "host" %in% names(data)) {
  names(data)[names(data) == "host"] <- "host_range"
  message("Renamed legacy SEM input column 'host' to 'host_range'.")
}
required_variables <- c(
  "antibioticsfood", "AntibioticDDD", "GDP", "environmentUS", "HDI",
  "tem", "pre", "transposon", "intI1", "FreshwaterT", "livestockAn",
  "abundance_ARG", "Population", "host_range"
)
missing_variables <- setdiff(required_variables, names(data))
if (length(missing_variables) > 0) stop("Missing SEM variables: ", paste(missing_variables, collapse = ", "))
non_numeric <- required_variables[!vapply(data[required_variables], is.numeric, logical(1))]
if (length(non_numeric) > 0) stop("Non-numeric SEM variables: ", paste(non_numeric, collapse = ", "))

final_model <- '
  Antibiotic =~ antibioticsfood + AntibioticDDD
  economy =~ GDP + environmentUS + HDI
  climate =~ tem + pre
  MGEs =~ transposon + intI1

  antibioticsfood ~ FreshwaterT + livestockAn
  MGEs ~ Antibiotic + host_range
  abundance_ARG ~ MGEs + host_range + economy + climate + Population
  Antibiotic ~ economy
  FreshwaterT ~ Population
  livestockAn ~ Population
'

fit <- sem(model = final_model, data = data, missing = "ml")
if (!lavInspect(fit, "converged")) stop("SEM did not converge.")

fit_indices <- data.frame(
  Measure = c("chisq", "df", "pvalue", "cfi", "tli", "rmsea", "srmr", "aic", "bic"),
  Value = as.numeric(fitMeasures(fit, c("chisq", "df", "pvalue", "cfi", "tli", "rmsea", "srmr", "aic", "bic")))
)
parameters <- parameterEstimates(fit, standardized = TRUE, ci = TRUE)
structural_paths <- parameters[parameters$op == "~", ]
factor_loadings <- parameters[parameters$op == "=~", ]
r_squared <- data.frame(Variable = names(inspect(fit, "r2")), R2 = as.numeric(inspect(fit, "r2")))

write.csv(fit_indices, file.path(output_dir, "sem_fit_indices.csv"), row.names = FALSE)
write.csv(structural_paths, file.path(output_dir, "sem_structural_paths.csv"), row.names = FALSE)
write.csv(factor_loadings, file.path(output_dir, "sem_factor_loadings.csv"), row.names = FALSE)
write.csv(r_squared, file.path(output_dir, "sem_r_squared.csv"), row.names = FALSE)
writeLines(final_model, file.path(output_dir, "sem_final_model.txt"))
capture.output(
  summary(fit, fit.measures = TRUE, standardized = TRUE, rsquare = TRUE),
  file = file.path(output_dir, "sem_summary.txt")
)

pdf(file.path(output_dir, "sem_standardized.pdf"), width = 12, height = 8)
semPaths(
  fit, what = "std", whatLabels = "std", layout = "tree",
  edge.label.cex = 0.8, sizeMan = 6, sizeLat = 8,
  residuals = FALSE, intercepts = FALSE, nDigits = 3
)
dev.off()
