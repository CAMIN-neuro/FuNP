#!/usr/bin/env python3.7
# -*- coding: utf-8 -*-

"""
    modType     :  (str) Type of modality (struc, dwi, func, gd, mpc)
    dataDir     :  (str) Directory that contains preprocessed data
    qcDir       :  (str) Output directory that QC files will be saved
    funpDir     :  (str) Directory of FuNP
"""

import os, glob
import sys
import numpy as np
import nibabel as nib
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

modType = sys.argv[1]
dataDir = sys.argv[2]
qcDir = sys.argv[3]
funpDir = sys.argv[4]


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


if modType == 'struc':
    ### Check volume data
    T1w = dataDir + '/wb_adjust/MNINonLinear/T1w_restore.nii.gz'
    T1w_brain = dataDir + '/wb_adjust/MNINonLinear/T1w_restore_brain.nii.gz'
    T1w_mask = dataDir + '/wb_adjust/MNINonLinear/brainmask_fs.nii.gz'
    display = plotting.plot_img(T1w, colorbar=True, display_mode='ortho', draw_cross=False,
                                title='T1w_restore', cmap=plt.cm.gray, black_bg=True,
                                output_file=qcDir + '/T1w_restore')
    display = plotting.plot_img(T1w_brain, colorbar=True, display_mode='ortho', draw_cross=False,
                                title='T1w_restore_brain', cmap=plt.cm.gray, black_bg=True,
                                output_file=qcDir + '/T1w_restore_brain')
    plotting.plot_roi(T1w_mask, T1w, threshold=0.5, alpha=0.5, display_mode='ortho', draw_cross=False,
                      title='T1w_mask', cmap=plt.cm.Reds, black_bg=True, output_file=qcDir + '/T1w_mask')

    ### Check surface data
    ## surfaces
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
                     screenshot=True, offscreen=True, filename=qcDir + '/surf_midthickness.png')
    plot_hemispheres(lhP, rhP, array_name=Val, size=(900, 250), zoom=1.25, embed_nb=True, interactive=False, share='both',
                     nan_color=(0, 0, 0, 1), color_range=(1.5, 4), cmap='summer', transparent_bg=False,
                     screenshot=True, offscreen=True, filename=qcDir + '/surf_pial.png')
    plot_hemispheres(lhW, rhW, array_name=Val, size=(900, 250), zoom=1.25, embed_nb=True, interactive=False, share='both',
                     nan_color=(0, 0, 0, 1), color_range=(1.5, 4), cmap='summer', transparent_bg=False,
                     screenshot=True, offscreen=True,filename=qcDir + '/surf_white.png')
    display.stop()

    ## cortical features
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
                     screenshot=True, offscreen=True, filename=qcDir + '/shape_thickness.png')
    # curvature
    gii_L = nib.load(dataDir + '/wb_adjust/MNINonLinear/fsaverage_LR32k/L.curvature.32k_fs_LR.shape.gii').darrays[0].data
    gii_R = nib.load(dataDir + '/wb_adjust/MNINonLinear/fsaverage_LR32k/R.curvature.32k_fs_LR.shape.gii').darrays[0].data
    gii = np.concatenate((gii_L, gii_R), axis=0)
    plot_hemispheres(surf_lh, surf_rh, array_name=gii, size=dsize, color_bar='bottom', zoom=1.25, embed_nb=True,
                     interactive=False, share='both',
                     nan_color=(0, 0, 0, 1), color_range=(-0.2, 0.2), cmap="inferno", transparent_bg=False,
                     screenshot=True, offscreen=True, filename=qcDir + '/shape_curvature.png')
    # sulcal depth
    gii_L = nib.load(dataDir + '/wb_adjust/MNINonLinear/fsaverage_LR32k/L.sulc.32k_fs_LR.shape.gii').darrays[0].data
    gii_R = nib.load(dataDir + '/wb_adjust/MNINonLinear/fsaverage_LR32k/R.sulc.32k_fs_LR.shape.gii').darrays[0].data
    gii = np.concatenate((gii_L, gii_R), axis=0)
    plot_hemispheres(surf_lh, surf_rh, array_name=gii, size=dsize, color_bar='bottom', zoom=1.25, embed_nb=True,
                     interactive=False, share='both',
                     nan_color=(0, 0, 0, 1), color_range=(-5, 5), cmap="inferno", transparent_bg=False,
                     screenshot=True, offscreen=True, filename=qcDir + '/shape_sulc.png')
    display.stop()
