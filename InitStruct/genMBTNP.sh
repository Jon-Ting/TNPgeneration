#!/bin/bash
# Script to generate all monometallic, bimetallic, and trimetallic nanoparticles from scratch. 
# Author: Jonathan Yik Chang Ting
# Date: 15/12/2022

python3 genMNP.py
python3 genBNPAL.py
bash genBNPCS.sh
python3 genTNPAL.py
bash genTNPCS23\@1.sh
bash genTNPCS23\@12.sh
bash genTNPCS3\@12.sh
