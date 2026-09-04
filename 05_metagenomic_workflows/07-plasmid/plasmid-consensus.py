#!/usr/bin/env python3

import csv
import sys


if len(sys.argv) not in {5, 6}:
    print("Usage: python plasmid-consensus.py plasflow.tsv plasclass.tsv plasme.fa consensus.tsv [plasclass_threshold]")
    sys.exit(1)

plasclass_threshold = float(sys.argv[5]) if len(sys.argv) == 6 else 0.5
plasflow_all = set()
plasflow_positive = set()

with open(sys.argv[1], encoding="utf-8") as handle:
    reader = csv.DictReader(handle, delimiter="\t")
    for row in reader:
        contig_id = row["contig_name"].lstrip(">")
        plasflow_all.add(contig_id)
        if row["label"].lower().startswith("plasmid"):
            plasflow_positive.add(contig_id)

plasclass_all = set()
plasclass_positive = set()
with open(sys.argv[2], encoding="utf-8") as handle:
    for line in handle:
        fields = line.rstrip("\n").split("\t")
        if len(fields) >= 2:
            contig_id = fields[0].lstrip(">")
            plasclass_all.add(contig_id)
            if float(fields[1]) >= plasclass_threshold:
                plasclass_positive.add(contig_id)

plasme_positive = set()
with open(sys.argv[3], encoding="utf-8") as handle:
    for line in handle:
        if line.startswith(">"):
            plasme_positive.add(line[1:].strip().split()[0])

all_contigs = plasflow_all | plasclass_all | plasme_positive
with open(sys.argv[4], "w", encoding="utf-8") as output:
    output.write("contig_id\tPlasFlow\tPlasClass\tPLASMe\tvotes\tplasmid_consensus\n")
    for contig_id in sorted(all_contigs):
        votes = int(contig_id in plasflow_positive) + int(contig_id in plasclass_positive) + int(contig_id in plasme_positive)
        output.write("\t".join([contig_id, str(int(contig_id in plasflow_positive)), str(int(contig_id in plasclass_positive)), str(int(contig_id in plasme_positive)), str(votes), str(int(votes >= 2))]) + "\n")