elif modType == 'dwi':
    os.system("mrconvert " + dataDir + "/dwi_b0.mif " + dataDir + "/dwi_b0.nii.gz -force")
    os.system("mrconvert " + dataDir + "/dwi_b0_brain.mif " + dataDir + "/dwi_b0_brain.nii.gz -force")
    os.system("mrconvert " + dataDir + "/dwi_mask.mif " + dataDir + "/dwi_mask.nii.gz -force")
    os.system("fslsplit " + dataDir + "/5TT2b0.nii.gz " + dataDir + "/5TT2b0_split -t")

    ### Check dwi data
    dwi = dataDir + '/dwi_b0.nii.gz'
    dwi_brain = dataDir + '/dwi_b0_brain.nii.gz'
    dwi_mask = dataDir + '/dwi_mask.nii.gz'
    display = plotting.plot_img(dwi, colorbar=True, display_mode='ortho', draw_cross=False,
                                title='dwi_b0', cmap=plt.cm.gray, black_bg=True, output_file=qcDir + '/dwi_b0')
    display = plotting.plot_img(dwi_brain, colorbar=True, display_mode='ortho', draw_cross=False,
                                title='dwi_b0_brain', cmap=plt.cm.gray, black_bg=True, output_file=qcDir + '/dwi_b0_brain')
    plotting.plot_roi(dwi_mask, dwi, threshold=0.5, alpha=0.2, display_mode='ortho', draw_cross=False,
                      title='dwi_mask', cmap=plt.cm.Reds, black_bg=True, output_file=qcDir + '/dwi_mask')

    # 5TT
    for i in range(0, 5):
        mask = dataDir + '/5TT2b0_split000' + str(i) + '.nii.gz'
        plotting.plot_roi(mask, dwi, threshold=0.5, alpha=0.5, display_mode='ortho', draw_cross=False,
                          title='5TT mask' + str(i), cmap=plt.cm.Reds, black_bg=True, output_file=qcDir + '/5TT_mask' + str(i))

    # FIRST
    firstseg = dataDir + '/T1w_all_fast_seg2b0.nii.gz'
    plotting.plot_roi(firstseg, dwi, threshold=0.5, alpha=1, display_mode='ortho', draw_cross=False,
                      title='firstseg', cmap=plt.cm.gist_rainbow, black_bg=True, output_file=qcDir + '/firstseg')

    # Cortical parcellations
    parc_list = ['aparc', 'economo', 'glasser-360', 'schaefer-100', 'schaefer-200', 'schaefer-300', 'schaefer-400',
                 'schaefer-500', 'schaefer-600', 'schaefer-700', 'schaefer-800', 'schaefer-900', 'schaefer-1000',
                 'vosdewael-100', 'vosdewael-200', 'vosdewael-300', 'vosdewael-400']
    for pl in parc_list:
        atlas = dataDir + '/parcellations/' + pl + '.nii.gz'
        plotting.plot_roi(atlas, dwi, threshold=0.5, alpha=1, display_mode='ortho', draw_cross=False,
                          title=pl, cmap=plt.cm.gist_rainbow, black_bg=True, output_file=qcDir + '/parc_' + pl)

    ### Connectomes
    for pl in parc_list:
        mat = np.loadtxt(dataDir + '/connectomes/iFOD2-40M_SIFT2_sub-cor-connectome_' + pl + '.txt')
        pltpy.figure()
        pltpy.imshow(mat, cmap="viridis", vmin=0, vmax=10000)
        pltpy.title('sctx & ' + pl)
        pltpy.colorbar()
        pltpy.savefig(qcDir + '/connectome_' + pl + '.png')

    ### Gradients
    surf_lh, surf_rh = load_conte69()
    dsize = (900, 250)
    display = Display(visible=0, size=dsize)
    display.start()
    for pl in parc_list:
        mat = np.loadtxt(dataDir + '/connectomes/iFOD2-40M_SIFT2_cor-connectome_' + pl + '.txt')
        mat = np.nan_to_num(mat, nan=0.000001, posinf=0.000001)
        mat = mat + 0.00001
        gm = GradientMaps(kernel='normalized_angle', approach='dm', n_components=5, random_state=0)
        gm.fit(mat)

        labeling = np.loadtxt(funpDir + '/parcellations/' + pl + '_conte69.csv', dtype=np.int64)
        mask = labeling != 0
        for i in range(3):
            grad = map_to_labels(gm.gradients_[:, i], labeling, mask=mask, fill=np.nan)
            plot_hemispheres(surf_lh, surf_rh, array_name=grad, size=dsize, color_bar=True, zoom=1.25, embed_nb=True,
                             interactive=False, share='both', nan_color=(0, 0, 0, 1), cmap="viridis", transparent_bg=False,
                             screenshot=True, offscreen=True, filename=qcDir + '/gradient_' + pl + '-' + str(i) + '.png')
    display.stop()

    os.system("rm -rf " + dataDir + "/dwi_b0.nii.gz")
    os.system("rm -rf " + dataDir + "/dwi_b0_brain.nii.gz")
    os.system("rm -rf " + dataDir + "/dwi_mask.nii.gz")
    os.system("rm -rf " + dataDir + "/5TT2b0_split*.nii.gz")
