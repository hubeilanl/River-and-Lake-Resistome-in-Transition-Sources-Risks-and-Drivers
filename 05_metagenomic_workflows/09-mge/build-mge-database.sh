#!/bin/bash
set -euo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd)
input_fasta=${1:-"$script_dir/myref.fa"}
output_dir=${2:-"$script_dir/database"}

mkdir -p "$output_dir"
awk '/^>/{keep=index($0,"|MGEs|")>0} keep' "$input_fasta" > "$output_dir/MGE.fa"
awk -F '|' 'BEGIN{OFS="\t"; print "sequence_id","category","type","subtype","gene"} /^>/{id=substr($0,2); if($2=="MGEs") print id,$2,$3,$4,$5}' "$output_dir/MGE.fa" > "$output_dir/MGE.structure.tsv"
args_oap make_db -i "$output_dir/MGE.fa"
