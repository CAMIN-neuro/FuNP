import os
import torch
import numpy as np

from torch.utils.data import DataLoader
from model import *


def test(args):
    FuNP = args.FuNP
    tmp_dir = args.tmp_dir
    gpu_name = args.gpu_name
    batch_size = args.batch_size

    device = torch.device(gpu_name if torch.cuda.is_available() else 'cpu')

    netG = Pix2Pix_3D(in_channels=3, out_channels=1).to(device)
    dict_model = torch.load("{}/functions/GANMAT/model.pth".format(FuNP), map_location=device)
    netG.load_state_dict(dict_model['netG'])

    input = np.load(tmp_dir + "/T1w_MNI_pveseg.npy")
    for i in range(input.shape[-1]):
        input[:, :, :, i] = (input[:, :, :, i] - input[:, :, :, i].mean()) / input[:, :, :, i].std()
    input = input.transpose((3, 0, 1, 2)).astype(np.float32); input = input[np.newaxis, :, :, :, :]
    input = torch.from_numpy(input).to(device)

    with torch.no_grad():
        netG.eval()
        output = netG(input)[0, 0]

        np.save(tmp_dir + "/output_T2w.npy", output.cpu().detach().numpy())
        print("\nsynthesizing T2-weighted MRI...\n")
