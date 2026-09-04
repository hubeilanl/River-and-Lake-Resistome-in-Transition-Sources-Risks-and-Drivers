#!/usr/bin/env python3
# ARGs-OAP v3.2.2 with SARG database v3.2.1.

import os
import shlex
import sys


if len(sys.argv) != 3:
    print("Usage: python args-oap-job.py sample_list.txt project_directory")
    sys.exit(1)

sample_list = sys.argv[1]
project_dir = os.path.abspath(sys.argv[2])
job_dir = os.path.join(project_dir, "slurm_jobs", "args-oap")
log_dir = os.path.join(job_dir, "logs")

os.makedirs(job_dir, exist_ok=True)
os.makedirs(log_dir, exist_ok=True)

with open(sample_list, encoding="utf-8") as sample_file:
    for line in sample_file:
        sample_id = line.strip()
        if not sample_id or sample_id.startswith("#"):
            continue

        input_dir = os.path.join(project_dir, "args_oap_input", sample_id)
        stage_one = os.path.join(project_dir, "one-args_oap", sample_id)
        stage_two = os.path.join(project_dir, "two-args_oap", sample_id)
        read1 = os.path.join(project_dir, "1-Trim", "PE", sample_id + "_1.fa.gz")
        read2 = os.path.join(project_dir, "1-Trim", "PE", sample_id + "_2.fa.gz")
        job_file = os.path.join(job_dir, sample_id + ".args_oap.job")

        with open(job_file, "w", encoding="utf-8") as qsubFile:
            qsubFile.write("#!/bin/bash\n")
            qsubFile.write("#SBATCH --time=72:00:00\n")
            qsubFile.write("#SBATCH --ntasks=1\n")
            qsubFile.write("#SBATCH --cpus-per-task=8\n")
            qsubFile.write("#SBATCH --mem=70G\n")
            qsubFile.write("#SBATCH --job-name=args_oap_" + sample_id + "\n")
            qsubFile.write("#SBATCH --output=" + shlex.quote(os.path.join(log_dir, "%x-%j.out")) + "\n")
            qsubFile.write("#SBATCH --error=" + shlex.quote(os.path.join(log_dir, "%x-%j.err")) + "\n\n")
            qsubFile.write("set -euo pipefail\n")
            qsubFile.write('source "$(conda info --base)/etc/profile.d/conda.sh"\n')
            qsubFile.write("conda activate args_oap\n")
            qsubFile.write("cd " + shlex.quote(project_dir) + "\n")
            qsubFile.write("mkdir -p " + shlex.quote(input_dir) + " " + shlex.quote(stage_one) + " " + shlex.quote(stage_two) + "\n")
            qsubFile.write("ln -sf " + shlex.quote(read1) + " " + shlex.quote(os.path.join(input_dir, sample_id + "_1.fa.gz")) + "\n")
            qsubFile.write("ln -sf " + shlex.quote(read2) + " " + shlex.quote(os.path.join(input_dir, sample_id + "_2.fa.gz")) + "\n")
            qsubFile.write("args_oap stage_one -i " + shlex.quote(input_dir) + " -f fa.gz -o " + shlex.quote(stage_one) + " -t 8\n")
            qsubFile.write("args_oap stage_two -i " + shlex.quote(stage_one) + " -o " + shlex.quote(stage_two) + " -t 8\n")
            qsubFile.write("scontrol show job $SLURM_JOB_ID\n")

        os.chmod(job_file, 0o755)

print("Slurm jobs were generated in: " + job_dir)
