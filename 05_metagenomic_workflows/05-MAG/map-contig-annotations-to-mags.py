#!/usr/bin/env python3

import os
import sys


if len(sys.argv) != 5:
    print("Usage: python map-contig-annotations-to-mags.py mag_list.tsv ARG_result_directory MGE_result_directory output_directory")
    sys.exit(1)

mag_list = sys.argv[1]
arg_dir = os.path.abspath(sys.argv[2])
mge_dir = os.path.abspath(sys.argv[3])
output_dir = os.path.abspath(sys.argv[4])
os.makedirs(output_dir, exist_ok=True)


def fasta_ids(path):
    identifiers = set()
    with open(path, encoding="utf-8") as handle:
        for line in handle:
            if line.startswith(">"):
                identifiers.add(line[1:].strip().split()[0])
    return identifiers


def load_annotations(path):
    annotations = {}
    with open(path, encoding="utf-8") as handle:
        for line in handle:
            fields = line.rstrip("\n").split("\t")
            if fields and fields[0]:
                annotations.setdefault(fields[0], []).append(fields)
    return annotations


arg_cache = {}
mge_cache = {}
arg_header = ["sample_id", "MAG_id", "contig_id", "subject_id", "identity", "alignment_length", "mismatches", "gap_opens", "query_start", "query_end", "subject_start", "subject_end", "evalue", "bitscore", "query_length", "subject_length", "ARG_type", "ARG_subtype"]
mge_header = ["sample_id", "MAG_id", "contig_id", "subject_id", "identity", "alignment_length", "mismatches", "gap_opens", "query_start", "query_end", "subject_start", "subject_end", "evalue", "bitscore", "query_length", "subject_length"]

with open(os.path.join(output_dir, "MAG-ARG-annotations.tsv"), "w", encoding="utf-8") as arg_output, open(os.path.join(output_dir, "MAG-MGE-annotations.tsv"), "w", encoding="utf-8") as mge_output:
    arg_output.write("\t".join(arg_header) + "\n")
    mge_output.write("\t".join(mge_header) + "\n")
    with open(mag_list, encoding="utf-8") as handle:
        for line in handle:
            fields = line.rstrip("\n").split("\t")
            if len(fields) != 3 or fields[0] == "sample_id":
                continue
            sample_id, mag_id, mag_fasta = fields
            if sample_id not in arg_cache:
                arg_cache[sample_id] = load_annotations(os.path.join(arg_dir, sample_id + ".annotated.tsv"))
                mge_cache[sample_id] = load_annotations(os.path.join(mge_dir, sample_id + ".result.tsv"))
            for contig_id in fasta_ids(mag_fasta):
                for annotation in arg_cache[sample_id].get(contig_id, []):
                    arg_output.write("\t".join([sample_id, mag_id] + annotation) + "\n")
                for annotation in mge_cache[sample_id].get(contig_id, []):
                    mge_output.write("\t".join([sample_id, mag_id] + annotation) + "\n")
