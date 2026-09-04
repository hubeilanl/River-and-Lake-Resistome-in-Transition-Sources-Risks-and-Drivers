# River and Lake Resistome in Transition: Sources, Risks and Drivers

Rivers and lakes connect natural environments with human activities and act as
major reservoirs and transmission pathways for antimicrobial resistance. This
study integrates 4,128 water and sediment metagenomes from river and lake
ecosystems across 42 countries or regions to resolve the global distribution,
sources, ecological drivers and potential risks of antibiotic resistance genes
(ARGs).

The analysis combines resistome profiling with genome-resolved metagenomics,
source apportionment, machine learning and structural equation modelling. It
characterizes the biogeography of the river and lake resistome, identifies
clinically important ARGs and their microbial hosts, quantifies major source
contributions, evaluates environmental and anthropogenic drivers, and generates
predictive maps of resistome risk.

This repository contains the bioinformatic workflows and statistical analysis
scripts used in *River and Lake Resistome in Transition: Sources, Risks and
Drivers*.

## Analytical framework

| Analysis | Objective | Main approaches |
| --- | --- | --- |
| Resistome profiling | Characterize ARG diversity, abundance and biogeographic patterns | ARGs-OAP, community diversity and ordination analyses |
| Genome-resolved analysis | Reconstruct ARG-carrying genomes and identify microbial hosts | MEGAHIT, MetaWRAP, CheckM, GTDB-Tk and sequence annotation |
| Source apportionment | Quantify contributions from major environmental and anthropogenic sources | Indicator ARGs and SourceTracker2 |
| Driver analysis | Identify environmental and anthropogenic predictors of resistome patterns | missForest, random forests, recursive feature elimination and leave-one-out cross-validation |
| Risk assessment | Model and map abundance-weighted resistome risk | Random-forest prediction and spatial projection |
| Ecological interpretation | Evaluate community assembly, geographic gradients and direct or indirect drivers | Neutral community modelling, sensitivity analyses and structural equation modelling |

## Repository structure

| Directory | Contents |
| --- | --- |
| [`01_source_apportionment/`](01_source_apportionment/) | SourceTracker2 execution and source-contribution summaries |
| [`02_environmental_modeling/`](02_environmental_modeling/) | Predictor integration, missing-value imputation, variable selection, random-forest modelling and risk mapping |
| [`03_sensitivity_and_sem/`](03_sensitivity_and_sem/) | Geographic and latitudinal sensitivity analyses and the final structural equation model |
| [`04_additional_statistics/`](04_additional_statistics/) | Community diversity, ordination, Procrustes, latitudinal-gradient, neutral-model and pairwise analyses |
| [`05_metagenomic_workflows/`](05_metagenomic_workflows/) | Read processing, ARG and taxonomic profiling, assembly, MAG reconstruction, functional annotation, plasmid prediction and phylogenetic analysis |

## Source apportionment

SourceTracker2 was applied to indicator ARG sequence types to estimate the
contributions of environmental and anthropogenic sources to river and lake
resistomes. `run_sourcetracker2.sh` records the model execution, and
`summarize_sourcetracker2.R` converts the source-contribution output into
sample-level and grouped summaries.

## Environmental drivers and resistome risk

The scripts in `02_environmental_modeling/` form a sequential modelling
workflow. Country-year predictors are first integrated with sample records,
variables with more than 30% missing values are removed, and the remaining
missing values are imputed with missForest. Random-forest models then combine
recursive feature elimination, hyperparameter tuning and leave-one-out
cross-validation to identify important predictors and generate global
predictions.

The workflow is applied to two study outcomes: ARG abundance for environmental
driver analysis, and the abundance-weighted sample risk score for resistome-risk
prediction. Separate river-water and lake-water models generate the global risk
maps presented in Fig. 5d and Fig. S11d.

## Sensitivity analyses and structural equation modelling

The sensitivity analyses evaluate the influence of uneven geographic coverage
on observed temporal trends. Samples are repeatedly balanced to 40 per
continent or 100 per 5-degree latitude band over 1,000 iterations. The final
structural equation model evaluates direct and indirect relationships among
population size, livestock and aquaculture production, antibiotic consumption,
economic development, ARG host range, mobile genetic elements and ARG
abundance, corresponding to Fig. 3f.

## Community and statistical analyses

The scripts in `04_additional_statistics/` implement Bray-Curtis PCoA and
PERMANOVA, NMDS, Procrustes analysis, Chao1 richness estimation, latitudinal
gradient models, Sloan neutral community modelling and FDR-corrected pairwise
tests. Together, these analyses describe resistome differentiation across
ecosystems and regions and connect ARG patterns with microbial community
structure and geography.

## Metagenomic workflows

The workflows in `05_metagenomic_workflows/` cover the principal sequence-based
analyses, including read trimming, ARG quantification, taxonomic profiling,
metagenome assembly, MAG reconstruction and classification, ARG and mobile
genetic element annotation, plasmid prediction, phylogenetic analysis and
fecal-marker quantification. Scripts are organized by analytical stage and
retain the parameters used in the study.

## External data resources

The metagenome-assembled genomes generated in this study are available through
Zenodo:

- The global surface water bacterial and archaeal genome catalog:
  [https://doi.org/10.5281/zenodo.18977176](https://doi.org/10.5281/zenodo.18977176)

The sample-level ARG risk score calculator is available through GitHub:

- Surface Water ARG Metagenomic Risk Score Calculator:
  [https://github.com/hubeilanl/Surface-Water-ARG-Metagenomic-Risk-Score-Calculator](https://github.com/hubeilanl/Surface-Water-ARG-Metagenomic-Risk-Score-Calculator)

