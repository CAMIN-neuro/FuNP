#!/bin/bash

source "${FuNP}/functions/utilities.sh"

set -e

Usage() {
    cat <<EOF
Usage: dwi.sh <dwi_main> <dwi_bval> <dwi_bvec> <pe_dir> <strucDir> <readout> <dwi_rev> <outDir> <threads> <procDir>
  
  <dwi_main>    DWI main phase data (NIFTI) with full directory
  <dwi_bval>    DWI b-value data with full directory
  <dwi_bvec>    DWI b-vector data with full directory
  <pe_dir>      Phase encoding direction (e.g., AP, PA, LR, RL, SI, IS)
  <strucDir>    Directory of structural processing
  <readout>     Total readout time (float number)
  <outDir>      Output directory
  <dwi_rev>     DWI reverse phase data (NIFTI) with full directory
  <threads>     Number of threads (default: 5)
  <procDir>     Processing directory (default: /tmp)

EOF
    exit 1
}

############################# Settings #############################
dwi_main="$1"
dwi_bval="$2"
dwi_bvec="$3"
pe_dir="$4"
strucDir="$5"
readout="$6"
dwi_rev="$7"
outDir="$8"
threads="$9"
procDir="$10"

### Check the inputs ###
input=($dwi_main $dwi_bval $dwi_bvec $pe_dir $strucDir $readout $outDir)
if [ "${#input[@]}" -lt 7 ]; then
    Error "A processing flag is missing:
             -dwi_main
             -dwi_bval
             -dwi_bvec
             -pe_dir
             -strucDir
             -readout
             -out"
    exit 1;
fi
####################################################################

### Prepare the processing directory ###
tmpName=`tr -dc A-Za-z0-9 </dev/urandom | head -c 5`
tmpDir=${procDir}/${tmpName}
if [ ! -d ${tmpDir} ]; then mkdir -m 777 -p ${tmpDir}; fi


echo -e "\n### Start dwi processing ###"

echo -e "\n## Process main phase encoding data"
# convert to mif
mrconvert ${dwi_main} -fslgrad ${dwi_bvec} ${dwi_bval} ${tmpDir}/dwi.mif
dwiextract ${tmpDir}/dwi.mif ${tmpDir}/dwi_b0.mif -bzero
mrmath ${tmpDir}/dwi_b0.mif mean ${tmpDir}/dwi_b0.nii.gz -axis 3

# denoise
dwidenoise ${tmpDir}/dwi.mif ${tmpDir}/dwi_tmp.mif -nthreads ${threads} 
mrdegibbs ${tmpDir}/dwi_tmp.mif ${tmpDir}/dwi_dns.mif -nthreads ${threads} 
rm -rf ${tmpDir}/dwi_tmp.mif

# Remove slices to make an even number of slices in all directions (requisite for dwi_preproc-TOPUP)
dim=$(mrinfo "${tmpDir}/dwi_dns.mif" -size)
dimNew=($(echo "$dim" | awk '{for(i=1;i<=NF;i++){$i=$i-($i%2);print $i-1}}'))
mrconvert ${tmpDir}/dwi_dns.mif ${tmpDir}/dwi_dns_even.mif -coord 0 0:"${dimNew[0]}" -coord 1 0:"${dimNew[1]}" -coord 2 0:"${dimNew[2]}" -coord 3 0:end -force

# get the mean b-zero
dwiextract ${tmpDir}/dwi_dns_even.mif - -bzero | mrmath - mean ${tmpDir}/b0_meanMainPhase.mif -axis 3
mrconvert ${tmpDir}/b0_meanMainPhase.mif ${tmpDir}/b0_meanMainPhase.nii.gz
    
# get brain mask
bet2 ${tmpDir}/b0_meanMainPhase.nii.gz ${tmpDir}/dwi -f 0.3 -n -m
mrconvert ${tmpDir}/dwi_mask.nii.gz ${tmpDir}/dwi_mask.mif
fslmaths ${tmpDir}/b0_meanMainPhase.nii.gz -mul ${tmpDir}/dwi_mask.nii.gz ${tmpDir}/dwi_b0_brain.nii.gz
mrconvert ${tmpDir}/dwi_b0_brain.nii.gz ${tmpDir}/dwi_b0_brain.mif

