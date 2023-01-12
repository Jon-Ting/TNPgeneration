#!/bin/bash
#PBS -P q27
#PBS -q normal
#PBS -l ncpus=1,walltime=00:20:00,mem=30GB,jobfs=0GB
#PBS -l storage=scratch/p00
#PBS -l wd
#PBS -M Jonathan.Ting@anu.edu.au
#PBS -m a

module load python3/3.11.0

# python3 genCSVs.py  #PBS -l ncpus=1,walltime=00:20:00,mem=30GB,jobfs=0GB  #PBS -l ncpus=48,walltime=04:00:00,mem=30GB,jobfs=0GB
python3 mergeFeatures.py #PBS -l ncpus=48,walltime=01:00:00,mem=36GB,jobfs=0GB  #PBS -l ncpus=1,walltime=00:20:00,mem=25GB,jobfs=0GB
