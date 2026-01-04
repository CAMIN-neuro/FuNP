import sys
import nibabel as nib
import numpy as np

in_seg = sys.argv[1]
out_seg = sys.argv[2]

LEFT = [10, 11, 12, 13, 17, 18, 26]
RIGHT = [49, 50, 51, 52, 53, 54, 58]
LABELS = LEFT + RIGHT

seg = nib.load(in_seg)
data = seg.get_fdata().astype(np.int32)

subcortex = np.zeros_like(data)
for lab in LABELS:
    subcortex[data == lab] = lab

nib.save(nib.Nifti1Image(subcortex, seg.affine, seg.header), out_seg)
