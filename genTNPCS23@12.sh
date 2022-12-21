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
EAM_DIR=./EAM/setfl_files
LMP_DATA_DIR=.
BNP_DIR=BNP
TNP_DIR=TNP
RAL_DIR=RAL
CRSR_DIR=CRSR
declare -a RATIO_LIST=(20 40 60 80)
RANDOM_DISTRIB_NO=3

IN_TEMPLATE=genTNPCS23@12.in
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

crsr() {
    # create directories for generation
    if test ! -d "$LMP_DATA_DIR"; then mkdir "$LMP_DATA_DIR"; fi
    if test ! -d "$LMP_DATA_DIR/$TNP_DIR"; then mkdir "$LMP_DATA_DIR/$TNP_DIR"; fi
    if test ! -d "$LMP_DATA_DIR/$TNP_DIR/$CRSR_DIR"; then mkdir "$LMP_DATA_DIR/$TNP_DIR/$CRSR_DIR"; fi
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
    potFile="$EAM_DIR/$element1$element2$element3.set"
    echo -e "($element2@$element3)@($element1@$element2)   CRSR"
    # Check if EAM potential file exists
    if test -f $potFile; then echo "  Using $potFile"; else echo "  $potFile not found!"; fi
    size1=${11}
    size2=${12}
    size3=${13}
    shape=${SHAPE_ARR[0]}
    for ((l=0;l<${#RATIO_LIST[@]};l++)); do
        for ((m=0;m<RANDOM_DISTRIB_NO;m++)); do
            fileName1="$LMP_DATA_DIR/$BNP_DIR/$RAL_DIR/$element1$element2$size1$shape${RATIO_LIST[$l]}$((100-${RATIO_LIST[$l]}))RAL$m.lmp"
            xBoxSize1=$(grep 'xlo xhi' $fileName1 | awk '{print $2}' | awk -F"E" 'BEGIN{OFMT="%10.10f"} {print $1 * (10 ^ $2)}')
            yBoxSize1=$(grep 'ylo yhi' $fileName1 | awk '{print $2}' | awk -F"E" 'BEGIN{OFMT="%10.10f"} {print $1 * (10 ^ $2)}')
            zBoxSize1=$(grep 'zlo zhi' $fileName1 | awk '{print $2}' | awk -F"E" 'BEGIN{OFMT="%10.10f"} {print $1 * (10 ^ $2)}')
            for ((n=0;n<${#RATIO_LIST[@]};n++)); do
                for ((o=0;o<RANDOM_DISTRIB_NO;o++)); do
                    fileName2="$LMP_DATA_DIR/$BNP_DIR/$RAL_DIR/$element2$element3$size3$shape${RATIO_LIST[$n]}$((100-${RATIO_LIST[$n]}))RAL$o.lmp"
                    outFile="$LMP_DATA_DIR/$TNP_DIR/$CRSR_DIR/$element1$element2$size1$element2$element3$size3$shape${RATIO_LIST[$l]}$((100-${RATIO_LIST[$l]}))${RATIO_LIST[$n]}$((100-${RATIO_LIST[$n]}))CRSR$m$o.lmp"
                    # Check if the TNP has been generated
                    if test -f $outFile; then
                        echo "  $element1$element2$size1$element2$element3$size3$shape${RATIO_LIST[$l]}$((100-${RATIO_LIST[$l]}))${RATIO_LIST[$n]}$((100-${RATIO_LIST[$n]}))CRSR$m$o.lmp already generated, skipping...";
                        continue
                    else
                        echo "  Generating $element1$element2$size1$element2$element3$size3$shape${RATIO_LIST[$l]}$((100-${RATIO_LIST[$l]}))${RATIO_LIST[$n]}$((100-${RATIO_LIST[$n]}))CRSR$m$o.lmp ..."; fi
                    # Compute shifts in atoms when reading the core
                    xBoxSize2=$(grep 'xlo xhi' $fileName2 | awk '{print $2}' | awk -F"E" 'BEGIN{OFMT="%10.10f"} {print $1 * (10 ^ $2)}')
                    yBoxSize2=$(grep 'ylo yhi' $fileName2 | awk '{print $2}' | awk -F"E" 'BEGIN{OFMT="%10.10f"} {print $1 * (10 ^ $2)}')
                    zBoxSize2=$(grep 'zlo zhi' $fileName2 | awk '{print $2}' | awk -F"E" 'BEGIN{OFMT="%10.10f"} {print $1 * (10 ^ $2)}')
                    xShift=$(echo "scale=3;($xBoxSize1-$xBoxSize2)/2" | bc)
                    yShift=$(echo "scale=3;($yBoxSize1-$yBoxSize2)/2" | bc)
                    zShift=$(echo "scale=3;($zBoxSize1-$zBoxSize2)/2" | bc)
		    if [ $HPC_CLUSTER == "GADI" ]; then
		        lmp_openmpi -in ${IN_TEMPLATE} \
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
		    elif [ $HPC_CLUSTER == "CECS" ]; then
		        eval "$lmp_sif -in ${IN_TEMPLATE} \
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
				       >> $logFile"
		    fi
                    if [ $(grep -c 'DONE!' log.lammps) -eq 0 ]; then echo "  Error!"; else echo "  Done!"; fi
                done
            done
        done
    done
}

echo "Generating core-shell trimetallic nanoparticles:"
for ((i=0;i<3;i++)); do
    for ((j=0;j<3;j++)); do
        if [ $i -eq $j ]; then continue; fi
        for ((k=0;k<3;k++)); do
            if [[ $k -eq $i || $k -eq $j ]]; then continue; fi
            crsr   "${ELEMENT_ARR[$i]}" "${MASS_ARR[$i]}" "${RADIUS_ARR[$i]}" \
                    "${ELEMENT_ARR[$j]}" "${MASS_ARR[$j]}" "${RADIUS_ARR[$j]}" \
                    "${ELEMENT_ARR[$k]}" "${MASS_ARR[$k]}" "${RADIUS_ARR[$k]}" \
                    "${FCC_LC_ARR[$k]}" 30 20 10
        done
    done
done

echo -e "All Done!\n"
