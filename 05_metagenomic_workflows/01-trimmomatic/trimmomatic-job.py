#!/usr/bin/env python3
# Trimmomatic v0.39.

import os
import shlex
import sys


if len(sys.argv) != 4:
    print("Usage: python trimmomatic-job.py sample_list.txt project_directory adapters.fa")
    sys.exit(1)

sample_list = sys.argv[1]
project_dir = os.path.abspath(sys.argv[2])
adapter_file = os.path.abspath(sys.argv[3])
job_dir = os.path.join(project_dir, "slurm_jobs", "trimmomatic")
log_dir = os.path.join(job_dir, "logs")

os.makedirs(job_dir, exist_ok=True)
os.makedirs(log_dir, exist_ok=True)

with open(sample_list, encoding="utf-8") as sample_file:
    for line in sample_file:
        sample_id = line.strip()
        if not sample_id or sample_id.startswith("#"):
            continue

        raw_read1 = os.path.join(project_dir, "rawdata", sample_id + "_1.fastq")
        raw_read2 = os.path.join(project_dir, "rawdata", sample_id + "_2.fastq")
        paired_read1 = os.path.join(project_dir, "1-Trim", "PE", sample_id + "_1.fq")
        paired_read2 = os.path.join(project_dir, "1-Trim", "PE", sample_id + "_2.fq")
        unpaired_read1 = os.path.join(project_dir, "1-Trim", "SE", sample_id + "_1.se.fq")
        unpaired_read2 = os.path.join(project_dir, "1-Trim", "SE", sample_id + "_2.se.fq")
        fasta_read1 = os.path.join(project_dir, "1-Trim", "PE", sample_id + "_1.fa")
        fasta_read2 = os.path.join(project_dir, "1-Trim", "PE", sample_id + "_2.fa")
        job_file = os.path.join(job_dir, sample_id + ".trim.job")

        with open(job_file, "w", encoding="utf-8") as qsubFile:
            qsubFile.write("#!/bin/bash\n")
            qsubFile.write("#SBATCH --time=02:00:00\n")
            qsubFile.write("#SBATCH --ntasks=1\n")
            qsubFile.write("#SBATCH --cpus-per-task=4\n")
            qsubFile.write("#SBATCH --mem=20G\n")
            qsubFile.write("#SBATCH --job-name=trim_" + sample_id + "\n")
            qsubFile.write("#SBATCH --output=" + shlex.quote(os.path.join(log_dir, "%x-%j.out")) + "\n")
            qsubFile.write("#SBATCH --error=" + shlex.quote(os.path.join(log_dir, "%x-%j.err")) + "\n\n")
            qsubFile.write("set -euo pipefail\n")
            qsubFile.write('source "$(conda info --base)/etc/profile.d/conda.sh"\n')
            qsubFile.write("conda activate trimmomatic\n")
            qsubFile.write("cd " + shlex.quote(project_dir) + "\n")
            qsubFile.write("mkdir -p 1-Trim/PE 1-Trim/SE\n")
            qsubFile.write("trimmomatic PE -threads 4 " + shlex.quote(raw_read1) + " " + shlex.quote(raw_read2) + " " + shlex.quote(paired_read1) + " " + shlex.quote(unpaired_read1) + " " + shlex.quote(paired_read2) + " " + shlex.quote(unpaired_read2) + " " + shlex.quote("ILLUMINACLIP:" + adapter_file + ":2:30:10") + " LEADING:3 TRAILING:3 SLIDINGWINDOW:4:20 MINLEN:50\n")
            qsubFile.write("seqkit fq2fa " + shlex.quote(paired_read1) + " -o " + shlex.quote(fasta_read1) + "\n")
            qsubFile.write("seqkit fq2fa " + shlex.quote(paired_read2) + " -o " + shlex.quote(fasta_read2) + "\n")
            qsubFile.write("pigz -p 4 " + shlex.quote(fasta_read1) + " " + shlex.quote(fasta_read2) + "\n")
            qsubFile.write("scontrol show job $SLURM_JOB_ID\n")

        os.chmod(job_file, 0o755)

print("Slurm jobs were generated in: " + job_dir)
