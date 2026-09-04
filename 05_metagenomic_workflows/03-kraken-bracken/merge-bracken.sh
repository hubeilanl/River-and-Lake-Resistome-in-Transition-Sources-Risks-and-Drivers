#!/bin/bash
set -euo pipefail

bracken_dir=$1
output_dir=$2
script_dir=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$output_dir"
output_dir=$(cd "$output_dir" && pwd)
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

for level in D P C O F G; do while IFS= read -r file; do name=$(basename "$file" ".${level}.tsv"); tail -n +2 "$file" | cut -f 1,7 > "$work_dir/${name}.${level}.txt"; done < <(find "$bracken_dir" -maxdepth 1 -type f -name "*.${level}.tsv" | sort); (cd "$work_dir" && find . -maxdepth 1 -name "*.${level}.txt" -print | sed 's#^./##' | sort > "${level}.list" && python3 "$script_dir/join_files_by_id.py" "${level}.list" "$output_dir/all-${level}.tsv"); done
