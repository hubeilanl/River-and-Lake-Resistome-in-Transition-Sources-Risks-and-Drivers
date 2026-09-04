rm(list = ls())
# R 4.3.1.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) stop("Usage: Rscript 03_latitudinal_gradient.R INPUT_TSV OUTPUT_PREFIX")
data <- read.delim(args[1], stringsAsFactors = FALSE, check.names = FALSE, quote = "")
output_prefix <- args[2]
required <- c("Latitude", "ARG_richness", "abundance")
if (length(setdiff(required, names(data))) > 0) stop("Input must contain Latitude, ARG_richness, and abundance.")

data$Absolute_latitude <- abs(data$Latitude)
fit <- lm(ARG_richness ~ poly(Absolute_latitude, 2) + abundance, data = data)
prediction_grid <- data.frame(
  Absolute_latitude = seq(min(data$Absolute_latitude), max(data$Absolute_latitude), length.out = 200),
  abundance = mean(data$abundance, na.rm = TRUE)
)
prediction <- predict(fit, newdata = prediction_grid, interval = "confidence")
prediction_table <- cbind(prediction_grid, prediction)

write.table(data.frame(Term = rownames(coef(summary(fit))), coef(summary(fit)), row.names = NULL), paste0(output_prefix, "_coefficients.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)
write.table(data.frame(R2 = summary(fit)$r.squared, Adjusted_R2 = summary(fit)$adj.r.squared, AIC = AIC(fit)), paste0(output_prefix, "_fit.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)
write.table(prediction_table, paste0(output_prefix, "_predictions.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)
