rm(list = ls())
# R 4.3.1. Samples are balanced to 100 per 5-degree latitude band for 1,000 iterations.
suppressPackageStartupMessages(library(dplyr))

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) {
  stop(
    "Usage: Rscript 02_latitude_coverage_sensitivity.R INPUT_TABLE OUTPUT_PREFIX ",
    "[LATITUDE_COLUMN] [RICHNESS_COLUMN] [ABUNDANCE_COLUMN] ",
    "[BAND_WIDTH] [ITERATIONS] [SEED] [N_PER_BAND]\n",
    "Study defaults: 5-degree bands, 1,000 iterations, and 100 samples per band."
  )
}

input_file <- args[1]
output_prefix <- args[2]
latitude_column <- if (length(args) >= 3) args[3] else "Latitude"
richness_column <- if (length(args) >= 4) args[4] else "ARG_richness"
abundance_column <- if (length(args) >= 5) args[5] else "abundance"
band_width <- if (length(args) >= 6) as.numeric(args[6]) else 5
iterations <- if (length(args) >= 7) as.integer(args[7]) else 1000L
seed <- if (length(args) >= 8) as.integer(args[8]) else 123L
n_per_band <- if (length(args) >= 9) as.integer(args[9]) else 100L
if (is.na(n_per_band) || n_per_band < 1) stop("N_PER_BAND must be a positive integer.")

data <- read.delim(input_file, stringsAsFactors = FALSE, check.names = FALSE, quote = "")
required <- c(latitude_column, richness_column, abundance_column)
if (length(setdiff(required, names(data))) > 0) stop("Input lacks one or more required columns: ", paste(setdiff(required, names(data)), collapse = ", "))
if (!all(vapply(data[required], is.numeric, logical(1)))) stop("Latitude, richness, and abundance columns must be numeric.")

data <- data %>%
  filter(!is.na(.data[[latitude_column]]), !is.na(.data[[richness_column]]), !is.na(.data[[abundance_column]])) %>%
  mutate(
    Absolute_latitude = abs(.data[[latitude_column]]),
    Latitude_band_lower = floor(Absolute_latitude / band_width) * band_width,
    Latitude_band = paste0(Latitude_band_lower, "-", Latitude_band_lower + band_width)
  )

band_counts <- data %>% count(Latitude_band, Latitude_band_lower, name = "Available_N")
eligible_bands <- band_counts %>% filter(Available_N >= n_per_band)
if (nrow(eligible_bands) < 3) stop("Fewer than three latitude bands are eligible for balanced resampling.")
data <- data %>% filter(Latitude_band %in% eligible_bands$Latitude_band)

set.seed(seed)
iteration_results <- vector("list", iterations)
model_results <- vector("list", iterations)
for (i in seq_len(iterations)) {
  sampled <- data %>%
    group_by(Latitude_band) %>%
    slice_sample(n = n_per_band) %>%
    ungroup()
  iteration_results[[i]] <- sampled %>%
    group_by(Latitude_band, Latitude_band_lower) %>%
    summarise(
      Mean_ARG_richness = mean(.data[[richness_column]], na.rm = TRUE),
      SD_ARG_richness = sd(.data[[richness_column]], na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(Iteration = i)
  fit <- lm(
    sampled[[richness_column]] ~ poly(sampled$Absolute_latitude, 2) + sampled[[abundance_column]]
  )
  model_results[[i]] <- data.frame(
    Iteration = i,
    R2 = summary(fit)$r.squared,
    AIC = AIC(fit),
    Linear_latitude = coef(fit)[2],
    Quadratic_latitude = coef(fit)[3]
  )
}

iteration_table <- bind_rows(iteration_results)
band_summary <- iteration_table %>%
  group_by(Latitude_band, Latitude_band_lower) %>%
  summarise(
    Mean_ARG_richness = mean(Mean_ARG_richness),
    SD_across_iterations = sd(Mean_ARG_richness),
    Lower_2.5pct = quantile(Mean_ARG_richness, 0.025),
    Upper_97.5pct = quantile(Mean_ARG_richness, 0.975),
    .groups = "drop"
  )

write.table(iteration_table, paste0(output_prefix, "_band_iterations.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)
write.table(band_summary, paste0(output_prefix, "_band_summary.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)
write.table(bind_rows(model_results), paste0(output_prefix, "_model_iterations.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)
write.table(eligible_bands, paste0(output_prefix, "_eligible_bands.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)
cat("Samples per latitude band:", n_per_band, "\n")
