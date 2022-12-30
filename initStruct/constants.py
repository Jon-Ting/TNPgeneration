# Purpose: Store variables for generation of NPs using ASE
# Author: Jonathan Yik Chang Ting
# Date: 19/20/2020

from math import sqrt

LMP_DATA_DIR = './'
MNP_DIR = 'MNP/'
BNP_DIR = ['BNP/L10/', 'BNP/RAL/']
TNP_DIR = ['TNP/L10R/', 'TNP/RRAL/', 'TNP/LL10/']
GOLDEN_RATIO = (1+sqrt(5)) / 2
VACUUM_THICKNESS = 40.0
RANDOM_DISTRIB_NO = 3

# Elements of interest & their lattice parameters
# - Pd, Pt, Au values were obtained from N. W. Ashcroft and N. D. Mermin, Solid State Physics (Holt, Rinehart, and Winston, New York, 1976.
# - The lattice constants are 3.859, 3.912, and 4.065 Angstroms, for the respective FCC metals at 300 K according to W. P. Davey, "Precision Measurements of the Lattice Constants of Twelve Common Metals," Physical Review, vol. 25, (6), pp. 753-761, 1925.
eleDict = {'Pd':
            {'lc': {'FCC': 3.89}}, 
           'Pt': 
            {'lc': {'FCC': 3.92}}, 
           'Au': 
            {'lc': {'FCC': 4.09}}}
diameterList = [10, 15, 20, 25, 30]  # NP diameters of interest (Angstrom)
shapeList = ['SP']  # Shapes of interest 
distribList = ['L10', 'RAL']  # Distributions of interest
ratioList = [20, 40, 60, 80]  # Ratios of interest
