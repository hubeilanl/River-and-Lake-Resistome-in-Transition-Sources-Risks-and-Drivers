#!/usr/bin/env python3
# MetaWRAP v1.3.2.

import os
import shlex
import sys


if len(sys.argv) != 3:
    print("Usage: python metawrap-job.py sample_list.txt project_directory")
    sys.exit(1)

sample_list = sys.argv[1]
project_dir = os.path.abspath(sys.argv[2])
job_dir = os.path.join(project_dir, "slurm_jobs", "metawrap")
log_dir = os.path.join(job_dir, "logs")

os.makedirs(job_dir, exist_ok=True)
os.makedirs(log_dir, exist_ok=True)

with open(sample_list, encoding="utf-8") as sample_file:
    for line in sample_file:
        sample_id = line.strip()
        if not sample_id or sample_id.startswith("#"):
            continue

        read1 = os.path.join(project_dir, "1-Trim", "PE", sample_id + "_1.fq")
        read2 = os.path.join(project_dir, "1-Trim", "PE", sample_id + "_2.fq")
        contigs = os.path.join(project_dir, "all_contigs", sample_id + ".fa")
        binning_dir = os.path.join(project_dir, "M-Bin", sample_id + "_Bin")
        refinement_dir = os.path.join(project_dir, "M-Bin", sample_id + "_Refinement")
        job_file = os.path.join(job_dir, sample_id + ".metawrap.job")

        with open(job_file, "w", encoding="utf-8") as qsubFile:
            qsubFile.write("#!/bin/bash\n")
            qsubFile.write("#SBATCH --time=72:00:00\n")
            qsubFile.write("#SBATCH --ntasks=1\n")
            qsubFile.write("#SBATCH --cpus-per-task=16\n")
            qsubFile.write("#SBATCH --mem=128G\n")
            qsubFile.write("#SBATCH --job-name=metawrap_" + sample_id + "\n")
            qsubFile.write("#SBATCH --output=" + shlex.quote(os.path.join(log_dir, "%x-%j.out")) + "\n")
            qsubFile.write("#SBATCH --error=" + shlex.quote(os.path.join(log_dir, "%x-%j.err")) + "\n\n")
            qsubFile.write("set -euo pipefail\n")
            qsubFile.write('source "$(conda info --base)/etc/profile.d/conda.sh"\n')
            qsubFile.write("conda activate metawrap\n")
            qsubFile.write("cd " + shlex.quote(project_dir) + "\n")
            qsubFile.write("mkdir -p " + shlex.quote(os.path.join(project_dir, "M-Bin")) + "\n")
            qsubFile.write("metawrap binning -o " + shlex.quote(binning_dir) + " -t 16 -m 128 -a " + shlex.quote(contigs) + " --metabat2 --maxbin2 " + shlex.quote(read1) + " " + shlex.quote(read2) + "\n")
            qsubFile.write("metawrap bin_refinement -o " + shlex.quote(refinement_dir) + " -t 16 -m 128 -A " + shlex.quote(os.path.join(binning_dir, "metabat2_bins")) + " -B " + shlex.quote(os.path.join(binning_dir, "maxbin2_bins")) + " -c 70 -x 10\n")
            qsubFile.write("scontrol show job $SLURM_JOB_ID\n")

        os.chmod(job_file, 0o755)

print("Slurm jobs were generated in: " + job_dir)
