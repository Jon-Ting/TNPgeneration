#!/bin/bash
# Script to generate EAM potentials for alloys of interest.
# Includes the capability to move the generated setfl files to a specific directory.
# Currently designed only for binary and ternary alloys.
# Author: Jonathan Yik Chang Ting
# Date: 10/10/2020
# To do:
# - Eliminate the need to copy the EAM.input file, direcly modify a master copy
# - Generalize code into taking any number of elements

declare -a COMB_ARR=('Co Pd' 'Co Pt' 'Co Au' 'Pd Co' 'Pd Pt' 'Pd Au' 'Pt Co' 'Pt Pd' 'Pt Au' 'Au Co' 'Au Pd' 'Au Pt')
declare -a COMB_ARR=('Au Pd Pt' 'Au Pt Pd' 'Pd Au Pt' 'Pd Pt Au' 'Pt Au Pd' 'Pt Pd Au')
POT_FILE_DIR="setfl_files"

echo "Running script to generate EAM alloy potentials"
echo "-----------------------------------------------"
for comb in "${COMB_ARR[@]}"
do
    echo "$comb"
    cp EAM.input inp_file
    read -ra elements <<<"$comb"
    E1=${elements[0]}
    E2=${elements[1]}
    E3=${elements[2]}
    sed -i "s/E1/$E1/" inp_file
    sed -i "s/E2/$E2/" inp_file
    sed -i "s/E3/$E3/" inp_file
    ./EAM_generator < inp_file
    echo -e "Done!\n"
done
mv *.set $POT_FILE_DIR/
