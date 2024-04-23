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

### Check volume data
func_proc = dataDir + '/volume/func_clean_vol_SBRef.nii.gz'
display = plotting.plot_img(func_proc, colorbar=True, display_mode='ortho', draw_cross=False,
                            title='func_proc', cmap=plt.cm.gray, black_bg=True, output_file=qcDir+'/func_proc')
# head motion
mc = np.loadtxt(dataDir + '/volume/MC.1D')
pltpy.figure(figsize=(10,5))
pltpy.plot(mc[:,0:3], linestyle='dashed')
pltpy.plot(mc[:,3:], linestyle='solid')
pltpy.title('Head motion')
pltpy.legend(['t-x', 't-y', 't-z', 'r-x', 'r-y', 'r-z'])
pltpy.savefig(qcDir + '/motion.png')

fd = np.loadtxt(dataDir + '/volume/FD.1D')
pltpy.figure(figsize=(10,5))
pltpy.plot(fd, "k-")
pltpy.axhline(y=0.3, color='g', linestyle=':')
pltpy.title('Framewise displacement')
pltpy.savefig(qcDir + '/fd.png')

# registration
func2hr = dataDir + '/volume/reg/Func2HR.nii.gz'
func2std = dataDir + '/volume/reg/Func2STD.nii.gz'
hr2std = dataDir + '/volume/reg/HR2STD.nii.gz'
hr = dataDir + '/volume/reg/highres.nii.gz'
std = dataDir + '/volume/reg/standard.nii.gz'

display = plotting.plot_img(hr, colorbar=False, display_mode='ortho', draw_cross=False,
                            title='Back: T1w, Fore: Func', cmap=plt.cm.gist_heat, black_bg=True)
display.add_overlay(func2hr, threshold=0.1, alpha=0.5, cmap=plt.cm.viridis)
display.savefig(qcDir+'/reg_Func2HR')
display.close()

display = plotting.plot_img(std, colorbar=False, display_mode='ortho', draw_cross=False,
                            title='Back: MNI, Fore: T1w', cmap=plt.cm.gist_heat, black_bg=True)
display.add_overlay(hr2std, threshold=0.1, alpha=0.5, cmap=plt.cm.viridis)
display.savefig(qcDir+'/reg_HR2STD')
display.close()

display = plotting.plot_img(std, colorbar=False, display_mode='ortho', draw_cross=False,
                            title='Back: MNI, Fore: Func', cmap=plt.cm.gist_heat, black_bg=True)
display.add_overlay(func2std, threshold=0.1, alpha=0.5, cmap=plt.cm.viridis)
display.savefig(qcDir+'/reg_Func2STD')
display.close()


### Connectomes
parc_list = ['aparc', 'economo', 'glasser-360', 'schaefer-100', 'schaefer-200', 'schaefer-300', 'schaefer-400', 'schaefer-500',
             'schaefer-600', 'schaefer-700', 'schaefer-800', 'schaefer-900', 'schaefer-1000',
             'vosdewael-100', 'vosdewael-200', 'vosdewael-300', 'vosdewael-400']
for pl in parc_list:
    mat = np.loadtxt(dataDir + '/surface/connectomes/Z_sub-cor-connectome_' + pl + '.txt')

    pltpy.figure()
    pltpy.imshow(mat, cmap="viridis", vmin=-1, vmax=1)
    pltpy.title('sctx & ' + pl)
    pltpy.colorbar()
    pltpy.savefig(qcDir + '/connectome_' + pl + '.png')

### Gradients
surf_lh, surf_rh = load_conte69()
dsize = (900, 250)
display = Display(visible=0, size=dsize)
display.start()
for pl in parc_list:
    mat = np.loadtxt(dataDir + '/surface/connectomes/Z_sub-cor-connectome_' + pl + '.txt')
    mat = mat[14:,14:]
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
