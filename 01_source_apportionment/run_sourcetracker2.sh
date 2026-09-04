#!/usr/bin/env bash
set -euo pipefail

# FEATURE_TABLE: indicator ARGs in rows and samples in columns.
# METADATA: SampleID, Env, and SourceSink columns.

if [[ $# -lt 3 ]]; then
  echo "Usage: bash run_sourcetracker2.sh FEATURE_TABLE METADATA OUTPUT_DIR" >&2
  exit 1
fi

feature_table=$1
metadata=$2
output_dir=$3

[[ -f "$feature_table" ]] || { echo "Feature table not found: $feature_table" >&2; exit 1; }
[[ -f "$metadata" ]] || { echo "Metadata file not found: $metadata" >&2; exit 1; }
mkdir -p "$output_dir"

sourcetracker2 gibbs \
  -i "$feature_table" \
  -m "$metadata" \
  -o "$output_dir" \
  --jobs 12 \
  --alpha1 0.001 \
  --alpha2 0.01 \
  --source_rarefaction_depth 0 \
  --sink_rarefaction_depth 0 \
  --restarts 10 \
  --draws_per_restart 20 \
  --burnin 1000 \
  --delay 20