# get motion parameters
mrconvert ${tmpDir}/dwi_dns_even.mif ${tmpDir}/dwi_dns_even.nii.gz
fsl_motion_outliers -i ${tmpDir}/dwi_dns_even -o ${tmpDir}/FD_cfd -s ${tmpDir}/FD.1D -p ${tmpDir}/FD --fd 
rm -rf ${tmpDir}/FD_cfd ${tmpDir}/dwi_dns_even.nii.gz


if [ $dwi_rev != None ]; then
    echo -e "\n## Process reverse phase encoding data"

    # convert to mif
    mrconvert ${dwi_rev} ${tmpDir}/dwi_rev.mif

    # denoise
    dwidenoise ${tmpDir}/dwi_rev.mif ${tmpDir}/dwi_rev_tmp.mif
    mrdegibbs ${tmpDir}/dwi_rev_tmp.mif ${tmpDir}/dwi_rev_dns.mif
    rm -rf ${tmpDir}/dwi_rev_tmp.mif

    # Remove slices to make an even number of slices in all directions (requisite for dwi_preproc-TOPUP)
    dim=$(mrinfo "${tmpDir}/dwi_rev_dns.mif" -size)
    dimNew=($(echo "$dim" | awk '{for(i=1;i<=NF;i++){$i=$i-($i%2);print $i-1}}'))
    mrconvert ${tmpDir}/dwi_rev_dns.mif ${tmpDir}/dwi_rev_dns_even.mif -coord 0 0:"${dimNew[0]}" -coord 1 0:"${dimNew[1]}" -coord 2 0:"${dimNew[2]}" -coord 3 0:end -force

    # get the mean b-zero
    mrmath ${tmpDir}/dwi_rev_dns_even.mif mean ${tmpDir}/b0_ReversePhase.mif -axis 3

    # concat main & reverse phase b0 data
    mrcat ${tmpDir}/b0_meanMainPhase.mif ${tmpDir}/b0_ReversePhase.mif ${tmpDir}/b0_pair.mif
    opt="-rpe_pair -align_seepi -se_epi ${tmpDir}/b0_pair.mif"

else
    opt="-rpe_none"
fi


echo -e "\n## Preproc"
dwi_4proc="${tmpDir}/dwi_dns_even.mif"
dwi_corr="${tmpDir}/dwi_preproc.mif"
dwi_n4="${tmpDir}/dwi_preproc_N4.mif"
dwi_mask="${tmpDir}/dwi_mask.mif"

dwifslpreproc ${dwi_4proc} ${dwi_corr} ${opt} -pe_dir ${pe_dir} -readout_time ${readout} -eddy_options " --data_is_shelled --slm=linear --repol" -nthreads ${threads} -nocleanup -scratch ${tmpDir} -force
if [[ ! -f ${dwi_corr} ]]; then 
    Error "dwifslpreproc failed, check the logs"
    exit;
else
    rm -rf ${tmpDir}/dwifslpreproc-tmp-*
fi

echo -e "\n## Bias field correction"
dwibiascorrect ants ${dwi_corr} ${dwi_n4} -force -nthreads ${threads} -scratch ${tmpDir}
if [[ ! -f ${dwi_n4} ]]; then 
    Error "dwibiascorrect failed, check the logs"
    exit;
else
    mv ${dwi_n4} ${dwi_corr}
fi

echo -e "\n## Get some basic metrics"
dwi2tensor -mask ${dwi_mask} ${dwi_corr} ${tmpDir}/dwi_DTI.mif
tensor2metric -fa ${tmpDir}/dwi_DTI-FA.mif -adc ${tmpDir}/dwi_DTI-ADC.mif ${tmpDir}/dwi_DTI.mif


echo -e "\n## Calculate response function and fiber orientation distribution"
# Response function
rf_wm="${tmpDir}/response_wm.mif"
rf_gm="${tmpDir}/response_gm.mif"
rf_csf="${tmpDir}/response_csf.mif"
# Fiber orientation distribution
fod_wm="${tmpDir}/wm_fod.mif"
fod_gm="${tmpDir}/gm_fod.mif"
fod_csf="${tmpDir}/csf_fod.mif"
# Normalized fiber orientation distribution
fod_wmN="${tmpDir}/wmNorm.mif"
fod_gmN="${tmpDir}/gmNorm.mif"
fod_csfN="${tmpDir}/csfNorm.mif"

