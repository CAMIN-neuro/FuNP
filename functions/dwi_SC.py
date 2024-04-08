#!/usr/bin/env python3.7
# -*- coding: utf-8 -*-

"""
    roi         :  (str) Parcellation file (nii.gz) for constructing connectome (or edgeLengths)
    data        :  (str) connectome (or edgeLengths) file generated using tck2connectome
    outDir      :  (str) Output directory that final connectome (or edgeLengths) will be saved
"""

import sys
import numpy as np
import nibabel as nib

roi = sys.argv[1]
data = sys.argv[2]
outDir = sys.argv[3]

# Load data
parc = nib.load(roi)
mat = np.loadtxt(data)

# Get parcellation index
parc_img = parc.get_fdata()
parc_uniq = np.unique(parc_img)
parc_uniq = parc_uniq.astype(int)
if parc_uniq[0] == 0:
    parc_uniq = np.delete(parc_uniq, 0, axis=0)

NumROI = np.size(parc_uniq)
idx_lh = parc_uniq[0:int(NumROI/2)]
idx_rh = parc_uniq[int(NumROI/2):]
idx_bh = np.append(idx_lh, idx_rh) -1

# Adjust connectome (or edgeLengths) data
mat_roi = mat[idx_bh,:][:,idx_bh]
mat_adj = mat_roi + np.transpose(np.triu(mat_roi, k=1))

tmp = data.split('/')
outName = tmp[-1]
np.savetxt(outDir+'/'+outName, mat_adj)
