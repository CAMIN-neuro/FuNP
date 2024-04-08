#!/usr/bin/env python3.7
# -*- coding: utf-8 -*-

"""
    dataDir     :  (str) Directory that contains cortical layer-wise microstructural data
    num_surfs   :  (int) Number of cortical surfaces
    parc        :  (str) Parcellation file with full directory
    outDir      :  (str) Output directory that MPC matrix will be saved
"""

import sys
import numpy as np
import nibabel as nib
from build_mpc import build_mpc
import warnings
warnings.filterwarnings('ignore')


dataDir = sys.argv[1]
num_surfs = sys.argv[2]
parc = sys.argv[3]
outDir = sys.argv[4]

# Load data
MP_L = np.zeros([int(num_surfs), 32492])
MP_R = np.zeros([int(num_surfs), 32492])
for ns in range(1, int(num_surfs)+1):
    gii = nib.load(dataDir + '/L.' + str(ns) + 'by' + num_surfs + 'surf_micro.32k_fs_LR.shape.gii').darrays
    MP_L[ns-1,:] = gii[0].data
    gii = nib.load(dataDir + '/R.' + str(ns) + 'by' + num_surfs + 'surf_micro.32k_fs_LR.shape.gii').darrays
    MP_R[ns - 1, :] = gii[0].data
MP = np.concatenate((MP_L, MP_R), axis=1)

# Build MPC
thisparc = np.loadtxt(parc)
exclude_labels = np.asarray([])
(mat, I, problemNodes) = build_mpc(MP, thisparc, exclude_labels)
MPC = mat + np.transpose(np.triu(mat, k=1))

# Save data
tmp1 = parc.split('/')
tmp2 = tmp1[-1].split('_')
outName = tmp2[0]
np.savetxt(outDir+'/mpc_'+outName+'.txt', MPC)
