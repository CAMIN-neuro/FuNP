#!/usr/bin/env python3.7
# -*- coding: utf-8 -*-

"""
    lh_surf     :  (str) Midthickness surface with full directory (lh)
    rh_surf     :  (str) Midthickness surface with full directory (rh)
    lh_parc     :  (str) Parcellation file with full directory (lh)
    rh_parc     :  (str) Parcellation file with full directory (rh)
    parc_str    :  (str) Parcellation name
    outDir      :  (str) Output directory that geodesic distance matrix will be saved
"""

import os
import sys
import numpy as np
import nibabel as nib
from scipy import spatial
import subprocess
import pygeodesic.geodesic as geodesic
import warnings
warnings.filterwarnings('ignore')


lh_surf = sys.argv[1]
rh_surf = sys.argv[2]
lh_parc = sys.argv[3]
rh_parc = sys.argv[4]
parc_str = sys.argv[5]
outDir = sys.argv[6]


# Load data
surf = nib.load(lh_surf).darrays
surf_L = surf[0].data
surf = nib.load(rh_surf).darrays
surf_R = surf[0].data
vertices = np.concatenate((surf_L, surf_R), axis=0)
NumVert = vertices.shape[0]

parc = nib.load(lh_parc).darrays
parc_L = parc[0].data
if np.unique(parc_L)[0] == 0:
    NumROI_L = len(np.unique(parc_L))-1
else:
    NumROI_L = len(np.unique(parc_L))

parc = nib.load(rh_parc).darrays
parc_R = parc[0].data
if np.unique(parc_R)[0] == 0:
    NumROI_R = len(np.unique(parc_R))-1
else:
    NumROI_R = len(np.unique(parc_R))
NumROI = NumROI_L + NumROI_R
parc = np.concatenate((parc_L, parc_R), axis=0)


# Find center vertices
uparcel = np.unique(parc)
if uparcel[0] == 0:
    uparcel = np.delete(uparcel, 0, 0)
NumROI = len(uparcel)

print("      - Finding central vertex for each parcel")
voi = np.zeros([1, NumROI])
for (n, _) in enumerate(uparcel):
    this_parc = np.where(parc == uparcel[n])[0]
    distances = spatial.distance.pdist(np.squeeze(vertices[this_parc, :]),'euclidean')  # Returns condensed matrix of distances
    distancesSq = spatial.distance.squareform(distances)  # convert to square form
    sumDist = np.sum(distancesSq, axis=1)  # sum distance across columns
    index = np.where(sumDist == np.min(sumDist))  # minimum sum distance index
    voi[0, n] = this_parc[index[0][0]]


# Calculate distance from VERTEX to all other central VERTICES
GD = np.zeros((NumROI, NumROI))

print("      - Running geodesic distance")
# Left hemisphere
N = NumROI_L
parcL = parc[0:int(NumVert/2)]
# Iterate over each central vertex
for ii in range(N):
    vertex = int(voi[0, ii])
    voiStr = str(vertex)

    # Calculate the GD from tha vertex to the rest of the vertices
    cmdStr = "wb_command -surface-geodesic-distance {lh_surf} {voiStr} {outDir}/this_voi.func.gii".format(lh_surf=lh_surf,voiStr=voiStr,outDir=outDir)
    subprocess.run(cmdStr.split())

    # Load file with GD column format
    tmp = nib.load(outDir + '/this_voi.func.gii').agg_data()
    parcGD = np.zeros((1, N))
    for n in range(N):
        tmpData = tmp[parcL == uparcel[n]]
        tmpMean = np.mean(tmpData)
        parcGD[0, n] = tmpMean

    # Save column on GD matrix
    GD[ii, :] = np.append(parcGD, np.zeros((1, NumROI_R)), axis=1)

# Right hemisphere
N = NumROI_R
parcR = parc[int(NumVert/2):]
# Iterate over each central vertex
for ii in range(N):
    ii_rh = int(ii + len(uparcel) / 2)
    vertex = int(voi[0, ii_rh] - int(NumVert/2))
    voiStr = str(vertex)

    # Calculate the GD from tha vertex to the rest of the vertices
    cmdStr = "wb_command -surface-geodesic-distance {rh_surf} {voiStr} {outDir}/this_voi.func.gii".format(rh_surf=rh_surf,voiStr=voiStr,outDir=outDir)
    subprocess.run(cmdStr.split())

    # Load file with GD column format
    tmp = nib.load(outDir + '/this_voi.func.gii').agg_data()
    parcGD = np.zeros((1, N))
    for n in range(N):
        n_rh = int(n + len(uparcel) / 2)
        tmpData = tmp[parcR == uparcel[n_rh]]
        tmpMean = np.mean(tmpData)
        parcGD[0, n] = tmpMean

    # Save column on GD matrix
    GD[ii_rh, :] = np.append(np.zeros((1, NumROI_L)), parcGD, axis=1)

os.remove(outDir+'/this_voi.func.gii')

# Save data
tmp = parc_str.split('_')
outName = tmp[0]
np.savetxt(outDir+'/GD_'+outName+'.txt', GD)
