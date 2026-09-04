#!/bin/bash
# GTDB-Tk v2.3.2 with GTDB release R214.
#SBATCH --time=72:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=256G
#SBATCH --job-name=gtdbtk_classify
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err

set -euo pipefail

mag_dir=$1
output_dir=$2
mash_db=$3
threads=${4:-${SLURM_CPUS_PER_TASK:-32}}

gtdbtk classify_wf --genome_dir "$mag_dir" --out_dir "$output_dir" --mash_db "$mash_db" --cpus "$threads" -x fa --prefix MAGs
