#!/bin/bash
set -euo pipefail

stage_two_dir=$1
output_dir=$2
script_dir=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$output_dir"
output_dir=$(cd "$output_dir" && pwd)
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

while IFS= read -r file; do sample_id=$(basename "$(dirname "$file")"); tail -n +2 "$file" > "$work_dir/${sample_id}.type.txt"; done < <(find "$stage_two_dir" -type f -name 'normalized_cell.type.txt' | sort)
while IFS= read -r file; do sample_id=$(basename "$(dirname "$file")"); tail -n +2 "$file" > "$work_dir/${sample_id}.subtype.txt"; done < <(find "$stage_two_dir" -type f -name 'normalized_cell.subtype.txt' | sort)
(cd "$work_dir" && find . -maxdepth 1 -name '*.type.txt' -print | sed 's#^./##' | sort > type.list && python3 "$script_dir/join_files_by_id.py" type.list "$output_dir/ARG-type-copies-per-cell.tsv")
(cd "$work_dir" && find . -maxdepth 1 -name '*.subtype.txt' -print | sed 's#^./##' | sort > subtype.list && python3 "$script_dir/join_files_by_id.py" subtype.list "$output_dir/ARG-subtype-copies-per-cell.tsv")
