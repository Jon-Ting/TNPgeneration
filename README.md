# TNPgeneration
Steps to generate and simulate 3D structures of sphered trimetallic nanoparticles (TNPs): 
1. Modify properties of nanoparticles (NPs)
    1. in initStruct/constants.py
        1. {diameterList}: NP diameters of interest (Angstrom)
        2. {ratioList}: Ratios of interest
        3. {RANDOM_DISTRIB_NO}: Random seeds of randomly substitution by specific ratios
        4. {VACUUM_THICKNESS}: The size of the box that contains an NP (must be larger or equal than diameters in {diameterList})
    2. in initStruct/genBNPCS.sh
        1. {SIZE_ARR}: NP diameters of interest (Angstrom)
    3. in initStruct/genTNPCS*.sh
        1. SIZE_ARR: Last three arguments representing NP diameters of interest (Angstrom) when calling the functions in this file
        2. {RATIO_LIST}: Ratios of interest
        3. {RANDOM_DISTRIB_NO}: Random seeds of randomly substitution by specific ratios
4. Run genMBTNPs.sh to generate the TNPs to be simulated.
5. Run setupMDsim.sh. This places each .lmp file into a unique directory in /scratch/, while initialising a config.yml file for each directory.
6. Check that parameter choices in annealS{0/1/2}.in template LAMMPS scripts are alright.
7. Modify the parameters in genAnnealIn.sh as appropriate and run them, taking stage number as argument {0, 1, 2}
8. Run jobList.sh, taking stage number as argument {0, 1, 2}. This bash script automatically places jobs that are ready into a jobList file and keeps track of their state -- whether it's not submitted, queuing, or running (requires jobList, queueList, runList to be generated under /scratch/$PROJECT/$USER/ directory). Also checks when the simulations are done and automatically place the next stage into the jobList file.
9. Modify maxQueueNum in subAnneal.sh and run it. This bash script automatically submits {maxQueueNum} of job scripts listed in the jobList file to Gadi. Once a job finishes, it will automatically submit the next job from jobList to Gadi, keeping the number of jobs submitted the same (i.e. {maxQueueNum}) until there are no more jobs in jobList.

Caveat:
- The scripts are only capable of generating TNPs consisting of the element set {Au, Pt, Pd}, extension shouldn't be too difficult.
- Some nanoparticles that are supposed to be TNPs turned out to be BNP due to overly large overlap cutoff in genTNPCS*.sh
