import os
import shutil
import argparse
import numpy as np
import nibabel as nib

parser = argparse.ArgumentParser()
parser.add_argument("--FuNP")
parser.add_argument("--tmp_dir")
parser.add_argument("--resize", default=False)
parser.add_argument("--resize_inv", default=False)
args = parser.parse_args()

FuNP = args.FuNP
tmp_dir = args.tmp_dir
resize = args.resize
resize_inv = args.resize_inv


if resize:
    img = np.zeros((256, 256, 256, 3))
    temp = np.zeros((227, 272, 227, 3))

    t1 = nib.load(tmp_dir + "/T1w_MNI.nii.gz").get_fdata()
    pve = nib.load(tmp_dir + "/T1w_MNI_pveseg.nii.gz").get_fdata()

    for i in range(1, 4):
        x, y, z = np.where(pve == i); temp[x, y, z, i-1] = t1[x, y, z]

    img[14:-15, : ,14:-15, :] = temp[:, 8:-8, :, :]
    np.save(tmp_dir + '/T1w_MNI_pveseg.npy', img)
    print("\nCropping T1-weighted image... \n")

if resize_inv:
    MNI_header = nib.load(FuNP + "/template/MNI152_T1_0.8mm_brain.nii.gz").header
    img = np.zeros((227, 272, 227))

    t2 = np.load(tmp_dir + '/output_T2w.npy')
    t2 = (t2 - t2.min()) / (t2.max() - t2.min())

    img[:, 8:-8, :] = t2[14:-15, :, 14:-15]
    nifti_img = nib.Nifti1Image(img, affine=None, header=MNI_header)

    nib.save(nifti_img, tmp_dir + '/output_MNI.nii.gz')
    print("\nPadding T2-weighted image... \n")


