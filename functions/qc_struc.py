import sys
import numpy as np
import nibabel as nib
from nilearn import plotting
import matplotlib as plt
from brainspace.datasets import load_conte69
from brainspace.mesh.mesh_io import read_surface
from brainspace.plotting import plot_hemispheres
from brainspace.vtk_interface import wrap_vtk, serial_connect
from vtk import vtkPolyDataNormals
from pyvirtualdisplay import Display
import warnings
warnings.filterwarnings('ignore')

dataDir = sys.argv[1]
qcDir = sys.argv[2]

### Check volume data
T1w = dataDir + '/wb_adjust/MNINonLinear/T1w_restore.nii.gz'
T1w_brain = dataDir + '/wb_adjust/MNINonLinear/T1w_restore_brain.nii.gz'
T1w_mask = dataDir + '/wb_adjust/MNINonLinear/brainmask_fs.nii.gz'
display = plotting.plot_img(T1w, colorbar=True, display_mode='ortho', draw_cross=False,
                            title='T1w_restore', cmap=plt.cm.gray, black_bg=True, output_file=qcDir+'/T1w_restore')
display = plotting.plot_img(T1w_brain, colorbar=True, display_mode='ortho', draw_cross=False,
                            title='T1w_restore_brain', cmap=plt.cm.gray, black_bg=True, output_file=qcDir+'/T1w_restore_brain')
plotting.plot_roi(T1w_mask, T1w, threshold=0.5, alpha=0.5, display_mode='ortho', draw_cross=False,
                  title='T1w_mask', cmap=plt.cm.Reds, black_bg=True, output_file=qcDir+'/T1w_mask')


### Check surface data
def load_surface(lh, rh, with_normals=True, join=False):
    """
    Loads surfaces.

    Parameters
    ----------
    with_normals : bool, optional
        Whether to compute surface normals. Default is True.
    join : bool, optional.
        If False, return one surface for left and right hemispheres. Otherwise,
        return a single surface as a combination of both left and right.
        surfaces. Default is False.

    Returns
    -------
    surf : tuple of BSPolyData or BSPolyData.
        Surfaces for left and right hemispheres. If ``join == True``, one
        surface with both hemispheres.
    """

    surfs = [None] * 2
    for i, side in enumerate([lh, rh]):
        surfs[i] = read_surface(side)
        if with_normals:
            nf = wrap_vtk(vtkPolyDataNormals, splitting=False,
                          featureAngle=0.1)
            surfs[i] = serial_connect(surfs[i], nf)

    if join:
        return combine_surfaces(*surfs)
    return surfs[0], surfs[1]

# surfaces
lhM, rhM = load_surface(dataDir + '/wb_adjust/MNINonLinear/fsaverage_LR32k/L.midthickness.32k_fs_LR.surf.gii',
                        dataDir + '/wb_adjust/MNINonLinear/fsaverage_LR32k/R.midthickness.32k_fs_LR.surf.gii', with_normals=True, join=False)
lhP, rhP = load_surface(dataDir + '/wb_adjust/MNINonLinear/fsaverage_LR32k/L.pial.32k_fs_LR.surf.gii',
                        dataDir + '/wb_adjust/MNINonLinear/fsaverage_LR32k/R.pial.32k_fs_LR.surf.gii', with_normals=True, join=False)
lhW, rhW = load_surface(dataDir + '/wb_adjust/MNINonLinear/fsaverage_LR32k/L.white.32k_fs_LR.surf.gii',
                        dataDir + '/wb_adjust/MNINonLinear/fsaverage_LR32k/R.white.32k_fs_LR.surf.gii', with_normals=True, join=False)
Val = np.repeat(0, lhM.n_points + rhM.n_points, axis=0)

dsize = (900, 250)
display = Display(visible=0, size=dsize)
display.start()
plot_hemispheres(lhM, rhM, array_name=Val, size=(900, 250), zoom=1.25, embed_nb=True, interactive=False, share='both',
                 nan_color=(0, 0, 0, 1), color_range=(-1, 1), cmap='summer', transparent_bg=False,
                 screenshot=True, offscreen=True,
                 filename=qcDir + '/surf_midthickness.png')
plot_hemispheres(lhP, rhP, array_name=Val, size=(900, 250), zoom=1.25, embed_nb=True, interactive=False, share='both',
                 nan_color=(0, 0, 0, 1), color_range=(1.5, 4), cmap='summer', transparent_bg=False,
                 screenshot=True, offscreen=True,
                 filename=qcDir + '/surf_pial.png')
plot_hemispheres(lhW, rhW, array_name=Val, size=(900, 250), zoom=1.25, embed_nb=True, interactive=False, share='both',
                 nan_color=(0, 0, 0, 1), color_range=(1.5, 4), cmap='summer', transparent_bg=False,
                 screenshot=True, offscreen=True,
                 filename=qcDir + '/surf_white.png')
display.stop()


# cortical features
surf_lh, surf_rh = load_conte69()
dsize = (900, 250)
display = Display(visible=0, size=dsize)
display.start()
# thickness
gii_L = nib.load(dataDir + '/wb_adjust/MNINonLinear/fsaverage_LR32k/L.thickness.32k_fs_LR.shape.gii').darrays[0].data
gii_R = nib.load(dataDir + '/wb_adjust/MNINonLinear/fsaverage_LR32k/R.thickness.32k_fs_LR.shape.gii').darrays[0].data
gii = np.concatenate((gii_L, gii_R), axis=0)
plot_hemispheres(surf_lh, surf_rh, array_name=gii, size=dsize, color_bar='bottom', zoom=1.25, embed_nb=True,
                 interactive=False, share='both',
                 nan_color=(0, 0, 0, 1), color_range=(1.5, 4), cmap="inferno", transparent_bg=False,
                 screenshot=True, offscreen=True,
                 filename=qcDir + '/shape_thickness.png')
# curvature
gii_L = nib.load(dataDir + '/wb_adjust/MNINonLinear/fsaverage_LR32k/L.curvature.32k_fs_LR.shape.gii').darrays[0].data
gii_R = nib.load(dataDir + '/wb_adjust/MNINonLinear/fsaverage_LR32k/R.curvature.32k_fs_LR.shape.gii').darrays[0].data
gii = np.concatenate((gii_L, gii_R), axis=0)
plot_hemispheres(surf_lh, surf_rh, array_name=gii, size=dsize, color_bar='bottom', zoom=1.25, embed_nb=True,
                 interactive=False, share='both',
                 nan_color=(0, 0, 0, 1), color_range=(-0.2, 0.2), cmap="inferno", transparent_bg=False,
                 screenshot=True, offscreen=True,
                 filename=qcDir + '/shape_curvature.png')
# sulcal depth
gii_L = nib.load(dataDir + '/wb_adjust/MNINonLinear/fsaverage_LR32k/L.sulc.32k_fs_LR.shape.gii').darrays[0].data
gii_R = nib.load(dataDir + '/wb_adjust/MNINonLinear/fsaverage_LR32k/R.sulc.32k_fs_LR.shape.gii').darrays[0].data
gii = np.concatenate((gii_L, gii_R), axis=0)
plot_hemispheres(surf_lh, surf_rh, array_name=gii, size=dsize, color_bar='bottom', zoom=1.25, embed_nb=True,
                 interactive=False, share='both',
                 nan_color=(0, 0, 0, 1), color_range=(-5, 5), cmap="inferno", transparent_bg=False,
                 screenshot=True, offscreen=True,
                 filename=qcDir + '/shape_sulc.png')
display.stop()
