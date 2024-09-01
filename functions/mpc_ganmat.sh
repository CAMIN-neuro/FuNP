#!/bin/bash

source "${FuNP}/functions/utilities.sh"

set -e

Usage() {
    cat <<EOF
Usage: mpc.sh <t1> <strucDir> <outDir> <threads> <procDir>
  
  <t1>          T1-weighted image (NIFTI) with full directory
                It should be bias field corrected and skull removed
  <strucDir>    Directory of structural processing (typically, ~/struc)
  <outDir>      Output directory
  <threads>     Number of threads (default: 5)
  <procDir>     Processing directory (default: /tmp)

EOF
    exit 1
}

############################# Settings #############################
t1="$1"
strucDir="$2"
outDir="$3"
threads="$4"
procDir="$5"

### Check the inputs ###
input=($t1 $strucDir $outDir)
if [ "${#input[@]}" -lt 3 ]; then
    Error "A processing flag is missing:
             -t1
             -strucDir
             -out"
    exit 1;
fi
####################################################################

### Prepare the processing directory ###
tmpName=`tr -dc A-Za-z0-9 </dev/urandom | head -c 5`
tmpDir=${procDir}/${tmpName}
if [ ! -d ${tmpDir} ]; then mkdir -m 777 -p ${tmpDir}; fi


echo -e "\n### Run GAN-MAT ###"
t2=${outDir}/t2_ganmat.nii.gz
gpu_name="cuda:0"

echo -e "\n## Registration native T1w to MNI 0.8mm template"
antsRegistrationSyN.sh -d 3 -f ${t1} -m ${FuNP}/template/MNI152_T1_0.8mm_brain.nii.gz -o ${tmpDir}/from-template_to-native -t a -n ${threads} -p d
antsApplyTransforms -d 3 -i ${t1} -r ${FuNP}/template/MNI152_T1_0.8mm_brain.nii.gz -t [${tmpDir}/from-template_to-native0GenericAffine.mat ,1] -o ${tmpDir}/T1w_MNI.nii.gz -v

echo -e "\n## Tissue segmentation using FSL FAST"
fast -N ${tmpDir}/T1w_MNI.nii.gz

echo -e "\n## Synthesize T2w"
python ${FuNP}/functions/GANMAT/preprocessing.py --FuNP=${FuNP} --tmp_dir=${tmpDir} --resize=TRUE
python ${FuNP}/functions/GANMAT/main.py --FuNP=${FuNP} --tmp_dir=${tmpDir} --gpu_name=${gpu_name}  
python ${FuNP}/functions/GANMAT/preprocessing.py --FuNP=${FuNP} --tmp_dir=${tmpDir} --resize_inv=TRUE

echo -e "\n## Registration the synthesized T2w to the native space"
antsApplyTransforms -d 3 -i ${tmpDir}/output_MNI.nii.gz -r ${t1} -t ${tmpDir}/from-template_to-native0GenericAffine.mat -o ${t2} -v


rm -rfv ${tmpDir} 

echo -e "\n### GAN-MAT Finished ###"


${FuNP}/functions/mpc.sh ${t1} ${t2} ${strucDir} ${outDir} ${threads}

