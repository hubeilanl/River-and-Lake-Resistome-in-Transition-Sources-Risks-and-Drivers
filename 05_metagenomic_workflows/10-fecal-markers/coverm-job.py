#!/usr/bin/env python3

import os
import shlex
import sys


if len(sys.argv) != 4:
    print("Usage: python coverm-job.py sample_list.txt project_directory viral-crAss.fa")
    sys.exit(1)

sample_list = sys.argv[1]
project_dir = os.path.abspath(sys.argv[2])
reference_fasta = os.path.abspath(sys.argv[3])
job_dir = os.path.join(project_dir, "slurm_jobs", "coverm-fecal-markers")
log_dir = os.path.join(job_dir, "logs")
output_dir = os.path.join(project_dir, "coverm-fecal-markers")

os.makedirs(job_dir, exist_ok=True)
os.makedirs(log_dir, exist_ok=True)

with open(sample_list, encoding="utf-8") as sample_file:
    for line in sample_file:
        sample_id = line.strip()
        if not sample_id or sample_id.startswith("#"):
            continue

        read1 = os.path.join(project_dir, "1-Trim", "PE", sample_id + "_1.fa.gz")
        read2 = os.path.join(project_dir, "1-Trim", "PE", sample_id + "_2.fa.gz")
        output_file = os.path.join(output_dir, sample_id + ".coverm.tsv")
        job_file = os.path.join(job_dir, sample_id + ".coverm.job")

        with open(job_file, "w", encoding="utf-8") as qsubFile:
            qsubFile.write("#!/bin/bash\n")
            qsubFile.write("#SBATCH --time=72:00:00\n")
            qsubFile.write("#SBATCH --ntasks=1\n")
            qsubFile.write("#SBATCH --cpus-per-task=4\n")
            qsubFile.write("#SBATCH --mem=20G\n")
            qsubFile.write("#SBATCH --job-name=coverm_" + sample_id + "\n")
            qsubFile.write("#SBATCH --output=" + shlex.quote(os.path.join(log_dir, "%x-%j.out")) + "\n")
            qsubFile.write("#SBATCH --error=" + shlex.quote(os.path.join(log_dir, "%x-%j.err")) + "\n\n")
            qsubFile.write("set -euo pipefail\n")
            qsubFile.write('source "$(conda info --base)/etc/profile.d/conda.sh"\n')
            qsubFile.write("conda activate coverm\n")
            qsubFile.write("mkdir -p " + shlex.quote(output_dir) + "\n")
            qsubFile.write("coverm contig -m mean -m trimmed_mean -m length -m count -t 4 --coupled " + shlex.quote(read1) + " " + shlex.quote(read2) + " --reference " + shlex.quote(reference_fasta) + " -o " + shlex.quote(output_file) + " --output-format dense --min-read-aligned-length 75 --min-read-aligned-percent 75 --min-read-percent-identity 80\n")
            qsubFile.write("scontrol show job $SLURM_JOB_ID\n")

        os.chmod(job_file, 0o755)

print("Slurm jobs were generated in: " + job_dir)
