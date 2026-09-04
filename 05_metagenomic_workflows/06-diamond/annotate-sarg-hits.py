#!/usr/bin/env python3

import sys


if len(sys.argv) != 5:
    print("Usage: python annotate-sarg-hits.py filtered_hits.tsv Type.map subtype.map annotated_hits.tsv")
    sys.exit(1)


def load_map(path):
    mapping = {}
    with open(path, encoding="utf-8") as handle:
        for line in handle:
            fields = line.rstrip("\n").split("\t")
            if len(fields) >= 2 and fields[0] != "SARG.Seq.ID":
                mapping[fields[0]] = fields[1]
    return mapping


type_map = load_map(sys.argv[2])
subtype_map = load_map(sys.argv[3])

with open(sys.argv[1], encoding="utf-8") as source, open(sys.argv[4], "w", encoding="utf-8") as output:
    for line in source:
        fields = line.rstrip("\n").split("\t")
        if len(fields) >= 2:
            output.write(line.rstrip("\n") + "\t" + type_map.get(fields[1], "NA") + "\t" + subtype_map.get(fields[1], "NA") + "\n")