NumShell=`python ${FuNP}/functions/dwi_check_shell.py ${dwi_bval}`
if [ $NumShell == 1 ]; then
    dwi2response tournier ${dwi_corr} ${rf_wm} -mask ${dwi_mask} -nthreads ${threads} 
    dwi2fod csd ${dwi_corr} ${rf_wm} ${fod_wm} -mask ${dwi_mask} -nthreads ${threads} 
else
    dwi2response dhollander ${dwi_corr} ${rf_wm} ${rf_gm} ${rf_csf} -mask ${dwi_mask} -nthreads ${threads} 
    dwi2fod msmt_csd ${dwi_corr} ${rf_wm} ${fod_wm} ${rf_gm} ${fod_gm} ${rf_csf} ${fod_csf} -mask ${dwi_mask} -nthreads ${threads} 
fi
mtnormalise ${fod_wm} ${fod_wmN} -mask ${dwi_mask} -nthreads ${threads} 


echo -e "\n## Subcortex processing"
T1Dir="${strucDir}/wb_adjust/T1w"

# Prepare subcortex
fslmaths ${T1Dir}/T1 ${tmpDir}/T1
fslmaths ${T1Dir}/T1w_restore_brain ${tmpDir}/T1w_restore_brain
mri_synthseg --i ${tmpDir}/T1w_restore_brain.nii.gz --o ${tmpDir}/T1w_restore_brain_seg.nii.gz --robust --cpu --threads ${threads}
python ${FuNP}/functions/extract_subcortex_SynthSeg.py ${tmpDir}/T1w_restore_brain_seg.nii.gz ${tmpDir}/T1w_subcortical.nii.gz

# Registration to dti space
antsRegistrationSyN.sh -d 3  -m ${tmpDir}/T1w_restore_brain.nii.gz -f ${tmpDir}/dwi_b0_brain.nii.gz -o ${tmpDir}/T1w2b0 -t r
rm -rf ${tmpDir}/T1w2b0*Inverse*
mv ${tmpDir}/T1w2b0Warped.nii.gz ${tmpDir}/T1w2b0.nii.gz
mv ${tmpDir}/T1w2b00GenericAffine.mat ${tmpDir}/T1w2b0.mat
mrconvert ${tmpDir}/T1w2b0.nii.gz ${tmpDir}/T1w2b0.mgz
T1dwi=${tmpDir}/T1w2b0.mgz

antsApplyTransforms --default-value 0 -e 3 --input ${tmpDir}/T1w_subcortical.nii.gz -r ${tmpDir}/dwi_b0_brain.nii.gz -o ${tmpDir}/T1w_subcortical2b0.nii.gz -t ${tmpDir}/T1w2b0.mat --interpolation NearestNeighbor
dwi_subc=${tmpDir}/T1w_subcortical2b0.nii.gz


echo -e "\n## Generate a five-tissue-type image for anatomically constrained tractography"
5ttgen fsl ${tmpDir}/T1.nii.gz ${tmpDir}/5TT.mif -nocrop
mrconvert ${tmpDir}/5TT.mif ${tmpDir}/5TT.nii.gz

antsApplyTransforms --default-value 0 -e 3 --input ${tmpDir}/5TT.nii.gz -r ${tmpDir}/dwi_b0_brain.nii.gz -o ${tmpDir}/5TT2b0.nii.gz -t ${tmpDir}/T1w2b0.mat
mrconvert ${tmpDir}/5TT2b0.nii.gz ${tmpDir}/5TT2b0.mif


echo -e "\n## Generate probabilistic tracts"
tckgen -nthreads ${threads} ${fod_wmN} ${tmpDir}/iFOD2-40M_tractography.tck -act ${tmpDir}/5TT2b0.mif -crop_at_gmwmi -backtrack -seed_dynamic ${fod_wmN} -algorithm iFOD2 -step 0.5 -angle 22.5 -cutoff 0.06 -maxlength 400 -minlength 10 -select 40M
if [[ ! -f "${tmpDir}/iFOD2-40M_tractography.tck" ]]; then 
    Error "tckgen failed, check the logs"
    exit;
fi

