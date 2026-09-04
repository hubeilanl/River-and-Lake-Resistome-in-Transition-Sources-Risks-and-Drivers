#!/usr/bin/env python3

import os
import shlex
import sys


if len(sys.argv) != 4:
    print("Usage: python kraken-bracken-job.py sample_list.txt project_directory kraken_database")
    sys.exit(1)

sample_list = sys.argv[1]
project_dir = os.path.abspath(sys.argv[2])
kraken_database = os.path.abspath(sys.argv[3])
job_dir = os.path.join(project_dir, "slurm_jobs", "kraken-bracken")
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
        kraken_dir = os.path.join(project_dir, "01-Kraken2")
        bracken_dir = os.path.join(project_dir, "02-Bracken")
        report_file = os.path.join(kraken_dir, sample_id + ".report")
        job_file = os.path.join(job_dir, sample_id + ".kraken_bracken.job")

        with open(job_file, "w", encoding="utf-8") as qsubFile:
            qsubFile.write("#!/bin/bash\n")
            qsubFile.write("#SBATCH --time=04:00:00\n")
            qsubFile.write("#SBATCH --ntasks=1\n")
            qsubFile.write("#SBATCH --cpus-per-task=4\n")
            qsubFile.write("#SBATCH --mem=70G\n")
            qsubFile.write("#SBATCH --job-name=kraken_" + sample_id + "\n")
            qsubFile.write("#SBATCH --output=" + shlex.quote(os.path.join(log_dir, "%x-%j.out")) + "\n")
            qsubFile.write("#SBATCH --error=" + shlex.quote(os.path.join(log_dir, "%x-%j.err")) + "\n\n")
            qsubFile.write("set -euo pipefail\n")
            qsubFile.write('source "$(conda info --base)/etc/profile.d/conda.sh"\n')
            qsubFile.write("conda activate kraken2\n")
            qsubFile.write("cd " + shlex.quote(project_dir) + "\n")
            qsubFile.write("mkdir -p " + shlex.quote(kraken_dir) + " " + shlex.quote(bracken_dir) + "\n")
            qsubFile.write("kraken2 --db " + shlex.quote(kraken_database) + " --threads 4 --paired --report " + shlex.quote(report_file) + " --output " + shlex.quote(os.path.join(kraken_dir, sample_id + ".output")) + " " + shlex.quote(read1) + " " + shlex.quote(read2) + "\n")
            qsubFile.write("conda activate bracken\n")
            qsubFile.write("for level in D P C O F G; do bracken -d " + shlex.quote(kraken_database) + " -i " + shlex.quote(report_file) + " -o " + shlex.quote(os.path.join(bracken_dir, sample_id)) + ".${level}.tsv -l ${level}; done\n")
            qsubFile.write("scontrol show job $SLURM_JOB_ID\n")

        os.chmod(job_file, 0o755)

print("Slurm jobs were generated in: " + job_dir)
