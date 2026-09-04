#!/usr/bin/env python3

import os
import shlex
import sys


if len(sys.argv) != 4:
    print("Usage: python diamond-mge-job.py sample_list.txt project_directory MGE_database.dmnd")
    sys.exit(1)

sample_list = sys.argv[1]
project_dir = os.path.abspath(sys.argv[2])
mge_database = os.path.abspath(sys.argv[3])
best_hit_script = os.path.join(os.path.dirname(os.path.abspath(__file__)), "get_BestHit_contig.py")
job_dir = os.path.join(project_dir, "slurm_jobs", "diamond-mge")
log_dir = os.path.join(job_dir, "logs")

os.makedirs(job_dir, exist_ok=True)
os.makedirs(log_dir, exist_ok=True)

with open(sample_list, encoding="utf-8") as sample_file:
    for line in sample_file:
        sample_id = line.strip()
        if not sample_id or sample_id.startswith("#"):
            continue

        contigs = os.path.join(project_dir, "ARGs_contigs", sample_id + ".ARGs.fa")
        raw_output = os.path.join(project_dir, "6-MGEs", "tsv", sample_id + ".tsv")
        sorted_output = os.path.join(project_dir, "6-MGEs", "best", sample_id + ".sorted.tsv")
        best_output = os.path.join(project_dir, "6-MGEs", "best", sample_id + ".best.tsv")
        result_output = os.path.join(project_dir, "6-MGEs", "result", sample_id + ".result.tsv")
        job_file = os.path.join(job_dir, sample_id + ".diamond_mge.job")

        with open(job_file, "w", encoding="utf-8") as qsubFile:
            qsubFile.write("#!/bin/bash\n")
            qsubFile.write("#SBATCH --time=12:00:00\n")
            qsubFile.write("#SBATCH --ntasks=1\n")
            qsubFile.write("#SBATCH --cpus-per-task=8\n")
            qsubFile.write("#SBATCH --mem=40G\n")
            qsubFile.write("#SBATCH --job-name=mge_" + sample_id + "\n")
            qsubFile.write("#SBATCH --output=" + shlex.quote(os.path.join(log_dir, "%x-%j.out")) + "\n")
            qsubFile.write("#SBATCH --error=" + shlex.quote(os.path.join(log_dir, "%x-%j.err")) + "\n\n")
            qsubFile.write("set -euo pipefail\n")
            qsubFile.write('source "$(conda info --base)/etc/profile.d/conda.sh"\n')
            qsubFile.write("conda activate diamond\n")
            qsubFile.write("cd " + shlex.quote(project_dir) + "\n")
            qsubFile.write("mkdir -p 6-MGEs/tsv 6-MGEs/best 6-MGEs/result\n")
            qsubFile.write("diamond blastx --db " + shlex.quote(mge_database) + " --query " + shlex.quote(contigs) + " --out " + shlex.quote(raw_output) + " --sensitive --outfmt 6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qlen slen --evalue 1e-5 --threads 8\n")
            qsubFile.write("sort -k1,1 -k12,12nr " + shlex.quote(raw_output) + " > " + shlex.quote(sorted_output) + "\n")
            qsubFile.write("python " + shlex.quote(best_hit_script) + " " + shlex.quote(sorted_output) + " " + shlex.quote(best_output) + "\n")
            qsubFile.write("awk '$3>=80 && $4/$14>=0.8' " + shlex.quote(best_output) + " > " + shlex.quote(result_output) + "\n")
            qsubFile.write("scontrol show job $SLURM_JOB_ID\n")

        os.chmod(job_file, 0o755)

print("Slurm jobs were generated in: " + job_dir)
