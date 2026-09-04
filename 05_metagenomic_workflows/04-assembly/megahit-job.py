#!/usr/bin/env python3
# MEGAHIT v1.2.9.

import os
import shlex
import sys


if len(sys.argv) != 3:
    print("Usage: python megahit-job.py sample_list.txt project_directory")
    sys.exit(1)

sample_list = sys.argv[1]
project_dir = os.path.abspath(sys.argv[2])
job_dir = os.path.join(project_dir, "slurm_jobs", "megahit")
log_dir = os.path.join(job_dir, "logs")

os.makedirs(job_dir, exist_ok=True)
os.makedirs(log_dir, exist_ok=True)

with open(sample_list, encoding="utf-8") as sample_file:
    for line in sample_file:
        sample_id = line.strip()
        if not sample_id or sample_id.startswith("#"):
            continue

        read1 = os.path.join(project_dir, "1-Trim", "PE", sample_id + "_1.fa.gz")
        read2 = os.path.join(project_dir, "1-Trim", "PE", sample_id + "_2.fa.gz")
        assembly_dir = os.path.join(project_dir, "2-assembly", sample_id + "_megahit")
        contig_file = os.path.join(project_dir, "all_contigs", sample_id + ".fa")
        job_file = os.path.join(job_dir, sample_id + ".megahit.job")

        with open(job_file, "w", encoding="utf-8") as qsubFile:
            qsubFile.write("#!/bin/bash\n")
            qsubFile.write("#SBATCH --time=72:00:00\n")
            qsubFile.write("#SBATCH --ntasks=1\n")
            qsubFile.write("#SBATCH --cpus-per-task=24\n")
            qsubFile.write("#SBATCH --mem=160G\n")
            qsubFile.write("#SBATCH --job-name=megahit_" + sample_id + "\n")
            qsubFile.write("#SBATCH --output=" + shlex.quote(os.path.join(log_dir, "%x-%j.out")) + "\n")
            qsubFile.write("#SBATCH --error=" + shlex.quote(os.path.join(log_dir, "%x-%j.err")) + "\n\n")
            qsubFile.write("set -euo pipefail\n")
            qsubFile.write('source "$(conda info --base)/etc/profile.d/conda.sh"\n')
            qsubFile.write("conda activate megahit\n")
            qsubFile.write("cd " + shlex.quote(project_dir) + "\n")
            qsubFile.write("mkdir -p " + shlex.quote(os.path.join(project_dir, "2-assembly")) + " " + shlex.quote(os.path.join(project_dir, "all_contigs")) + "\n")
            qsubFile.write("megahit -t 24 -1 " + shlex.quote(read1) + " -2 " + shlex.quote(read2) + " -o " + shlex.quote(assembly_dir) + "\n")
            qsubFile.write("seqkit seq -m 200 -w 0 -g " + shlex.quote(os.path.join(assembly_dir, "final.contigs.fa")) + " -o " + shlex.quote(contig_file) + "\n")
            qsubFile.write("scontrol show job $SLURM_JOB_ID\n")

        os.chmod(job_file, 0o755)

print("Slurm jobs were generated in: " + job_dir)
