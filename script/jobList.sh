#!/bin/bash
# Goal: Script to generate and update the list of LAMMPS simulations to be run
# Author: Jonathan Yik Chang Ting
# Date: 14/12/2020

STAGE=$1
JOB_LIST_FILE=jobList; QUEUE_LIST_FILE=queueList
CONFIG_FILE=config.yml; RUN_LOCK=run.lock; EXAM_LOCK=examine.lock
SIM_DATA_DIR=/scratch/$PROJECT/$USER
for inFile in /scratch/hm62/hd8710/CSRAL/PdAu30Pt10SP6040CSRAL1/*S$STAGE.in; do
#for inFile in $SIM_DATA_DIR/*/*/*S$STAGE.in; do
    jobPath=${inFile::-3}; dirPath=$(echo ${jobPath%/*}); unqName=$(echo $jobPath | awk -F'/' '{print $NF}')
    if [ $STAGE = 1 ]; then
        eqState=$(grep S0eq: $dirPath/$CONFIG_FILE)
        if ! grep -q "true" <<< "$eqState"; then echo "$jobPath unequilibrated, skipping..."; continue; fi  # Skip if unequilibrated
    elif [ $STAGE = 2 ]; then
        heatState=$(grep S1ok: $dirPath/$CONFIG_FILE)
        if ! grep -q "true" <<< "$heatState"; then echo "$jobPath unmelted, skipping..."; continue; fi  # Skip if unmelted
    fi
    if grep -Fq $jobPath $SIM_DATA_DIR/$JOB_LIST_FILE; then echo "$jobPath on list, skipping..."; continue  # On the to-be-submitted-list
    elif grep -Fq $jobPath $SIM_DATA_DIR/$QUEUE_LIST_FILE; then echo "$jobPath queuing, skipping..."; continue  # Has been submitted
    elif test -f $dirPath/$RUN_LOCK; then echo "$dirPath running a job, skipping..."; continue  # Running
    elif test -f $jobPath.log; then  # Log file exists but not running
        if [[ $(tail -n 350 $jobPath.log) =~ "DONE!" ]]; then
            if [ $STAGE = 2 ]; then
                if [[ ! $(tail -n 5 $jobPath.log) =~ "ALL DONE!" ]]; then
                    echo "$jobPath unfinished, regenerating job script..."
                else
                    runState=$(grep S2ok: $dirPath/$CONFIG_FILE)
                    if ! grep -q "true" <<< "$runState"; then echo "S2ok: true" >> $dirPath/$CONFIG_FILE; fi
                    echo "$jobPath done, skipping..."; continue
                fi
            elif [ $STAGE = 1 ]; then
                if [[ ! $(tail -n 40 $jobPath.log) =~ "DONE!" ]]; then 
		    echo "$jobPath unfinished, regenerating job script..."
                else
                    heatState=$(grep S1ok: $dirPath/$CONFIG_FILE)
                    if ! grep -q "true" <<< "$heatState"; then echo "S1ok: true" >> $dirPath/$CONFIG_FILE; fi
                    echo "$jobPath done, skipping..."; continue
                fi
            elif [ $STAGE = 0 ]; then
                if [[ ! $(tail -n 5 $jobPath.log) =~ "DONE!" ]]; then 
		    echo "$jobPath unfinished, regenerating job script..."
	        else
                    eqState=$(grep S0eq: $dirPath/$CONFIG_FILE)
                    if ! grep -q "true" <<< "$eqState"; then echo "S0eq: true" >> $dirPath/$CONFIG_FILE; fi
                    echo "$jobPath done, skipping..."; continue
                fi
            fi
        else echo "$jobPath unfinished, submitting..."; fi
    else echo "$jobPath ready, submitting..."; fi
    touch $EXAM_LOCK; echo $jobPath >> $SIM_DATA_DIR/$JOB_LIST_FILE; rm -f $EXAM_LOCK
done
echo "$JOB_LIST_FILE generated!"
