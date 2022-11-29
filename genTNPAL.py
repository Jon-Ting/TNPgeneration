# Goal: Generate initial alloy TNP structures for MD simulations
# Author: Jonathan Yik Chang Ting
# Date: 22/10/2020
'''
Note:
- Abbreviations:
    - RAL = randomly distributed alloy
    - RCS = randomly distributed core-shell-like alloy
    - (R)L10 = L1_0 intermetallic alloy (with/without random component)
    - (R)L12 = L1_2 intermetallic alloy (with/without random component)
- To do:
    - FCC is currently being hard-coded for lattice constant retrieval, might need to be flexible
    - Perhaps could add a parameter to control core thickness
'''

import numpy as np
from os.path import isfile, isdir
from os import mkdir
from numpy.random import seed, rand, RandomState
from ase.io.lammpsdata import read_lammps_data, write_lammps_data
from ase.visualize import view
from constants import LMP_DATA_DIR, BNP_DIR, TNP_DIR, RANDOM_DISTRIB_NO, VACUUM_THICKNESS, eleDict, diameterList, shapeList, distribList, ratioList


def dist1D(coord1, coord2, dim):
    """Compute distance between 2 points in one of their real space coordinates"""
    return round(np.sqrt(np.sum((coord2[dim]-coord1[dim]) ** 2)), 3)


def dist3D(coord1, coord2):
    """Compute real space distance between 2 points"""
    return round(np.sqrt(np.sum((coord2 - coord1) ** 2)), 3)


def randConv(obj, element3, ele2Ratio, ele3Ratio, rseed, prob):
    """Randomly convert elements of atoms until specified ratio is reached"""
    elements = np.array(list(obj.symbols.species()))
    print(elements)
    element1 = elements[elements != element3][0]
    element2 = elements[elements != element3][1]
    ele1Arr, ele2Arr, ele3Arr = obj.symbols.search(element1), obj.symbols.search(element2), obj.symbols.search(element3)
    ele3IdealNum = round(ele3Ratio / 100 * len(obj))
    diff = len(ele3Arr) - ele3IdealNum
    randGen = RandomState(rseed)
    probArr = None  # np.array(prob)[convEleArr] / np.array(prob)[convEleArr].sum() if len(prob) > 0 else None

    if diff < 0:
        if ele2Ratio == '': ele2Ratio = 50
        idxArr = randGen.choice(a=ele1Arr, size=round(abs(diff) * (100 - ele2Ratio - ele3Ratio) / 100), replace=False, p=probArr)
        for idx in idxArr: obj[idx].symbol = element3
        idxArr = randGen.choice(a=ele2Arr, size=round(abs(diff) * ele2Ratio / 100), replace=False, p=probArr)
        for idx in idxArr: obj[idx].symbol = element3
    else:
        if ele2Ratio == '': ele2Ratio = 50
        idxArr = randGen.choice(a=ele3Arr, size=round(abs(diff) * (100 - ele2Ratio - ele3Ratio) / 100), replace=False, p=probArr)
        for idx in idxArr: obj[idx].symbol = element1
        idxArr = randGen.choice(a=ele3Arr, size=round(abs(diff) * ele2Ratio / 100), replace=False, p=probArr)
        for idx in idxArr: obj[idx].symbol = element2
    return obj


