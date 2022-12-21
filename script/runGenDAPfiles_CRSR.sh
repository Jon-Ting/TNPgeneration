#!/bin/bash
#PBS -P hm62
#PBS -q normal
#PBS -l ncpus=1,walltime=24:10:12,mem=24GB,jobfs=24GB
#PBS -l storage=scratch/hm62
#PBS -l wd
#PBS -M Jonathan.Ting@anu.edu.au
#PBS -m a

module load python3
python3 $HOME/TNPgeneration/script/genDAPfiles_CRSR.py 
