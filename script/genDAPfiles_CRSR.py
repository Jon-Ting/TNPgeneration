# ASSUMES:
# - targetDir exists, contains 'ConfID, Temp, Pres, KinE, PotE, TotE\n' as header
# - MDout.csv exists in targetDir (contains header)

import os
from os.path import isdir, exists
import pandas as pd
import multiprocessing
from multiprocessing import Pool
import shutil
from zipfile import ZipFile
import tarfile


# Important variables to check!
npCnt = 600  # Different starting point for different type of ordering, e.g. CS != RRAL
PROJECT, USER_NAME = 'hm62', 'hd8710'
sourceDirs = ['CS', 'LL10', 'CL10S', 'CSL10', 'CRALS', 'CSRAL', 'L10R', 'RRAL', 'CRSR']
sourceDirs = ['CS', 'LL10', 'CL10S', 'CSL10']  # npCnt = 0, total = 24
sourceDirs = ['CRALS', 'CSRAL']  # npCnt = 24, total = 144
sourceDirs = ['L10R']  # npCnt = 168, total = 108 
sourceDirs = ['RRAL']  # npCnt = 276, total = 324
sourceDirs = ['CRSR']  # npCnt = 600, total = 864 
sourcePaths = [f"/scratch/{PROJECT}/{USER_NAME}/{dir}" for dir in sourceDirs]

# Variables that are more constant
targetDir = f"/scratch/{PROJECT}/{USER_NAME}/AuPtPd"
if not isdir(targetDir): os.mkdir(targetDir)

numFramePerNP = 11
doneFile = 'DONE.txt'
outMDfile = 'MDout.csv'
NCPacExeName, NCPacInpName = 'NCPac.exe', 'NCPac.inp'
workingDir = f"/home/659/{USER_NAME}/TNPgeneration/script"
path2NCPacExe = f"/home/659/{USER_NAME}/TNPgeneration/NCPac/{NCPacExeName}"
path2NCPacInp = f"/home/659/{USER_NAME}/TNPgeneration/NCPac/{NCPacInpName}"
headerLine = f"CSIRO Nanostructure Databank - AuPtPd Nanoparticle Data Set\n"

# Make the final path to receice the results
finalPath = f"{targetDir}/final"
if not isdir(finalPath): os.mkdir(finalPath)
if not isdir(f'{finalPath}/data'): os.mkdir(f'{finalPath}/data')
if not isdir(f'{finalPath}/feature'): os.mkdir(f'{finalPath}/feature')

print("Copying xyz files to individual directories and relabelling numerically...")
for sourcePath in sourcePaths:
    for NPdir in os.listdir(sourcePath):
        print(f"  Nanoparticle: {NPdir}")
        NPdirPath = f"{sourcePath}/{NPdir}"

        # If not done for the nanoparticle yet, reextract Stage 2 files
        if not exists(f"{NPdirPath}/{doneFile}"):
            if not exists(f"{NPdirPath}/{NPdir}S2.zip"):
                shutil.make_archive(f"{NPdirPath}/{NPdir}S2", 'zip', '.', f"{NPdirPath}/{NPdir}S2")
                print("    Zipped Stage 2 files...")
            with ZipFile(f"{NPdirPath}/{NPdir}S2.zip", 'r') as f: f.extractall(f"{NPdirPath}/")
            print("    Extracted Stage 2 files...")
        else:
            npCnt += 1
            continue
        
        confCnt = 0 + npCnt*numFramePerNP
        for NPconf in os.listdir(f"{NPdirPath}/{NPdir}S2"): 
            if 'min' not in NPconf: continue  # Skip the unminimised configurations
            oriFilePath = f"{NPdirPath}/{NPdir}S2/{NPconf}"
            confID = str(confCnt).zfill(7)
            print(f"  Conformation ID: {confID}")
            confDir = f"{targetDir}/{confID}"
            if not isdir(f"{targetDir}/{confID}"): os.mkdir(confDir)
            
            print("    Copying files...")
            with open(oriFilePath, 'r') as f1:
                with open(f"{confDir}/{confID}.xyz", 'w') as f2:
                    f2.write(f1.readline())
                    f1.readline()  # Replace second line with CSIRO header
                    f2.write(headerLine)
                    f2.write(''.join([line for line in f1.readlines()]))
            shutil.copy(oriFilePath, f"{confDir}/{confID}.xyz")
            shutil.copy(path2NCPacExe, f"{confDir}/{NCPacExeName}")
            shutil.copy(path2NCPacInp, f"{confDir}/{NCPacInpName}")
            with open(f"{confDir}/{NCPacInpName}", 'r+') as f:
                f.writelines([f'{confID}.xyz       - name of xyz input file                                              [in_filexyz]'])
            os.system(f"head {confDir}/{NCPacInpName}")
            os.chdir(confDir)
            os.system(f"./{NCPacExeName}")
            os.chdir(workingDir)

            # Move .xyz, FEATURES.csv to {finalDir} and remove {confDir}
            shutil.copy(f"{confDir}/{confID}.xyz", f'{finalPath}/data')
            shutil.copy(f"{confDir}/od_FEATURESET.csv", f'{finalPath}/feature/{confID}.csv')
            shutil.rmtree(confDir)
            confCnt += 1
        
        # Extract outputs from MD for each configuration
        with open(f"{NPdirPath}/{NPdir}S2.log", 'r') as f1:
            with open(f"{targetDir}/{outMDfile}", 'a') as f2:
                foundMinLine, prevLine, confCnt = False, None, confCnt - numFramePerNP
                for (i, line) in enumerate(f1):
                    if '- MINIMISATION -' in line and not foundMinLine: foundMinLine = True
                    elif 'Loop time of' in line and foundMinLine: 
                        confID = str(confCnt).zfill(7)
                        temp, pres, kinE, potE, totE = prevLine.split()[2:]
                        f2.write(f"{confID},{temp},{pres},{kinE},{potE},{totE}\n")
                        confCnt += 1
                        foundMinLine = False
                    prevLine = line
        assert (confCnt) % numFramePerNP == 0  # Check that confCnt is expected
    
        # Clean up directory, mark as done
        shutil.rmtree(f"{NPdirPath}/{NPdir}S2/")
        open(f"{NPdirPath}/{doneFile}", 'w').close()
        print("    Done!")
        npCnt += 1

print("All DONE!")