tcksift2 -nthreads ${threads} ${tmpDir}/iFOD2-40M_tractography.tck ${fod_wmN} ${tmpDir}/SIFT2_40M.txt
tckmap -vox 1,1,1 -dec -nthreads ${threads} ${tmpDir}/iFOD2-40M_tractography.tck ${tmpDir}/iFOD2-40M_dti.mif


echo -e "\n## Prepare atlases"
# Atlas from surface to dwi volume
fsDir="${strucDir}/fs_initial"
MNIDir="${strucDir}/wb_adjust/MNINonLinear"
fs_parcDir="${strucDir}/parcellations"
if [[ ! -d "${fs_parcDir}" ]]; then
    mkdir -m 777 -p $fs_parcDir
fi
dwi_parcDir="${tmpDir}/parcellations"
if [[ ! -d "${dwi_parcDir}" ]]; then
    mkdir -m 777 -p $dwi_parcDir
fi

export SUBJECTS_DIR="${strucDir}"

# Register T1 in fs to T1 in dwi
T1fs="${fsDir}/mri/brain.mgz" 
T1dwi="${tmpDir}/T1w2b0.mgz"
mat_fsnative_affine="${dwi_parcDir}/from-fsnative_to_dwi_t1w_"
T1_fsnative_affine=${mat_fsnative_affine}0GenericAffine.mat
antsRegistrationSyN.sh -d 3 -f "$T1dwi" -m "$T1fs" -o "$mat_fsnative_affine" -t r -p d

# Create parcellation volumes
cp -r -L ${FREESURFER_HOME}/subjects/fsaverage5 ${strucDir}

cd ${FuNP}/parcellations
atlas_parc=($(ls lh.*annot))
for parc in "${atlas_parc[@]}"; do
    parc_annot="${parc/lh./}"
    parc_str=$(echo "${parc_annot}" | awk -F '_mics' '{print $1}')

    for hemi in lh rh; do
        mri_surf2surf --hemi "$hemi" \
           		  --srcsubject fsaverage5 \
       	    	  --trgsubject fs_initial \
       		      --sval-annot "${hemi}.${parc_annot}" \
       		      --tval "${fsDir}/label/${hemi}.${parc_annot}"
    done
    fs_mgz="${fs_parcDir}/${parc_str}.mgz"
    fs_tmp="${fs_parcDir}/${parc_str}_in_T1.mgz"
    fs_nii="${fs_parcDir}/${parc_str}.nii.gz"         # labels in fsnative tmp dir
    labels_dwi="${dwi_parcDir}/${parc_str}.nii.gz"    # lables in dwi space

    # Register the annot surface parcelation to the T1-freesurfer volume
    mri_aparc2aseg --s fs_initial --o "$fs_mgz" --annot "${parc_annot/.annot/}" --new-ribbon
    mri_label2vol --seg "$fs_mgz" --temp "$T1fs" --o "$fs_tmp" --regheader "${fsDir}/mri/aseg.mgz"
    mrconvert "$fs_tmp" "$fs_nii" -force      # mgz to nifti_gz
    fslreorient2std "$fs_nii" "$fs_nii"       # reorient to standard
    fslmaths "$fs_nii" -thr 1000 "$fs_nii"    # threshold the labels

    # Register parcellation to T1 in dwi space
    antsApplyTransforms -d 3 -i "$fs_nii" -r "$T1dwi" -n GenericLabel -t "$T1_fsnative_affine" -o "$labels_dwi" -v -u int
done


echo -e "\n## Build connectomes"
connDir_tmp="${tmpDir}/connectomes_tmp"
if [[ ! -d "${connDir_tmp}" ]]; then
    mkdir -m 777 -p $connDir_tmp
fi
connDir="${tmpDir}/connectomes"
if [[ ! -d "${connDir}" ]]; then
    mkdir -m 777 -p $connDir
