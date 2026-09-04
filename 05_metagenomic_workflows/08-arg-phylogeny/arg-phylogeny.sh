#!/bin/bash
# BEDTools v2.30.0 and FastTree v2.1.
#SBATCH --time=24:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --job-name=arg_phylogeny
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err

set -euo pipefail

contigs=$1
diamond_result=$2
reference_sequences=$3
arg_pattern=$4
output_dir=$5
threads=${6:-${SLURM_CPUS_PER_TASK:-16}}

mkdir -p "$output_dir"
awk -F '\t' -v arg="$arg_pattern" 'BEGIN{OFS="\t"} $2~arg {start=$7<$8?$7-1:$8-1; end=$7>$8?$7:$8; strand=$7<=$8?"+":"-"; print $1,start,end,$1"|"$2"|"NR,0,strand}' "$diamond_result" > "$output_dir/ARG-regions.bed"
test -s "$output_dir/ARG-regions.bed"
bedtools getfasta -fi "$contigs" -bed "$output_dir/ARG-regions.bed" -fo "$output_dir/ARG-query-sequences.fa" -name -s
cat "$reference_sequences" "$output_dir/ARG-query-sequences.fa" > "$output_dir/ARG-nucleotide-sequences.fa"
mafft --auto --thread "$threads" "$output_dir/ARG-nucleotide-sequences.fa" > "$output_dir/ARG-nucleotide-alignment.fa"
FastTree -nt -gtr "$output_dir/ARG-nucleotide-alignment.fa" > "$output_dir/ARG-nucleotide-tree.nwk"
