#!/usr/bin/env python3
# PlasFlow v1.1, PlasClass v0.1.1, and PLASme v1.1.

import os
import shlex
import sys


if len(sys.argv) != 5:
    print("Usage: python plasmid-job.py sample_list.txt project_directory PLASMe.py PLASMe_database")
    sys.exit(1)

sample_list = sys.argv[1]
project_dir = os.path.abspath(sys.argv[2])
plasme_script = os.path.abspath(sys.argv[3])
plasme_database = os.path.abspath(sys.argv[4])
consensus_script = os.path.join(os.path.dirname(os.path.abspath(__file__)), "plasmid-consensus.py")
job_dir = os.path.join(project_dir, "slurm_jobs", "plasmid")
log_dir = os.path.join(job_dir, "logs")

os.makedirs(job_dir, exist_ok=True)
os.makedirs(log_dir, exist_ok=True)

with open(sample_list, encoding="utf-8") as sample_file:
    for line in sample_file:
        sample_id = line.strip()
        if not sample_id or sample_id.startswith("#"):
            continue

        contigs = os.path.join(project_dir, "ARGs_contigs", sample_id + ".ARGs.fa")
        plasflow_output = os.path.join(project_dir, "4-Plasmid", "plasflow", sample_id + ".tsv")
        plasclass_output = os.path.join(project_dir, "4-Plasmid", "plasclass", sample_id + ".tsv")
        plasme_output = os.path.join(project_dir, "4-Plasmid", "plasme", sample_id + ".fa")
        consensus_output = os.path.join(project_dir, "4-Plasmid", "consensus", sample_id + ".consensus.tsv")
        job_file = os.path.join(job_dir, sample_id + ".plasmid.job")

        with open(job_file, "w", encoding="utf-8") as qsubFile:
            qsubFile.write("#!/bin/bash\n")
            qsubFile.write("#SBATCH --time=24:00:00\n")
            qsubFile.write("#SBATCH --ntasks=1\n")
            qsubFile.write("#SBATCH --cpus-per-task=16\n")
            qsubFile.write("#SBATCH --mem=70G\n")
            qsubFile.write("#SBATCH --job-name=plasmid_" + sample_id + "\n")
            qsubFile.write("#SBATCH --output=" + shlex.quote(os.path.join(log_dir, "%x-%j.out")) + "\n")
            qsubFile.write("#SBATCH --error=" + shlex.quote(os.path.join(log_dir, "%x-%j.err")) + "\n\n")
            qsubFile.write("set -euo pipefail\n")
            qsubFile.write('source "$(conda info --base)/etc/profile.d/conda.sh"\n')
            qsubFile.write("cd " + shlex.quote(project_dir) + "\n")
            qsubFile.write("mkdir -p 4-Plasmid/plasflow 4-Plasmid/plasclass 4-Plasmid/plasme 4-Plasmid/consensus\n")
            qsubFile.write("conda activate plasflow\n")
            qsubFile.write("PlasFlow.py --input " + shlex.quote(contigs) + " --output " + shlex.quote(plasflow_output) + "\n")
            qsubFile.write("conda activate plasclass\n")
            qsubFile.write("classify_fasta.py -f " + shlex.quote(contigs) + " -o " + shlex.quote(plasclass_output) + " -p 16\n")
            qsubFile.write("conda activate plasme\n")
            qsubFile.write("python " + shlex.quote(plasme_script) + " " + shlex.quote(contigs) + " " + shlex.quote(plasme_output) + " -d " + shlex.quote(plasme_database) + " -t 16\n")
            qsubFile.write("python " + shlex.quote(consensus_script) + " " + shlex.quote(plasflow_output) + " " + shlex.quote(plasclass_output) + " " + shlex.quote(plasme_output) + " " + shlex.quote(consensus_output) + "\n")
            qsubFile.write("scontrol show job $SLURM_JOB_ID\n")

        os.chmod(job_file, 0o755)

print("Slurm jobs were generated in: " + job_dir)