fi
for parc in "${atlas_parc[@]}"; do
    parc_annot="${parc/lh./}"
    parc_str=$(echo "${parc_annot}" | awk -F '_mics' '{print $1}')

    echo -e "    - ${parc_str}"

    # ctx
    echo -e "      - ctx"
    cp ${dwi_parcDir}/${parc_str}.nii.gz ${dwi_parcDir}/${parc_str}-cor_dwi.nii.gz
    dwi_cortex="${dwi_parcDir}/${parc_str}-cor_dwi.nii.gz"

    # remove the medial wall
    fslmaths ${dwi_cortex} -thr 1000 -uthr 1000 -binv -mul ${dwi_cortex} ${dwi_cortex}
    fslmaths ${dwi_cortex} -thr 2000 -uthr 2000 -binv -mul ${dwi_cortex} ${dwi_cortex}

    # build connectomes & edge lengths
    tck2connectome -nthreads ${threads} ${tmpDir}/iFOD2-40M_tractography.tck ${dwi_cortex} ${connDir_tmp}/iFOD2-40M_SIFT2_cor-connectome_${parc_str}.txt -tck_weights_in ${tmpDir}/SIFT2_40M.txt -quiet -force
    tck2connectome -nthreads ${threads} ${tmpDir}/iFOD2-40M_tractography.tck ${dwi_cortex} ${connDir_tmp}/iFOD2-40M_SIFT2_cor-edgeLengths_${parc_str}.txt -tck_weights_in ${tmpDir}/SIFT2_40M.txt -scale_length -stat_edge mean -quiet -force


    # sctx
    echo -e "      - sctx"
    dwi_cortexSub="${dwi_parcDir}/${parc_str}-sub_dwi.nii.gz"

    # added the subcortical parcellation
    fslmaths ${dwi_cortex} -binv -mul ${dwi_subc} -add ${dwi_cortex} ${dwi_cortexSub} -odt int

    # build connectomes & edge lengths
    tck2connectome -nthreads ${threads} ${tmpDir}/iFOD2-40M_tractography.tck ${dwi_cortexSub} ${connDir_tmp}/iFOD2-40M_SIFT2_sub-cor-connectome_${parc_str}.txt -tck_weights_in ${tmpDir}/SIFT2_40M.txt -quiet -force
    tck2connectome -nthreads ${threads} ${tmpDir}/iFOD2-40M_tractography.tck ${dwi_cortexSub} ${connDir_tmp}/iFOD2-40M_SIFT2_sub-cor-edgeLengths_${parc_str}.txt -tck_weights_in ${tmpDir}/SIFT2_40M.txt -scale_length -stat_edge mean -quiet -force


    # Store data (sctx + ctx)
    python ${FuNP}/functions/dwi_SC.py ${dwi_cortex} ${connDir_tmp}/iFOD2-40M_SIFT2_cor-connectome_${parc_str}.txt ${connDir}
    python ${FuNP}/functions/dwi_SC.py ${dwi_cortex} ${connDir_tmp}/iFOD2-40M_SIFT2_cor-edgeLengths_${parc_str}.txt ${connDir}
    python ${FuNP}/functions/dwi_SC.py ${dwi_cortexSub} ${connDir_tmp}/iFOD2-40M_SIFT2_sub-cor-connectome_${parc_str}.txt ${connDir}
    python ${FuNP}/functions/dwi_SC.py ${dwi_cortexSub} ${connDir_tmp}/iFOD2-40M_SIFT2_sub-cor-edgeLengths_${parc_str}.txt ${connDir}
done


echo -e "\n## Organize intermediate files"
# dwi
rm -rf ${tmpDir}/b0_meanMainPhase.nii.gz
rm -rf ${tmpDir}/dwi_b0.*
rm -rf ${tmpDir}/dwi_b0_brain.nii.gz
rm -rf ${tmpDir}/dwi_dns*
rm -rf ${tmpDir}/dwi_mask.nii.gz
mv ${tmpDir}/b0_meanMainPhase.mif ${tmpDir}/dwi_b0.mif
# 5TT
rm -rf ${tmpDir}/5TT*.mif
# response & fod
rm -rf ${tmpDir}/response*.mif
rm -rf ${tmpDir}/*_fod.mif
rm -rf ${tmpDir}/*Norm.mif
# tractography
rm -rf ${tmpDir}/iFOD2*.tck
rm -rf ${tmpDir}/SIFT2*
rm -rf ${tmpDir}/connectomes_tmp


echo -e "\n## Move data to the output directory"
cp -r ${tmpDir}/* ${outDir}
rm -rf ${tmpDir}


echo -e "\n### dwi processing finished ###"

