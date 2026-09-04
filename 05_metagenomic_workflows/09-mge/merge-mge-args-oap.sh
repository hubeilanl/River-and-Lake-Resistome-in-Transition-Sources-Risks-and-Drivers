#!/bin/bash
set -euo pipefail

stage_two_dir=$1
output_dir=$2
script_dir=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$output_dir"
output_dir=$(cd "$output_dir" && pwd)
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

for level in category type subtype gene; do while IFS= read -r file; do sample_id=$(basename "$(dirname "$file")"); tail -n +2 "$file" > "$work_dir/${sample_id}.${level}.txt"; done < <(find "$stage_two_dir" -type f -name "normalized_cell.${level}.txt" | sort); (cd "$work_dir" && find . -maxdepth 1 -name "*.${level}.txt" -print | sed 's#^./##' | sort > "${level}.list" && python3 "$script_dir/join_files_by_id.py" "${level}.list" "$output_dir/MGE-${level}-copies-per-cell.tsv"); done
