#!/bin/bash
# CheckM v1.1.3.
#SBATCH --time=48:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=128G
#SBATCH --job-name=checkm_v1
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err

set -euo pipefail

mag_dir=$1
output_dir=$2
threads=${3:-${SLURM_CPUS_PER_TASK:-32}}

mkdir -p "$output_dir"
checkm lineage_wf -x fa -t "$threads" --tab_table -f "$output_dir/checkm-quality.tsv" "$mag_dir" "$output_dir/checkm-workflow"
awk -F '\t' 'NR==1 || ($12>=70 && $13<=10)' "$output_dir/checkm-quality.tsv" > "$output_dir/checkm-quality-filtered.tsv"
