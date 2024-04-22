#!/usr/bin/env python3.7
# -*- coding: utf-8 -*-

"""
    bval        :  (str) dMRI b-value file with full directory
"""

import sys
import numpy as np
import warnings
warnings.filterwarnings('ignore')

bval = sys.argv[1]

bval_arr = np.loadtxt(bval)
bval_uniq = np.unique(bval_arr)
num_shell = np.size(bval_uniq) - 1

print(num_shell)