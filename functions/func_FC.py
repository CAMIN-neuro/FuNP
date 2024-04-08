#!/usr/bin/env python3.7
# -*- coding: utf-8 -*-

"""
    funcDir     :  (str) fMRI processing directory (typicall, ~/func)
    parc        :  (str) Parcellation file with full directory
    sctx        :  (str) Subcortex file defined using run_first_all
    outDir      :  (str) Output directory that connectomes will be saved
"""

import sys
import numpy as np
import nibabel as nib
import warnings
warnings.filterwarnings('ignore')

funcDir = sys.argv[1]
parc = sys.argv[2]
sctx = sys.argv[3]
outDir = sys.argv[4]


# Load parcellation
thisparc = np.loadtxt(parc)


# Timeseries of ctx
func_L = nib.load(funcDir + '/surface/func.L.func.gii').darrays
NumVertex = np.shape(func_L[0].data)[0]
NumVol = np.shape(func_L)[0]
ts_L = np.zeros([NumVol, NumVertex])
for i in range(0, NumVol):
    t = func_L[i].data
    ts_L[i] = t

func_R = nib.load(funcDir + '/surface/func.R.func.gii').darrays
ts_R = np.zeros([NumVol, NumVertex])
for i in range(0, NumVol):
    t = func_L[i].data
    ts_R[i] = t

ts = np.concatenate((ts_L, ts_R), axis=1)


# Parcellate cortical timeseries
uparcel = np.unique(thisparc)
if uparcel[0] == 0:
    uparcel = np.delete(uparcel, 0, 0)

ts_ctx = np.zeros([NumVol, len(uparcel)])
for up in range(len(uparcel)):
    tmpData = ts[:, thisparc == uparcel[up]]
    ts_ctx[:, up] = np.nanmean(tmpData, axis=1)


# Timeseries of  sctx
func_nii = nib.load(funcDir + '/volume/func_clean_vol.nii.gz')
func_img = func_nii.get_fdata()

sctx_nii = nib.load(sctx)
sctx_img = sctx_nii.get_fdata()
sctx_label = [10, 11, 12, 13, 17, 18, 26, 49, 50, 51, 52, 53, 54, 58]
# 10 Left-Thalamus-Proper
# 11 Left-Caudate
# 12 Left-Putamen
# 13 Left-Pallidum
# 17 Left-Hippocampus
# 18 Left-Amygdala
# 26 Left-Accumbens-area
# 49 Right-Thalamus-Proper
# 50 Right-Caudate
# 51 Right-Putamen
# 52 Right-Pallidum
# 53 Right-Hippocampus
# 54 Right-Amygdala
# 58 Right-Accumbens-area

ts_sctx = np.zeros([NumVol, len(sctx_label)])
for i, sl in enumerate(sctx_label):
    sctx_idx = np.where(sctx_img == sl)
    ts_sctx[:,i] = np.mean(func_img[sctx_idx], axis=0)


# Total timeseries
ts = np.concatenate((ts_sctx, ts_ctx), axis=1)


# Calculate correlation matrix
cm_R = np.corrcoef(np.transpose(ts))
np.fill_diagonal(cm_R, val=1)

cm_Z = np.arctanh(cm_R)
np.fill_diagonal(cm_Z, val=1)

# Save data
tmp1 = parc.split('/')
tmp2 = tmp1[-1].split('_')
outName = tmp2[0]
np.savetxt(outDir+'/R_sub-cor-connectome_'+outName+'.txt', cm_R)
np.savetxt(outDir+'/Z_sub-cor-connectome_'+outName+'.txt', cm_Z)