elif modType == 'func':
    ### Check volume data
    func_proc = dataDir + '/volume/func_clean_vol_SBRef.nii.gz'
    display = plotting.plot_img(func_proc, colorbar=True, display_mode='ortho', draw_cross=False,
                                title='func_proc', cmap=plt.cm.gray, black_bg=True, output_file=qcDir + '/func_proc')

    # Head motion
    mc = np.loadtxt(dataDir + '/volume/MC.1D')
    pltpy.figure(figsize=(10, 5))
    pltpy.plot(mc[:, 0:3], linestyle='dashed')
    pltpy.plot(mc[:, 3:], linestyle='solid')
    pltpy.title('Head motion')
    pltpy.legend(['t-x', 't-y', 't-z', 'r-x', 'r-y', 'r-z'])
    pltpy.savefig(qcDir + '/motion.png')

    fd = np.loadtxt(dataDir + '/volume/FD.1D')
    pltpy.figure(figsize=(10, 5))
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
    display.savefig(qcDir + '/reg_Func2HR')
    display.close()

    display = plotting.plot_img(std, colorbar=False, display_mode='ortho', draw_cross=False,
                                title='Back: MNI, Fore: T1w', cmap=plt.cm.gist_heat, black_bg=True)
    display.add_overlay(hr2std, threshold=0.1, alpha=0.5, cmap=plt.cm.viridis)
    display.savefig(qcDir + '/reg_HR2STD')
    display.close()

    display = plotting.plot_img(std, colorbar=False, display_mode='ortho', draw_cross=False,
                                title='Back: MNI, Fore: Func', cmap=plt.cm.gist_heat, black_bg=True)
    display.add_overlay(func2std, threshold=0.1, alpha=0.5, cmap=plt.cm.viridis)
    display.savefig(qcDir + '/reg_Func2STD')
    display.close()

    ### Connectomes
    parc_list = ['aparc', 'economo', 'glasser-360', 'schaefer-100', 'schaefer-200', 'schaefer-300', 'schaefer-400',
                 'schaefer-500', 'schaefer-600', 'schaefer-700', 'schaefer-800', 'schaefer-900', 'schaefer-1000',
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
        mat = mat[14:, 14:]
        mat = np.nan_to_num(mat, nan=0.000001, posinf=0.000001)
        mat = mat + 0.00001
        np.fill_diagonal(mat, 0)
        gm = GradientMaps(kernel='normalized_angle', approach='dm', n_components=5, random_state=0)
        gm.fit(mat)

        labeling = np.loadtxt(funpDir + '/parcellations/' + pl + '_conte69.csv', dtype=np.int64)
        mask = labeling != 0
        for i in range(3):
            grad = map_to_labels(gm.gradients_[:, i], labeling, mask=mask, fill=np.nan)
            plot_hemispheres(surf_lh, surf_rh, array_name=grad, size=dsize, color_bar=True, zoom=1.25, embed_nb=True,
                             interactive=False, share='both', nan_color=(0, 0, 0, 1), cmap="viridis", transparent_bg=False,
                             screenshot=True, offscreen=True, filename=qcDir + '/gradient_' + pl + '-' + str(i) + '.png')
    display.stop()
elif modType == 'gd':
    ### Connectomes
    parc_list = ['aparc', 'economo', 'glasser-360', 'schaefer-100', 'schaefer-200', 'schaefer-300', 'schaefer-400',
                 'schaefer-500', 'schaefer-600', 'schaefer-700', 'schaefer-800', 'schaefer-900', 'schaefer-1000',
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
            grad = map_to_labels(gm.gradients_[:, i], labeling, mask=mask, fill=np.nan)
            plot_hemispheres(surf_lh, surf_rh, array_name=grad, size=dsize, color_bar=True, zoom=1.25, embed_nb=True,
                             interactive=False, share='both', nan_color=(0, 0, 0, 1), cmap="viridis", transparent_bg=False,
                             screenshot=True, offscreen=True, filename=qcDir + '/gradient_' + pl + '-' + str(i) + '.png')
    display.stop()
elif modType == 'mpc':
    strucDir = dataDir + '/../struc'
    ### Check volume data
    myelin = strucDir + '/wb_adjust/MNINonLinear/T1wDividedByT2w.nii.gz'
    display = plotting.plot_img(myelin, colorbar=True, display_mode='ortho', draw_cross=False,
                                title='T1w/T2w', cmap=plt.cm.gray, vmin=0, vmax=1, black_bg=True,
                                output_file=qcDir + '/T1T2ratio')

    ### Check surface data
    surf_lh, surf_rh = load_conte69()
    dsize = (900, 250)
    display = Display(visible=0, size=dsize)
    display.start()
    gii_L = nib.load(strucDir + '/wb_adjust/MNINonLinear/fsaverage_LR32k/L.MyelinMap.32k_fs_LR.func.gii').darrays[0].data
    gii_R = nib.load(strucDir + '/wb_adjust/MNINonLinear/fsaverage_LR32k/R.MyelinMap.32k_fs_LR.func.gii').darrays[0].data
    gii = np.concatenate((gii_L, gii_R), axis=0)
    plot_hemispheres(surf_lh, surf_rh, array_name=gii, size=dsize, color_bar='bottom', zoom=1.25, embed_nb=True,
                     interactive=False, share='both',
                     nan_color=(0, 0, 0, 1), color_range=(np.mean(gii) * 0.5, np.mean(gii) * 1.5), cmap="viridis",
                     transparent_bg=False, screenshot=True, offscreen=True, filename=qcDir + '/MyelinMap.png')

    gii_L = nib.load(strucDir + '/wb_adjust/MNINonLinear/fsaverage_LR32k/L.SmoothedMyelinMap.32k_fs_LR.func.gii').darrays[0].data
    gii_R = nib.load(strucDir + '/wb_adjust/MNINonLinear/fsaverage_LR32k/R.SmoothedMyelinMap.32k_fs_LR.func.gii').darrays[0].data
    gii = np.concatenate((gii_L, gii_R), axis=0)
    plot_hemispheres(surf_lh, surf_rh, array_name=gii, size=dsize, color_bar='bottom', zoom=1.25, embed_nb=True,
                     interactive=False, share='both',
                     nan_color=(0, 0, 0, 1), color_range=(np.mean(gii) * 0.5, np.mean(gii) * 1.5), cmap="viridis",
                     transparent_bg=False, screenshot=True, offscreen=True, filename=qcDir + '/SmoothMyelinMap.png')
    display.stop()

    ### Connectomes
    parc_list = ['aparc', 'economo', 'glasser-360', 'schaefer-100', 'schaefer-200', 'schaefer-300', 'schaefer-400',
                 'schaefer-500', 'schaefer-600', 'schaefer-700', 'schaefer-800', 'schaefer-900', 'schaefer-1000',
                 'vosdewael-100', 'vosdewael-200', 'vosdewael-300', 'vosdewael-400']
    for pl in parc_list:
        mat = np.loadtxt(dataDir + '/mpc_' + pl + '.txt')
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
        mat = np.loadtxt(dataDir + '/mpc_' + pl + '.txt')
        mat = np.nan_to_num(mat, nan=0.000001, posinf=0.000001)
        mat = mat + 0.00001
        np.fill_diagonal(mat, 0)
        gm = GradientMaps(kernel='normalized_angle', approach='dm', n_components=5, random_state=0)
        gm.fit(mat)

        labeling = np.loadtxt(funpDir + '/parcellations/' + pl + '_conte69.csv', dtype=np.int64)
        mask = labeling != 0
        for i in range(3):
            grad = map_to_labels(gm.gradients_[:, i], labeling, mask=mask, fill=np.nan)
            plot_hemispheres(surf_lh, surf_rh, array_name=grad, size=dsize, color_bar=True, zoom=1.25, embed_nb=True,
                             interactive=False, share='both',
                             nan_color=(0, 0, 0, 1), cmap="viridis",
                             transparent_bg=False,
                             screenshot=True, offscreen=True,
                             filename=qcDir + '/gradient_' + pl + '-' + str(i) + '.png')
    display.stop()
else:
    raise Exception('No valid "modType" is entered!!!')
