# TNPgeneration
This repository contains code written for generation of AuPtPd trimetallic nanoparticles (TNPs) structural data set for machine learning applications.

Conducted by: Kaihan Lu assisted by Haotai Peng (Bill)
Supervised by: Jonathan Yik Chang Ting and Amanda Barnard
Institution: School of Computing Australian National University
Research course: SCNC2021 Science Research Project
Date Accomplished: 1/1/23


## Contents of each directory
- InitStruct: LAMMPS, Python, and Bash scripts written for generation of TNP initial structures (.lmp format)
- EAM: Modified LAMMPS tools for the generation of relevant interatomic potential files required for LAMMPS scripts execution
- MDsim: LAMMPS, Python, and Bash scripts written for tasks related to molecular dynamics (MD) simulations of the generated TNPs
- FeatExtEng: Python and Bash scripts written for tasks related to feature extraction of TNPs, along with the source code, executable file, and input files of Network Characterisation Package (NCPac), a software developed by Dr George Opletal from CSIRO and extended by Jonathan Ting for structural/geometrical feature extraction of TNPs


## Instructions to use the repository to generate more TNPs structural data
- The current script is designed to:
    - only generate TNPs with different combinations of the listed degrees of freedom, but extension is possible by appropriate modification of the code.
    - be run on high performance computing cluster such as Gadi of National Computational Infrastructure or cluster1 of ANU College of Engineering and Computer Science.

## Degrees of freedom of TNPs generated
- Elemental composition: Au, Pt, Pd
- Size: 30 Angstroms
- Shape: Spherical
- Ratio: i:j:k where i, j, k are from {2, 4, 6, 8}, with an additional constraint if i+j+k == 10
- Atomic ordering: (chosen with reference to Figure 2 in the review by Crawley et al, Heterogenous Trimetallic Nanoparticles as Catalysts, Chem. Rev. 2022, 122, 6, 6795--6849)
    - L10R: ordered alloy with randomly distributed M3 (o-M1M2-M3)
    - CS: inner-core@core@shell (M1@M2@M3)
    - CL10S: ordered-core@shell (o-M1M2@M3)
    - CRALS: random-core@shell (M1M2@M3)
    - RRAL: random solid solution (M1M2M3)
    - CSRAL: core@random-shell (M1@M2M3)
    - CSL10: core@ordered-shell (M1@o-M2M3)
    - CRSR: core@shell with randomly distributed M3 (M1M2@M2M3)
    - LL10: ordered intermetallic solution (o-M1M2M3)

### Generation of TNP initial structures
1. Modify the variables in the files below under ./InitStruct/ to generate other combinations:
    - constants.py
        - {diameterList}: NP diameters (Angstrom)
        - {ratioList}: Percentage of each element (only ratio combinations that add up to 100% will be generated)
        - {RANDOM_DISTRIB_NO}: Number of replicas for atomic orderings involving random distribution
        - {VACUUM_THICKNESS}: Size of the box containing the NP (need to be >= greatest diameter in {diameterList})
    - genBNPCS.sh
        - {SIZE_ARR}: NP diameters (Angstrom)
    - genTNPCS*.sh
        - Last three arguments representing NP diameters (Angstrom) of each component when calling the functions in these scripts
        - {RATIO_LIST}: Percentage of each element (only ratio combinations that add up to 100% will be generated)
        - {RANDOM_DISTRIB_NO}: Number of replicas for atomic orderings involving random distribution
        - *Note: Some NPs that are supposed to be TNPs turned out to be BNP due to overly large overlap cutoff in genTNPCS*.sh.
2. Run genMBTNPs.sh to generate the TNPs to be simulated.

### Simulation of TNPs
#### Stages of simulations
- S0: Short equilibration of TNPs
- S1: Heating up of TNPs, saving configurations along the way
- S2: Short equilibration of the saved TNP configurations at the saved temperature

#### Instructions:
1. Go to ./MDsim/
2. Modify the path in setupMDsim.sh as appropriate and run it. This places each .lmp file into a unique directory in the specified path to store the simulation data, while initialising a config.yml file that stores the simulation progress/status for each directory.
3. Check that parameters that are not variables in annealS{0/1/2}.in LAMMPS script templates are appropriate according to your simulation goals.
4. Modify the paths and parameters in genAnnealIn.sh as appropriate and run it, taking simulation stage number as argument {0, 1, 2}.
5. Generate 3 files at the path specified in setupMDsim.sh {'jobList', 'queueList', 'runList'}
5. Modify the path in jobList.sh as appropriate and run it, taking simulation stage number as argument {0, 1, 2}. This script:
    - places jobs (LAMMPS running of *S{0/1/2}.in) that are ready to be run by the HPC into 'jobList'.
    - needs to be rerun after the jobs are finished (until all jobs are done), to:
        - update the progress of the simulations by updating config.yml in the TNP directory (whether each stage is done), and 
        - update the status of the jobs (whether it's submitted, queuing, or running) by updating 'jobList', 'queueList', and 'runList'
        - place the job for next stage of simulation into 'jobList'.
6. Modify the parameters in runAnneal.sh and subAnneal.sh, and run subAnneal.sh. This script:
    - submits {maxQueueNum} of job scripts listed in 'jobList' to the HPC. 
    - Once a job finishes, it will automatically submit the next job from 'jobList', keeping the number of jobs submitted the same (i.e. {maxQueueNum}) until there are no more jobs in 'jobList'.
- * delJobs.sh and rmOutFiles.sh are provided to ease the debugging/cleaning process.
- * Remember to backup your simulation data to elsewhere when they are done.

### Feature extraction of TNPs
1. Go to ./FeatExtEng/
2. Modify the paths and parameters in genCSVs.py as appropriate.
3. Submit runGenDAPdata.sh to the HPC. This will generate:
    - {MDout.csv}, which contains the output of MD simulations of all TNPs.
    - {features.csv}, which contains the features extracted by NCPac for all TNPs.
4. Modify the parameters in mergeFeatures.py and run it. This will merge the information from the 2 csv files and generate a new {AuPtPd_nanoparticle_dataset.csv} following the format of dataset stored on CSIRO's Data Access Portal, such as https://data.csiro.au/collection/csiro:40669 (gold nanoparticle).
