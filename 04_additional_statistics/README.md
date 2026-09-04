# Additional statistical analyses

This directory contains the statistical procedures used to characterize
resistome diversity, community differentiation and geographic patterns.

- `01_pcoa_permanova.R`: Bray-Curtis PCoA, overall PERMANOVA, and pairwise
  PERMANOVA with FDR correction.
- `02_procrustes_analysis.R`: Procrustes and PROTEST comparison of two community
  profiles.
- `03_latitudinal_gradient.R`: quadratic absolute-latitude model with ARG
  abundance as a covariate.
- `04_neutral_community_model.R`: Sloan neutral community model.
- `05_pairwise_wilcoxon_fdr.R`: pairwise Mann-Whitney/Wilcoxon tests with FDR
  correction.
- `06_nmds.R`: Bray-Curtis non-metric multidimensional scaling, as used for
  resistome-profile comparisons and indicator-ARG source profiles.
- `07_chao1.R`: sample-level observed richness and Chao1 estimates using
  `vegan::estimateR`.
