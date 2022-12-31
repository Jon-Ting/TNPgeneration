# TNPgeneration
## Steps to generate and simulate 3D structures of sphered trimetallic nanoparticles (TNPs): 
1. Modify properties of nanoparticles (NPs)
    1. in constants.py
        1. {diameterList}: NP diameters of interest (Angstrom)
        2. {ratioList}: Ratios of interest
        3. {RANDOM_DISTRIB_NO}: Random seeds of randomly substitution by specific ratios
        4. {VACUUM_THICKNESS}: The size of the box that contains an NP (must be larger or equal than diameters in {diameterList})
    2. in genBNPCS.sh
        1. {SIZE_ARR}: NP diameters of interest (Angstrom)
    3. in genTNPCS*.sh
        1. SIZE_ARR: Last three arguments representing NP diameters of interest (Angstrom) when calling the functions in this script
        2. {RATIO_LIST}: Ratios of interest
        3. {RANDOM_DISTRIB_NO}: Random seeds of randomly substitution by specific ratios
2. Run genMBTNPs.sh to generate the TNPs to be simulated.
3. Run setupMDsim.sh. This places each .lmp file into a unique directory in /scratch/, while initialising a config.yml file for each directory.
4. Check that parameter choices in annealS{0/1/2}.in template LAMMPS scripts are alright.
5. Modify the parameters in genAnnealIn.sh as appropriate and run them, taking stage number as argument {0, 1, 2}.
6. Run jobList.sh, taking stage number as argument {0, 1, 2}. This bash script automatically places jobs that are ready into a jobList file and keeps track of their state -- whether it's not submitted, queuing, or running (requires jobList, queueList, runList to be generated under /scratch/$PROJECT/$USER/ directory). Also checks when the simulations are done and automatically place the next stage into the jobList file.
7. Modify maxQueueNum in subAnneal.sh and run it. This bash script automatically submits {maxQueueNum} of job scripts listed in the jobList file to Gadi. Once a job finishes, it will automatically submit the next job from jobList to Gadi, keeping the number of jobs submitted the same (i.e. {maxQueueNum}) until there are no more jobs in jobList.

## Steps to get the features of TNPs after simulating
1. Modify variables above the functions in genDAPfilesParallel.py to suit for your use.
2. Submit runGenDAPfilesParallel.sh to HPC and wait for the results.
3. Modify variables in mergeFeatures.py and run it to get completed AuPtPd_nanoparticle_dataset.csv.

Caveat:
- The scripts are only capable of generating TNPs consisting of the element set {Au, Pt, Pd}, extension shouldn't be too difficult.
- Some nanoparticles that are supposed to be TNPs turned out to be BNP due to overly large overlap cutoff in genTNPCS*.sh.
