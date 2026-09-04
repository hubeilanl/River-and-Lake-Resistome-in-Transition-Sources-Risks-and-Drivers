#!/usr/bin/env python3

import csv
import os
import sys
from pathlib import Path


if len(sys.argv) != 4:
    print("Usage: python calculate-copies-per-cell.py primary-fecal-markers.tsv ARGs-OAP_stage-one_directory output_directory")
    sys.exit(1)

marker_file = sys.argv[1]
stage_one_dir = Path(sys.argv[2]).resolve()
output_dir = Path(sys.argv[3]).resolve()
output_dir.mkdir(parents=True, exist_ok=True)


def number(value):
    return format(value, ".12g")


ncells = {}
metadata_files = sorted(stage_one_dir.rglob("metadata.txt"))
if not metadata_files:
    raise SystemExit("No metadata.txt files were found under: " + str(stage_one_dir))

for metadata_file in metadata_files:
    with metadata_file.open(encoding="utf-8") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        if not reader.fieldnames or not {"sample", "nCell"}.issubset(reader.fieldnames):
            raise SystemExit("Missing sample or nCell column in: " + str(metadata_file))
        for row in reader:
            sample_id = row["sample"].strip()
            ncell = float(row["nCell"])
            if ncell <= 0:
                raise SystemExit("nCell must be greater than zero for sample: " + sample_id)
            if sample_id in ncells and ncells[sample_id] != ncell:
                raise SystemExit("Conflicting nCell values were found for sample: " + sample_id)
            ncells[sample_id] = ncell

with open(marker_file, encoding="utf-8") as handle:
    reader = csv.DictReader(handle, delimiter="\t")
    required = {"sample_id", "marker_name", "mean_coverage", "trimmed_mean_coverage"}
    if not reader.fieldnames or not required.issubset(reader.fieldnames):
        raise SystemExit("The marker table is missing required columns: " + ", ".join(sorted(required)))
    input_fields = reader.fieldnames
    rows = list(reader)

output_fields = input_fields + ["nCell", "copies_per_cell", "trimmed_mean_copies_per_cell"]
human_markers = {"crAssphage", "PhiCrAss001"}
human_values = {}

with (output_dir / "fecal-marker-copies-per-cell.tsv").open("w", encoding="utf-8", newline="") as handle:
    writer = csv.DictWriter(handle, fieldnames=output_fields, delimiter="\t", lineterminator="\n")
    writer.writeheader()
    for row in rows:
        sample_id = row["sample_id"]
        if sample_id not in ncells:
            raise SystemExit("No nCell value was found for sample: " + sample_id)
        ncell = ncells[sample_id]
        copies_per_cell = float(row["mean_coverage"]) / ncell
        trimmed_copies_per_cell = float(row["trimmed_mean_coverage"]) / ncell
        row.update({"nCell": number(ncell), "copies_per_cell": number(copies_per_cell), "trimmed_mean_copies_per_cell": number(trimmed_copies_per_cell)})
        writer.writerow(row)
        if row["marker_name"] in human_markers:
            human_values.setdefault(sample_id, {})[row["marker_name"]] = copies_per_cell

combined_fields = ["sample_id", "nCell", "crAssphage_copies_per_cell", "PhiCrAss001_copies_per_cell", "human_fecal_markers_combined_copies_per_cell"]
with (output_dir / "human-fecal-markers-combined.tsv").open("w", encoding="utf-8", newline="") as handle:
    writer = csv.DictWriter(handle, fieldnames=combined_fields, delimiter="\t", lineterminator="\n")
    writer.writeheader()
    for sample_id in sorted(human_values):
        missing = human_markers.difference(human_values[sample_id])
        if missing:
            raise SystemExit("Missing human fecal marker(s) for " + sample_id + ": " + ", ".join(sorted(missing)))
        crassphage = human_values[sample_id]["crAssphage"]
        phicrass001 = human_values[sample_id]["PhiCrAss001"]
        writer.writerow({"sample_id": sample_id, "nCell": number(ncells[sample_id]), "crAssphage_copies_per_cell": number(crassphage), "PhiCrAss001_copies_per_cell": number(phicrass001), "human_fecal_markers_combined_copies_per_cell": number(crassphage + phicrass001)})

print("Normalized fecal-marker tables were written to: " + os.fspath(output_dir))
