#!/usr/bin/env python3.7
# -*- coding: utf-8 -*-

"""
    dataDir     :  (str) Directory that contains ?.MyelinMap.32k_fs_LR.func.gii (typicall, ~/struc/wb_adjust/MNINonLinear/fsaverage_LR32k)
    parc        :  (str) Parcellation file with full directory
    outDir      :  (str) Output directory that parcellated myelin will be saved
"""

import sys
import numpy as np
import nibabel as nib
import scipy.special
import scipy.stats
import warnings
warnings.filterwarnings('ignore')

dataDir = sys.argv[1]
parc = sys.argv[2]
outDir = sys.argv[3]

# Load data
mye_L = nib.load(dataDir + '/L.MyelinMap.32k_fs_LR.func.gii').darrays
mye_R = nib.load(dataDir + '/R.MyelinMap.32k_fs_LR.func.gii').darrays
mye = np.concatenate((mye_L[0].data, mye_R[0].data), axis=0)

# Parcellate myelin data
thisparc = np.loadtxt(parc)
uparcel = np.unique(thisparc)
if uparcel[0] == 0:
    uparcel = np.delete(uparcel, 0, 0)

mye_parc = np.zeros(len(uparcel))
for up in range(len(uparcel)):
    tmpData = mye[thisparc == uparcel[up]]
    mye_parc[up] = np.nanmean(tmpData)

# Save data
tmp1 = parc.split('/')
tmp2 = tmp1[-1].split('_')
outName = tmp2[0]
np.savetxt(outDir+'/mp_'+outName+'.txt', mye_parc)