def genTNP(obj, element3, shape, ele2Ratio, ele3Ratio, distrib, rseed):
    probList = []
    if distrib == 'RAL':
        seed(rseed)
        randList = rand(len(obj))  # Uniform distribution
        for (i, atom) in enumerate(obj):
            if randList[i] > (100 - ele3Ratio) / 100: atom.symbol = element3

    elif distrib == 'RCS':
        if shape == 'IC':
            massCenter = obj.get_center_of_mass()
            radius = (obj.cell[0][0]-VACUUM_THICKNESS)/2
        else:
            xSlices = set([round(atom[0], 3) for atom in obj.positions])
            ySlices = set([round(atom[1], 3) for atom in obj.positions])
            zSlices = set([round(atom[2], 3) for atom in obj.positions])
            
            # Find the center of each line in the box
            zThreadDict = {(x, y): {'max': 0, 'min': 0, 'mid': []} for x in xSlices for y in ySlices}
            xThreadDict = {(y, z): {'max': 0, 'min': 0, 'mid': []} for y in ySlices for z in zSlices}
            yThreadDict = {(z, x): {'max': 0, 'min': 0, 'mid': []} for z in zSlices for x in xSlices}
            for (atomIdx, atom) in enumerate(obj):
                xCoord, yCoord, zCoord = round(atom.position[0], 3), round(atom.position[1], 3), round(atom.position[2], 3)
                zThreadDict[(xCoord, yCoord)]['mid'].append(zCoord)
                xThreadDict[(yCoord, zCoord)]['mid'].append(xCoord)
                yThreadDict[(zCoord, xCoord)]['mid'].append(yCoord)
            threadDicts = [zThreadDict, xThreadDict, yThreadDict]
            for threadDict in threadDicts:
                emptyDictKeys = []
                for (dim1, dim2) in threadDict.keys():
                    if len(threadDict[(dim1, dim2)]['mid']) == 0: emptyDictKeys.append((dim1, dim2)); continue
                    threadDict[(dim1, dim2)]['max'] = max(threadDict[(dim1, dim2)]['mid'])
                    threadDict[(dim1, dim2)]['min'] = min(threadDict[(dim1, dim2)]['mid'])
                    threadDict[(dim1, dim2)]['mid'] = (threadDict[(dim1, dim2)]['max']+threadDict[(dim1, dim2)]['min']) / 2
                for key in emptyDictKeys: del threadDict[key]
     
        # Alchemical change
        seed(rseed)
        randList = rand(len(obj))
        for (atomIdx, atom) in enumerate(obj):
            if shape == 'IC':
                prob = dist3D(massCenter, atom.position) / radius
            else:
                xCoord, yCoord, zCoord = round(atom.position[0], 3), round(atom.position[1], 3), round(atom.position[2], 3)
                zHalfLen = (zThreadDict[(xCoord, yCoord)]['max']-zThreadDict[(xCoord, yCoord)]['min']) / 2
                xHalfLen = (xThreadDict[(yCoord, zCoord)]['max']-xThreadDict[(yCoord, zCoord)]['min']) / 2
                yHalfLen = (yThreadDict[(zCoord, xCoord)]['max']-yThreadDict[(zCoord, xCoord)]['min']) / 2
                zRelPos = abs(zCoord-zThreadDict[(xCoord, yCoord)]['mid']) / zHalfLen if round(zHalfLen, 3) != 0.0 else abs(zCoord-zThreadDict[(xCoord, yCoord)]['mid'])
                xRelPos = abs(xCoord-xThreadDict[(yCoord, zCoord)]['mid']) / xHalfLen if round(xHalfLen, 3) != 0.0 else abs(xCoord-xThreadDict[(yCoord, zCoord)]['mid'])
                yRelPos = abs(yCoord-yThreadDict[(zCoord, xCoord)]['mid']) / yHalfLen if round(yHalfLen, 3) != 0.0 else abs(yCoord-yThreadDict[(zCoord, xCoord)]['mid'])
                if shape == 'DH':
                    prob = 1 if (round(zRelPos, 3) == 1.0) | (round(zHalfLen, 3) == 0.0) else zRelPos
                else:
                    if (round(zRelPos, 3) == 1.0) | (round(xRelPos, 3) == 1.0) | (round(yRelPos, 3) == 1.0) | (round(zHalfLen, 3) == 0.0) | (round(xHalfLen, 3) == 0.0) | (round(yHalfLen, 3) == 0.0): prob = 1
                    else: prob = (zRelPos+xRelPos+yRelPos) / 3
            if randList[atomIdx] < prob: obj[atomIdx].symbol = element3
            probList.append(prob)

    elif distrib in ['L10', 'L12', 'RL10', 'RL12']:
        lc = eleDict[obj[0].symbol]['lc']['FCC']
        vacOffset = VACUUM_THICKNESS / 2
        for (i, atom) in enumerate(obj):
            yModulo = round((round(obj.positions[i][1], 3) - vacOffset) % lc, 3)
            # yModulo = round((round(obj.positions[i][1], 3) - vacOffset) % (lc + lc / 2), 3)
            if (yModulo == 0.0) | (yModulo == lc): atom.symbol = element3
            if distrib == 'L12':
                xModulo = round((round(obj.positions[i][0], 3) - vacOffset) % lc, 3)
                if (xModulo == 0.0) | (xModulo == lc): atom.symbol = element3

    else:
        raise Exception('Specified distribution type unrecognised!')

    if 'R' in distrib:
        obj = randConv(obj, element3, ele2Ratio, ele3Ratio, rseed, probList)
    return obj


