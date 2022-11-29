#!/bin/bash
# Script to generate core-shell bimetallic nanoparticles (CS BNPs).
# Feed different parameters into the LAMMPS input template file genBNPCS.in
# Author: Jonathan Yik Chang Ting
# Date: 29/10/2020
# Atomic mass taken from 
# Metallic radii taken from Greenwood, Norman N.; Earnshaw, Alan (1997). Chemistry of the Elements (2nd ed.). Butterworth-Heinemann. ISBN 978-0-08-037941-8

# To do:
# - Add atomic mass reference
# - Validate potential files

# Define variables
EAM_DIR=/home/bill-peng/Projects/BNPs/EAM/setfl_files
LMP_DATA_DIR=/home/bill-peng/Projects/BNPs
MNP_DIR=MNP
BNP_DIR=BNP
TNP_DIR=TNP
CS_DIR=CS
IN_TEMPLATE=genTNPCS.in
logFile=lmpBNPCS.log
latType=fcc
declare -a ELEMENT_ARR=('Au' 'Pd' 'Pt')
# declare -a ELEMENT_ARR=('Au' 'Pt' 'Pd' 'Co')
# declare -a MASS_ARR=(58.933 106.42 195.08 196.97)
declare -a MASS_ARR=(196.97 106.42 195.08)
# declare -a RADIUS_ARR=(1.25 1.37 1.39 1.44)
declare -a RADIUS_ARR=(1.44 1.37 1.39)
# declare -a FCC_LC_ARR=(3.537 3.89 3.92 4.09)
declare -a FCC_LC_ARR=(4.09 3.89 3.92)
# declare -a SHAPE_ARR=('CU' 'TH' 'RD' 'OT' 'TO' 'CO' 'DH' 'IC')
declare -a SHAPE_ARR=('SP')

overlapThree3@12() {
    echo "Generating core-shell trimetallic nanoparticles:"
    echo "-----------------------------------------------"
    element1=$1 # shell element
    mass1=$2
    radius1=$3
    element2=$4 # intermediate element
    mass2=$5
    radius2=$6
    element3=$7 # core element
    mass3=$8
    radius3=$9
    delCutoff1=$(echo "scale=3;$radius1+$radius3" | bc)
    delCutoff2=$(echo "scale=3;$radius2+$radius3" | bc)
    latConst=${10} # FCC_LC_ARR of the core (ie. element3)
    potFile="$EAM_DIR/AuPtPd.set"
    echo -e "$element1@$element3 $delCutoff1 & \c"
    echo "$element2@$element3 $delCutoff2"
    # Check if EAM potential file exists
    if test -f $potFile; then echo "  Using $potFile"; else echo "  $potFile not found!"; fi
    size1=${11}
    size2=${12}
    size3=${13}
    shape1=${SHAPE_ARR[0]}
    shape2=${SHAPE_ARR[0]}
    shape3=${SHAPE_ARR[0]}
    fileName1="$LMP_DATA_DIR/$BNP_DIR/$CS_DIR/$element1$size1$shape1$element2$size2${shape2}CS.lmp"
    xBoxSize1=$(grep 'xlo xhi' $fileName1 | awk '{print $2}' | awk -F"E" 'BEGIN{OFMT="%10.10f"} {print $1 * (10 ^ $2)}')
    yBoxSize1=$(grep 'ylo yhi' $fileName1 | awk '{print $2}' | awk -F"E" 'BEGIN{OFMT="%10.10f"} {print $1 * (10 ^ $2)}')
    zBoxSize1=$(grep 'zlo zhi' $fileName1 | awk '{print $2}' | awk -F"E" 'BEGIN{OFMT="%10.10f"} {print $1 * (10 ^ $2)}')
    fileName2="$LMP_DATA_DIR/$MNP_DIR/$element3$size3$shape3.lmp"
    outFile="$LMP_DATA_DIR/$TNP_DIR/$CS_DIR/$element1$size1$shape1$element2$size2$shape2$element3$size3${shape3}CS.lmp"
    # Check if the TNP has been generated
    if test -f $outFile; then
        echo "  $element1$size1$shape1$element2$size2$shape2$element3$size3${shape3}CS.lmp already generated, skipping...";
        return
    else
        echo "  Generating $element1$size1$shape1$element2$size2$shape2$element3$size3${shape3}CS.lmp ..."; fi
    # Compute shifts in atoms when reading the core
    xBoxSize2=$(grep 'xlo xhi' $fileName2 | awk '{print $2}' | awk -F"E" 'BEGIN{OFMT="%10.10f"} {print $1 * (10 ^ $2)}')
    yBoxSize2=$(grep 'ylo yhi' $fileName2 | awk '{print $2}' | awk -F"E" 'BEGIN{OFMT="%10.10f"} {print $1 * (10 ^ $2)}')
    zBoxSize2=$(grep 'zlo zhi' $fileName2 | awk '{print $2}' | awk -F"E" 'BEGIN{OFMT="%10.10f"} {print $1 * (10 ^ $2)}')
    xShift=$(echo "scale=3;($xBoxSize1-$xBoxSize2)/2" | bc)
    yShift=$(echo "scale=3;($yBoxSize1-$yBoxSize2)/2" | bc)
    zShift=$(echo "scale=3;($zBoxSize1-$zBoxSize2)/2" | bc)
    lmp -in ${IN_TEMPLATE} \
                -var element1 $element1 \
                -var element2 $element2 \
                -var element3 $element3 \
                -var mass1 $mass1 \
                -var mass2 $mass2 \
                -var mass3 $mass3 \
                -var fileName1 $fileName1 \
                -var fileName2 $fileName2 \
                -var xShift ${xShift} \
                -var yShift ${yShift} \
                -var zShift ${zShift} \
                -var latType $latType \
                -var latConst $latConst \
                -var delCutoff $delCutoff1 \
                -var potFile $potFile \
                -var outFile $outFile \
                >> $logFile
    if [ $(grep -c 'DONE!' log.lammps) -eq 0 ]; then echo "  Error!"; else echo "  Done!"; fi
}

overlapThree3@12 ${ELEMENT_ARR[0]} ${MASS_ARR[0]} ${RADIUS_ARR[0]} \
                 ${ELEMENT_ARR[1]} ${MASS_ARR[1]} ${RADIUS_ARR[1]} \
                 ${ELEMENT_ARR[2]} ${MASS_ARR[2]} ${RADIUS_ARR[2]} \
                 ${FCC_LC_ARR[2]} 30 20 10

echo -e "Done!\n"

