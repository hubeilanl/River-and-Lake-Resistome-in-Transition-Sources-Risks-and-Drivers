rm(list = ls())
# R 4.3.1. Samples are balanced to 40 per eligible continent for 1,000 iterations.
suppressPackageStartupMessages(library(dplyr))

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 3) {
  stop(
    "Usage: Rscript 01_geographic_imbalance_sensitivity.R ",
    "GROUP_TABLE ARG_ABUNDANCE_TABLE OUTPUT_PREFIX ",
    "[SAMPLE_COLUMN] [CONTINENT_COLUMN] [N_PER_CONTINENT] [ITERATIONS] [SEED]"
  )
}

group_file <- args[1]
abundance_file <- args[2]
output_prefix <- args[3]
sample_column <- if (length(args) >= 4) args[4] else "Sample"
continent_column <- if (length(args) >= 5) args[5] else "Continent"
n_per_continent <- if (length(args) >= 6) as.integer(args[6]) else 40L
iterations <- if (length(args) >= 7) as.integer(args[7]) else 1000L
seed <- if (length(args) >= 8) as.integer(args[8]) else 123L

groups <- read.delim(group_file, stringsAsFactors = FALSE, check.names = FALSE, quote = "")
abundance <- read.delim(abundance_file, stringsAsFactors = FALSE, check.names = FALSE, quote = "")
if (!all(c(sample_column, continent_column) %in% names(groups))) stop("Group table lacks the sample or continent column.")
if (!sample_column %in% names(abundance)) stop("Abundance table lacks the sample column.")

data <- merge(groups[c(sample_column, continent_column)], abundance, by = sample_column)
gene_columns <- setdiff(names(abundance), sample_column)
eligible <- data %>% count(.data[[continent_column]], name = "N") %>% filter(N >= n_per_continent)
if (nrow(eligible) < 2) stop("Fewer than two continents have the requested number of samples.")
data <- data %>% filter(.data[[continent_column]] %in% eligible[[continent_column]])

set.seed(seed)
iteration_results <- vector("list", iterations)
for (i in seq_len(iterations)) {
  sampled <- data %>%
    group_by(.data[[continent_column]]) %>%
    slice_sample(n = n_per_continent) %>%
    ungroup()
  iteration_results[[i]] <- bind_rows(lapply(gene_columns, function(gene) {
    sampled %>%
      group_by(.data[[continent_column]]) %>%
      summarise(Prevalence = mean(.data[[gene]] > 0, na.rm = TRUE), .groups = "drop") %>%
      mutate(Gene = gene, Iteration = i)
  }))
}

iteration_table <- bind_rows(iteration_results)
names(iteration_table)[1] <- "Continent"
summary_table <- iteration_table %>%
  group_by(Gene, Continent) %>%
  summarise(
    Mean_prevalence = mean(Prevalence),
    SD_prevalence = sd(Prevalence),
    Lower_2.5pct = quantile(Prevalence, 0.025),
    Upper_97.5pct = quantile(Prevalence, 0.975),
    .groups = "drop"
  )

write.table(iteration_table, paste0(output_prefix, "_iterations.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)
write.table(summary_table, paste0(output_prefix, "_summary.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)
write.table(eligible, paste0(output_prefix, "_eligible_continents.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)
