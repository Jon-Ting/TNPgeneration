import os


PROJECT, USER_NAME = 'p00', 'hd8710'
finalPath = f"/scratch/{PROJECT}/{USER_NAME}/AuPtPd/finalData"
sourcePath = f"{finalPath}/Features"
featureFiles = os.listdir(sourcePath)

# Merge all particle-wise features extracted using NCPac into features.csv
with open(f'{finalPath}/features.csv', 'a') as f1:
    for i in range(len(featureFiles)):
        with open(f'{sourcePath}/{featureFiles[i]}') as f2:
            if i == 0: f1.writelines(f2.readlines())  # Include headers for first csv file
            else: 
                outputNCPac = f2.readlines()
                if outputNCPac: 
                    print(outputNCPac[1])
                    f1.writelines(outputNCPac[2])
                else: f1.writelines([','] * 13196)

# Concatenate AuPtPd_nanoparticle_dataset.csv with features.csv (keep the name of combined document as the former)

# Modify AuPtPd_nanoparticle_dataset.csv to publication ready format

