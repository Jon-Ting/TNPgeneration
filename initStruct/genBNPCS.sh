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
export lmp_sif="singularity exec /opt/apps/containers/lammps-20221215.sif lmp_serial"
HPC_CLUSTER=GADI  # GADI or CECS
EAM_DIR=../EAM/setfl_files
LMP_DATA_DIR=.
MNP_DIR=MNP
BNP_DIR=BNP
CS_DIR=CS
IN_TEMPLATE=genBNPCS.in
logFile=lmpBNPCS.log
latType=fcc
declare -a ELEMENT_ARR=('Au' 'Pd' 'Pt')
declare -a MASS_ARR=(196.97 106.42 195.08)
declare -a RADIUS_ARR=(1.44 1.37 1.39)
declare -a FCC_LC_ARR=(4.09 3.89 3.92)
declare -a SIZE_ARR=(10 15 20 25 30)
declare -a SHAPE_ARR=('SP')

# Create directories to store files generated
if test ! -d "$LMP_DATA_DIR"; then mkdir "$LMP_DATA_DIR"; fi
if test ! -d "$LMP_DATA_DIR/$BNP_DIR"; then mkdir "$LMP_DATA_DIR/$BNP_DIR"; fi
if test ! -d "$LMP_DATA_DIR/$BNP_DIR/$CS_DIR"; then mkdir "$LMP_DATA_DIR/$BNP_DIR/$CS_DIR"; fi
echo "Generating core-shell bimetallic nanoparticles:"
echo "-----------------------------------------------"
for ((i=0;i<${#ELEMENT_ARR[@]};i++)); do
    element1=${ELEMENT_ARR[$i]}
    mass1=${MASS_ARR[$i]}
    radius1=${RADIUS_ARR[$i]}
    for ((j=0;j<${#ELEMENT_ARR[@]};j++)); do
        element2=${ELEMENT_ARR[$j]}
        if [ $element1 == $element2 ]; then continue; fi
        mass2=${MASS_ARR[$j]}
        radius2=${RADIUS_ARR[$j]}
        delCutoff=$(echo "scale=3;($radius1+$radius2)/2" | bc)
        latConst=${FCC_LC_ARR[$j]}
        potFile="$EAM_DIR/$element1$element2.set"
        echo "$element2@$element1"
        # Check if EAM potential file exists
        if test -f $potFile; then echo "  Using $potFile"; else echo "  $potFile not found!"; fi
        for ((k=1;k<${#SIZE_ARR[@]};k++)); do
            size1=${SIZE_ARR[$k]}
            for ((l=0;l<$k;l++)); do
                size2=${SIZE_ARR[$l]}
                for ((m=0;m<${#SHAPE_ARR[@]};m++)); do
                    shape1=${SHAPE_ARR[$m]}
                    fileName1="$LMP_DATA_DIR/$MNP_DIR/$element1$size1$shape1.lmp"
                    xBoxSize1=$(grep 'xlo xhi' $fileName1 | awk '{print $2}')
                    yBoxSize1=$(grep 'ylo yhi' $fileName1 | awk '{print $2}')
                    zBoxSize1=$(grep 'zlo zhi' $fileName1 | awk '{print $2}')
                    for ((n=0;n<${#SHAPE_ARR[@]};n++)); do
                        shape2=${SHAPE_ARR[$n]}
                        fileName2="$LMP_DATA_DIR/$MNP_DIR/$element2$size2$shape2.lmp"
                        outFile="$LMP_DATA_DIR/$BNP_DIR/$CS_DIR/$element1$size1$shape1$element2$size2${shape2}CS.lmp"
                        # Check if the BNP has been generated
                        if test -f $outFile; then
                            echo "  $element1$size1$shape1$element2$size2${shape2}CS.lmp already exists, skipping...";
                            continue
                        else
                            echo "  Generating $element1$size1$shape1$element2$size2${shape2}CS.lmp..."; fi
                        # Compute shifts in atoms when reading the core MNP
                        xBoxSize2=$(grep 'xlo xhi' $fileName2 | awk '{print $2}')
                        yBoxSize2=$(grep 'ylo yhi' $fileName2 | awk '{print $2}')
                        zBoxSize2=$(grep 'zlo zhi' $fileName2 | awk '{print $2}')
                        xShift=$(echo "scale=3;($xBoxSize1-$xBoxSize2)/2" | bc)
                        yShift=$(echo "scale=3;($yBoxSize1-$yBoxSize2)/2" | bc)
                        zShift=$(echo "scale=3;($zBoxSize1-$zBoxSize2)/2" | bc)
			if [ $HPC_CLUSTER == "GADI" ]; then
			    lmp_openmpi -in ${IN_TEMPLATE} \
                                        -var element1 $element1 \
                                        -var element2 $element2 \
                                        -var mass1 $mass1 \
                                        -var mass2 $mass2 \
                                        -var fileName1 $fileName1 \
                                        -var fileName2 $fileName2 \
                                        -var xShift ${xShift} \
                                        -var yShift ${yShift} \
                                        -var zShift ${zShift} \
                                        -var latType $latType \
                                        -var latConst $latConst \
                                        -var delCutoff $delCutoff \
                                        -var potFile $potFile \
                                        -var outFile $outFile \
                                        >> $logFile
			elif [ $HPC_CLUSTER == "CECS" ]; then
			    eval "$lmp_sif -in ${IN_TEMPLATE} \
                                       -var element1 $element1 \
                                       -var element2 $element2 \
                                       -var mass1 $mass1 \
                                       -var mass2 $mass2 \
                                       -var fileName1 $fileName1 \
                                       -var fileName2 $fileName2 \
                                       -var xShift ${xShift} \
                                       -var yShift ${yShift} \
                                       -var zShift ${zShift} \
                                       -var latType $latType \
                                       -var latConst $latConst \
                                       -var delCutoff $delCutoff \
                                       -var potFile $potFile \
                                       -var outFile $outFile \
                                       >> $logFile"
			fi
                        if [ $(grep -c 'DONE!' log.lammps) -eq 0 ]; then echo "  Error!"; else echo "  Done!"; fi
                    done
                done
            done
        done
    done
done
echo -e "All Done!\n"