def writeTNP(element1, element2, diameter, shape, ele2Ratio, rep1, ele3Ratio, distrib1, distrib2, replace=False, vis=False):
    if not isdir(LMP_DATA_DIR): mkdir(LMP_DATA_DIR)
    if not isdir('{0}{1}'.format(LMP_DATA_DIR, 'TNP')): mkdir('{0}{1}'.format(LMP_DATA_DIR, 'TNP'))

    for element3 in eleDict:
        if element3 is element1 or element3 is element2: continue
        # Get input file name
        if 'L10' in distrib1:
            ele2Ratio, rep1 = '', ''
            directory = BNP_DIR[0]
            fileNameBNP = '{0}{1}{2}{3}{4}.lmp'.format(element1, element2, diameter, shape, distrib1)
        else:
            directory = BNP_DIR[1]
            fileNameBNP = '{0}{1}{2}{3}{4}{5}{6}.lmp'.format(element1, element2, diameter, shape, ele2Ratio, distrib1, rep1)
        # Read data from previous generated file
        bnp = read_lammps_data('{0}{1}{2}'.format(LMP_DATA_DIR, directory, fileNameBNP), style='atomic', units='metal')
        bnp.set_chemical_symbols(symbols=[element1 if bnp.arrays['type'][i] == 1 else element2 for i in range(bnp.arrays['type'].size)])

        for rep2 in range(RANDOM_DISTRIB_NO):
            # Generate the new file name
            if rep1 == rep2: continue
            if distrib1 == 'L10' and distrib2 == 'RAL': directory = TNP_DIR[0]
            elif distrib1 == 'RAL' and distrib2 == 'RAL': directory = TNP_DIR[1]
            # ele3Ratio, rep2 = '', ''  # TODO
            fileNameTNP = '{0}{1}{2}{3}{4}{5}{6}{7}{8}{9}{10}.lmp'.format(
                element1, element2, element3, diameter, shape, 
                ele2Ratio, distrib1, rep1,
                ele3Ratio, distrib2, rep2
            )
            if not replace:
                if isfile(LMP_DATA_DIR + directory + fileNameTNP):
                    print('      {0} already exist, skipping...'.format(fileNameTNP))
                    continue

            try:
                tnp = genTNP(bnp, element3, shape, ele2Ratio, ele3Ratio, distrib2, rep2)
                if not isdir('{0}{1}'.format(LMP_DATA_DIR, directory[:-1])): mkdir('{0}{1}'.format(LMP_DATA_DIR, directory[:-1]))
                write_lammps_data('{0}{1}{2}'.format(LMP_DATA_DIR, directory, fileNameTNP), atoms=tnp, units='metal', atom_style='atomic')
                print('      Generated {0}, formula: {1}'.format(fileNameTNP, tnp.get_chemical_formula()))
                if vis: view(tnp)
            except ValueError as err:
                print(err)
            if 'R' not in distrib2: break


def main(replace=False, vis=False):
    print('Generating TNP alloys of:')
    for diameter in diameterList:
        print('\n  Size {0} Angstrom for:'.format(diameter))
        for element1 in eleDict:
            for element2 in eleDict:
                if element1 is element2: continue
                print('    Element 1: {0}, Element 2: {1}'.format(element1, element2))
                for shape in shapeList:
                    for ratio1 in ratioList:
                        for ratio2 in ratioList:
                            if ratio1 + ratio2 >= 100: continue
                            print('    Ratio 1: {0}, Ratio 2: {1}'.format(ratio1, ratio2))
                            for rep1 in range(RANDOM_DISTRIB_NO):
                                for distrib1 in distribList:
                                    for distrib2 in distribList:
                                        if distrib1 == 'L10' and distrib2 == 'L10': continue
                                        elif distrib1 == 'RAL' and distrib2 == 'L10': continue
                                        print('    Distrib 1: {0}, Distrib 2: {1}'.format(distrib1, distrib2))
                                        writeTNP(
                                            element1=element1,
                                            element2=element2,
                                            diameter=diameter,
                                            shape=shape,
                                            ele2Ratio=ratio1,
                                            rep1=rep1,
                                            ele3Ratio=ratio2,
                                            distrib1=distrib1,
                                            distrib2=distrib2,
                                            replace=replace,
                                            vis=vis
                                        )


if __name__ == '__main__':
    main(replace=False, vis=False)
    print('ALL DONE!')
