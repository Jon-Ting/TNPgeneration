#!/bin/bash
# Goal: Submit jobs efficiently to NCI Gadi following modification of job scripts
# Author: Jonathan Yik Chang Ting
# Modified by Kaihan Lu as Project Request
# Date: 15/12/2020

SIM_DATA_DIR=/scratch/$PROJECT/$USER
SCRIPT_DIR=/g/data/$PROJECT/$USER/TNPgeneration/script
EXAM_LOCK=examine.lock; JOB_LIST=jobList; QUEUE_LIST=queueList; SCRIPT=runAnneal.sh

maxQueueNum=50; numInQueue=$(qselect -u $USER | wc -l); numToSub=$(echo "$maxQueueNum-$numInQueue" | bc)  # qselect: select from queue is for your name; wc := word count per line; -u := username.
echo -e "maxQueueNum: $maxQueueNum\nnumInQueue: $numInQueue\nnumToSub: $numToSub"; cd $SIM_DATA_DIR  # echo := print parameter after this command; -e := in this case, \n is translated to making a new line, similarly, \t can be translated to be tab. If lost -e them \n will be printed directly without function.
for (( a=0; $a<$numToSub; a++ )); do  # a := the current iteration number; a++ := a=a+1
    numJobLeft=$(wc -l $SIM_DATA_DIR/$JOB_LIST | awk '{print $1}')  # awk can search objects by column, grep := search them by row.
    if [ $numJobLeft -eq 0 ]; then echo -e "\nNo more job in $JOB_LIST"; exit 0; else echo -e "\n$numJobLeft job(s) in $JOB_LIST"; fi
    i=0; maxIter=100
    while [ $i -lt $maxIter ]; do 
        if test -f $EXAM_LOCK; then sleep 1; i=$[$i+1]
        else
            touch $EXAM_LOCK; jobName=$(head -n1 $JOB_LIST); tail -n+2 $JOB_LIST > $JOB_LIST.2; mv $JOB_LIST.2 $JOB_LIST || continue; break; fi
    done
    # jobName=/scratch/q27/jt5911/SimAnneal/L10/AuCo20COL10/AuCo20COL10S1  #DEBUG
    if [ $i -gt $maxIter ]; then echo "Waited for too long! Check $EXAM_LOCK"; exit 1; fi
    if grep -q "re" <<< "${jobName: -2}"; then initName=${jobName::-2}; else initName=$jobName; fi
    initStruct=$(grep read_data ${initName::-1}0.in | awk '{print $2}')
    numAtoms=$(grep atoms $initStruct | awk '{print $1}')
    ncpus=$(echo "scale=0; (($numAtoms-1)/64000+1) * 1" | bc)
    numNode=$(echo "scale=0; ($ncpus-1)/48 + 1" | bc)
    mem=$(echo "scale=0; ($numAtoms/360000 + 1) * $ncpus/2" | bc)  # GB (for S0 only at the moment)
    wallTime=$(echo "(36*$numAtoms) / $ncpus" | bc)  # s
    #mem=$(echo "scale=0; (-($numAtoms-320000)*($numAtoms-320000)/40000000000+8) * $numNode" | bc)  # GB (for S0 only at the moment)
    # wallTime=$(echo "(36*$numAtoms+360000) / $ncpus" | bc)  # s
    if grep -q "S1" <<< "${initName: -2}"; then
        mem=$(echo "scale=0; (($mem*0.6)+1) / 1" | bc); wallTime=$(echo "scale=0; ($wallTime*3) / 1" | bc); echo "Adjusted S1 mem & wallTime!"
        if [ $wallTime -gt 172800 ]; then wallTime=172800; echo "Limited wallTime!"; fi
    elif grep -q "S2" <<< "${initName: -2}"; then
        mem=$(echo "scale=0; (($mem*0.8)+1) / 1" | bc); wallTime=$(echo "scale=0; ($wallTime*4) / 1" | bc); echo "Adjusted S2 mem & wallTime!"
        if [ $wallTime -gt 172800 ]; then wallTime=172800; echo "Limited wallTime!"; fi
    fi
    hr=$(printf "%02d\n" $(echo "scale=0; $wallTime / 60 / 60" | bc))  # hr
    min=$(printf "%02d\n" $(echo "scale=0; ($wallTime-$hr*60*60) / 60" | bc))  # min
    sec=$(printf "%02d\n" $(echo "scale=0; $wallTime - $hr*60*60 - $min*60" | bc))  # s
    sed -i "0,/^.*-l ncpus=.*$/s//#PBS -l ncpus=$ncpus,walltime=$hr:$min:$sec,mem=${mem}GB,jobfs=10GB/" $SCRIPT_DIR/$SCRIPT
    sed -i "0,/^.*mpirun.*$/s//mpirun -np $ncpus lmp_openmpi -sf opt -in \$jobName.in > \$initName.log/" $SCRIPT_DIR/$SCRIPT
    qsub -v jobName=$jobName $SCRIPT_DIR/$SCRIPT; sleep 1; echo $jobName >> $QUEUE_LIST; rm -f $EXAM_LOCK
    echo -e "Submitted $jobName\nnumAtoms,ncpus,walltime,mem = $numAtoms,$ncpus,$hr:$min:$sec,$mem"
done
qstat -Ewatu $USER; echo "$(qstat -Eu $USER | wc -l) - 5" | bc | xargs printf "%s jobs in queue!\n"
