#!/usr/bin/env python3.7
# -*- coding: utf-8 -*-

"""
    Nvol_rev    :  (int) Number of volumes of the reverse phased data
    readout     :  (float) Total readout time
    outDir      :  (str) Output directory that acqparams will be saved
"""

import sys
import numpy as np

Nvol_rev = int(sys.argv[1])
readout = float(sys.argv[2])
outDir = sys.argv[3]

acqpar = np.zeros((Nvol_rev*2, 4))
for ap in range(0,Nvol_rev):
    acqpar[ap,1] = -1
    acqpar[ap+Nvol_rev,1] = 1
acqpar[:,3] = readout

np.savetxt(outDir+'/acqparams.txt', acqpar)
