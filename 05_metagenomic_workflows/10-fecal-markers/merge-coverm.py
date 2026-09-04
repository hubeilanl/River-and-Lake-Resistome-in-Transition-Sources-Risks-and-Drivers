#!/usr/bin/env python3

import csv
import os
import sys


if len(sys.argv) != 5:
    print("Usage: python merge-coverm.py sample_list.txt CoverM_output_directory marker-map.tsv output_directory")
    sys.exit(1)

sample_list = sys.argv[1]
coverm_dir = os.path.abspath(sys.argv[2])
marker_map_file = sys.argv[3]
output_dir = os.path.abspath(sys.argv[4])
os.makedirs(output_dir, exist_ok=True)

marker_map = {}
with open(marker_map_file, encoding="utf-8") as handle:
    for row in csv.DictReader(handle, delimiter="\t"):
        marker_map[row["accession"]] = row


def column_index(header, method, fallback):
    normalized = [value.lower().replace("_", " ") for value in header]
    for index, value in enumerate(normalized):
        if method == "mean" and "mean" in value and "trimmed" not in value:
            return index
        if method == "trimmed_mean" and "trimmed" in value and "mean" in value:
            return index
        if method == "length" and "length" in value:
            return index
        if method == "count" and "count" in value:
            return index
    return fallback


rows = []
with open(sample_list, encoding="utf-8") as handle:
    for line in handle:
        sample_id = line.strip()
        if not sample_id or sample_id.startswith("#"):
            continue
        with open(os.path.join(coverm_dir, sample_id + ".coverm.tsv"), encoding="utf-8") as coverm_file:
            reader = csv.reader(coverm_file, delimiter="\t")
            header = next(reader)
            indexes = [column_index(header, "mean", 1), column_index(header, "trimmed_mean", 2), column_index(header, "length", 3), column_index(header, "count", 4)]
            for fields in reader:
                accession = fields[0].split()[0]
                marker = marker_map.get(accession, {"marker_name": accession, "reference_group": "unassigned", "primary_marker": "0"})
                rows.append([sample_id, accession, marker["marker_name"], marker["reference_group"], marker["primary_marker"]] + [fields[index] for index in indexes])

header = ["sample_id", "accession", "marker_name", "reference_group", "primary_marker", "mean_coverage", "trimmed_mean_coverage", "reference_length", "mapped_read_count"]
with open(os.path.join(output_dir, "all-viral-markers.tsv"), "w", encoding="utf-8", newline="") as output:
    writer = csv.writer(output, delimiter="\t", lineterminator="\n")
    writer.writerow(header)
    writer.writerows(rows)

with open(os.path.join(output_dir, "primary-fecal-markers.tsv"), "w", encoding="utf-8", newline="") as output:
    writer = csv.writer(output, delimiter="\t", lineterminator="\n")
    writer.writerow(header)
    writer.writerows(row for row in rows if row[4] == "1")
