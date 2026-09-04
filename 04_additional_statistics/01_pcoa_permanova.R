rm(list = ls())
# R 4.3.1.
suppressPackageStartupMessages(library(vegan))

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 4) {
  stop("Usage: Rscript 01_pcoa_permanova.R ABUNDANCE_TSV METADATA_TSV GROUP_COLUMN OUTPUT_PREFIX")
}

abundance <- read.delim(args[1], row.names = 1, check.names = FALSE, stringsAsFactors = FALSE, quote = "")
metadata <- read.delim(args[2], row.names = 1, check.names = FALSE, stringsAsFactors = FALSE, quote = "")
group_column <- args[3]
output_prefix <- args[4]
if (!group_column %in% names(metadata)) stop("Metadata lack group column: ", group_column)

common_samples <- intersect(rownames(abundance), rownames(metadata))
if (length(common_samples) < 3) stop("Fewer than three shared samples were found.")
abundance <- abundance[common_samples, , drop = FALSE]
metadata <- metadata[common_samples, , drop = FALSE]
if (!all(vapply(abundance, is.numeric, logical(1)))) stop("Abundance values must be numeric.")

distance <- vegdist(abundance, method = "bray", na.rm = TRUE)
ordination <- cmdscale(distance, k = 2, eig = TRUE)
coordinates <- data.frame(
  Sample = rownames(ordination$points),
  PCoA1 = ordination$points[, 1],
  PCoA2 = ordination$points[, 2],
  Group = metadata[[group_column]],
  row.names = NULL
)
explained <- 100 * ordination$eig / sum(ordination$eig[ordination$eig > 0])

set.seed(123)
overall <- adonis2(distance ~ metadata[[group_column]], permutations = 999)
overall_table <- data.frame(
  Term = rownames(overall), overall, row.names = NULL, check.names = FALSE
)

groups <- unique(metadata[[group_column]])
pairs <- combn(groups, 2, simplify = FALSE)
pairwise <- do.call(rbind, lapply(pairs, function(pair) {
  keep <- metadata[[group_column]] %in% pair
  local_distance <- as.dist(as.matrix(distance)[keep, keep])
  local_group <- droplevels(factor(metadata[[group_column]][keep]))
  set.seed(123)
  result <- adonis2(local_distance ~ local_group, permutations = 999)
  data.frame(
    Group1 = pair[1], Group2 = pair[2],
    R2 = result$R2[1], P_value = result$`Pr(>F)`[1]
  )
}))
pairwise$FDR <- p.adjust(pairwise$P_value, method = "fdr")

write.table(coordinates, paste0(output_prefix, "_coordinates.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)
write.table(data.frame(Axis = seq_along(explained), Percent_explained = explained), paste0(output_prefix, "_variance.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)
write.table(overall_table, paste0(output_prefix, "_permanova.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)
write.table(pairwise, paste0(output_prefix, "_pairwise_permanova.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)
