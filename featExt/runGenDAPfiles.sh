#!/bin/bash
#PBS -P hm62
#PBS -q normal
#PBS -l ncpus=48,walltime=05:00:00,mem=128GB,jobfs=0GB
#PBS -l storage=scratch/hm62+scratch/p00
#PBS -l wd
#PBS -M Jonathan.Ting@anu.edu.au
#PBS -m a

module load python3
python3 $HOME/TNPgeneration/featExt/genDAPfiles.py > $HOME/TNPgeneration/featExt/runGenDAPfiles.log
