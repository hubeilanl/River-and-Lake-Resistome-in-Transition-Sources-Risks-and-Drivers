# Fecal marker abundance calculation

CoverM `mean coverage` is normalized by the ARGs-OAP stage-one estimate of microbial cell abundance (`nCell`):

`marker copies per cell = CoverM mean coverage / nCell`

The combined human fecal-marker abundance used in the analysis is:

`human fecal markers = crAssphage copies per cell + PhiCrAss001 copies per cell`

PhiB124-14 is reported separately because it is associated with both human and animal fecal sources. CoverM `trimmed_mean` is retained as an additional auditable metric, but `mean coverage` is used for the reported copies-per-cell abundance.

Run after `merge-coverm.py`:

```bash
python calculate-copies-per-cell.py coverm-merged/primary-fecal-markers.tsv one-args_oap fecal-marker-abundance
```

The script recursively reads ARGs-OAP `metadata.txt` files and writes `fecal-marker-copies-per-cell.tsv` and `human-fecal-markers-combined.tsv`.
