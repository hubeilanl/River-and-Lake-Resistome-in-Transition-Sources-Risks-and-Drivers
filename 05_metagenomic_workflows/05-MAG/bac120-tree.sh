#!/bin/bash
# GTDB-Tk v2.3.2 with GTDB release R214.
#SBATCH --time=72:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=128G
#SBATCH --job-name=bac120_tree
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err

set -euo pipefail

mag_dir=$1
output_dir=$2
threads=${3:-${SLURM_CPUS_PER_TASK:-32}}
identify_dir="$output_dir/MAGs_identify"
align_dir="$output_dir/MAGs_align"
infer_dir="$output_dir/MAGs_infer"

mkdir -p "$output_dir"
gtdbtk identify --genome_dir "$mag_dir" --out_dir "$identify_dir" --cpus "$threads" -x fa --prefix MAGs
gtdbtk align --identify_dir "$identify_dir" --out_dir "$align_dir" --skip_gtdb_refs --cpus "$threads" --prefix MAGs
gtdbtk infer --msa_file "$align_dir/align/MAGs.bac120.user_msa.fasta.gz" --out_dir "$infer_dir" --prot_model LG --gamma --prefix MAGs --cpus "$threads"
gtdbtk convert_to_itol --input "$infer_dir/MAGs.unrooted.tree" --output "$output_dir/MAGs.itol.tree"
