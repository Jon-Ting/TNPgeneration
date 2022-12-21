#!/bin/bash
#PBS -P hm62
#PBS -q normal
#PBS -l ncpus=48,walltime=24:00:00,mem=24GB,jobfs=24GB
#PBS -l storage=scratch/hm62
#PBS -l wd
#PBS -M Jonathan.Ting@anu.edu.au
#PBS -m a

module load python3
python3 $HOME/TNPgeneration/script/genDAPfiles_modified.py >> $HOME/TNPgeneration/script/runGenDAPfiles.log
