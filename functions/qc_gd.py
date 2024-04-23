import os, glob
import sys
import numpy as np
from nilearn import plotting
import matplotlib as plt
import matplotlib.pyplot as pltpy
from brainspace.datasets import load_parcellation, load_conte69
from brainspace.gradient import GradientMaps
from brainspace.plotting import plot_hemispheres
from brainspace.utils.parcellation import map_to_labels
from brainspace.mesh.mesh_io import read_surface
from brainspace.vtk_interface import wrap_vtk, serial_connect
from vtk import vtkPolyDataNormals
from pyvirtualdisplay import Display
import warnings
warnings.filterwarnings('ignore')

dataDir = sys.argv[1]
qcDir = sys.argv[2]
funpDir = sys.argv[3]

### Connectomes
parc_list = ['aparc', 'economo', 'glasser-360', 'schaefer-100', 'schaefer-200', 'schaefer-300', 'schaefer-400', 'schaefer-500',
             'schaefer-600', 'schaefer-700', 'schaefer-800', 'schaefer-900', 'schaefer-1000',
             'vosdewael-100', 'vosdewael-200', 'vosdewael-300', 'vosdewael-400']
for pl in parc_list:
    mat = np.loadtxt(dataDir + '/GD_' + pl + '.txt')

    pltpy.figure()
    pltpy.imshow(mat, cmap="viridis", vmin=0, vmax=300)
    pltpy.title('sctx & ' + pl)
    pltpy.colorbar()
    pltpy.savefig(qcDir + '/connectome_' + pl + '.png')

### Gradients
surf_lh, surf_rh = load_conte69()
dsize = (900, 250)
display = Display(visible=0, size=dsize)
display.start()
for pl in parc_list:
    mat = np.loadtxt(dataDir + '/GD_' + pl + '.txt')
    mat = np.nan_to_num(mat, nan=0.000001, posinf=0.000001)
    mat = mat + 0.00001
    np.fill_diagonal(mat, 0)
    gm = GradientMaps(kernel='normalized_angle', approach='dm', n_components=5, random_state=0)
    gm.fit(mat)

    labeling = np.loadtxt(funpDir + '/parcellations/' + pl + '_conte69.csv', dtype=np.int64)
    mask = labeling != 0
    for i in range(3):
        grad = map_to_labels(gm.gradients_[:,i], labeling, mask=mask, fill=np.nan)
        plot_hemispheres(surf_lh, surf_rh, array_name=grad, size=dsize, color_bar=True, zoom=1.25, embed_nb=True,
                         interactive=False, share='both',
                         nan_color=(0, 0, 0, 1), cmap="viridis",
                         transparent_bg=False,
                         screenshot=True, offscreen=True,
                         filename=qcDir + '/gradient_' + pl + '-' + str(i) + '.png')
display.stop()
