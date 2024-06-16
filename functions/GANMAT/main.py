import argparse
from t2 import *

os.environ['KMP_DUPLICATE_LIB_OK']='True' 

parser = argparse.ArgumentParser()
parser.add_argument("--FuNP", type=str, dest="FuNP")
parser.add_argument("--tmp_dir", type=str, dest="tmp_dir")
parser.add_argument("--gpu_name", type=str, dest="gpu_name")
parser.add_argument("--batch_size", default=1, type=int, dest="batch_size")
args = parser.parse_args()

test(args)
