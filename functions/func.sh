#!/bin/bash

source "${FuNP}/functions/utilities.sh"

set -e

Usage() {
    cat <<EOF
Usage: func.sh <func_main> <wbDir> <fix_train> <slice_order> <func_rev> <readout> <outDir> <threads> <procDir>
  
  <func_main>   fMRI main phase data (NIFTI) with full directory
  <wbDir>       wb_adjust folder (typically, ~/struc/wb_adjust)
  <fix_train>   Training files (.RData) for ICA-FIX
                Standard: TR=3s, 3.5mm^3
                HCP_hp2000: TR=0.7s, 2mm^3, no spatial smoothing, 2000s HPF
                UKBiobank: TR=0.735s, 2.4mm^3, no spatial smoothing, 100s HPF
  <outDir>      Output directory
  <func_rev>    fMRI reverse phase data (NIFTI) with full directory
  <slice_order> Slice order file for slice timing correction (each slice has slicing order, default: interleaved)
  <threads>     Number of threads (default: 5)
  <procDir>     Processing directory (default: /tmp)

EOF
    exit 1
}

############################# Settings #############################
func_main="$1"
wbDir="$2"
fix_train="$3"
slice_order="$4"
func_rev="$5"
readout="$6"
outDir="$7"
threads="$8"
procDir="$9"

### Check the inputs ###
input=($func_main $wbDir $outDir)
if [ "${#input[@]}" -lt 3 ]; then
    Error "A processing flag is missing:
             -func_main
             -wbDir
             -out"
    exit 1;
fi
####################################################################

### Prepare the processing directory ###
tmpName=`tr -dc A-Za-z0-9 </dev/urandom | head -c 5`
tmpDir=${procDir}/${tmpName}
if [ ! -d ${tmpDir} ]; then mkdir -m 777 -p ${tmpDir}; fi


echo -e "\n### Start volume processing ###"
volDir="${tmpDir}/volume"
if [[ ! -d "${volDir}" ]]; then
    mkdir -m 777 -p $volDir
fi


echo -e "\n## Prepare data"
fslmaths ${func_main} ${volDir}/orig -odt float
Nvol=`fslinfo ${volDir}/orig | grep -w 'dim4' | cut -f 3`
TR=`fslinfo ${volDir}/orig | grep -w 'pixdim4' | cut -f 3`


echo -e "\n## De-oblique"
3drefit -deoblique ${volDir}/orig.nii.gz


echo -e "\n## Re-orient to RPI"
3dresample -orient RPI -prefix ${volDir}/RPI.nii.gz -inset ${volDir}/orig.nii.gz


echo -e "\n## Delete first N volumes (10s)"
delVol=$(expr "10 / $TR" | bc)
FinVol=$(expr $Nvol - $delVol)
fslroi ${volDir}/RPI ${volDir}/delNvol ${delVol} ${FinVol}


echo -e "\n## Slice timing correction (if TR>=2s)"
TR_thr=2
if [ $(echo "scale=2;$TR > $TR_thr" | bc) == 1 ]; then
    if [ $slice_order != None ]; then
        slicetimer -i ${volDir}/delNvol --out=${volDir}/STC -r ${TR} --ocustom=${slice_order}
    else
        slicetimer -i ${volDir}/delNvol --out=${volDir}/STC -r ${TR} --odd
    fi
    func_out="${volDir}/STC"
else
    echo -e "    - TR<2s: No need to perform slice timing correction (skip)"
    func_out="${volDir}/delNvol"
fi


echo -e "\n## Distortion correction"
if [ $func_rev != None ]; then
    Nvol_rev=`fslinfo ${func_rev} | grep -w 'dim4' | cut -f 3`
    python ${FuNP}/functions/acqparams.py ${Nvol_rev} ${readout} ${volDir}

    # Make a data for topup
    fslroi ${func_out} ${volDir}/temp_dc_orig 0 ${Nvol_rev}
    fslroi ${func_rev} ${volDir}/temp_dc_rev 0 ${Nvol_rev}
    fslmerge -t ${volDir}/dc_origrev ${volDir}/temp_dc_orig ${volDir}/temp_dc_rev
    rm -rf ${volDir}/temp_dc*

    # Perform topup
    topup --imain=${volDir}/dc_origrev --datain=${volDir}/acqparams.txt --config=b02b0.cnf --out=${volDir}/topup_res --fout=${volDir}/topup_field --iout=${volDir}/topup_unwarped
    applytopup --imain=${func_out} --inindex=1 --datain=${volDir}/acqparams.txt --topup=${volDir}/topup_res --out=${volDir}/dc --method=jac

    func_out="${volDir}/dc"
else
    echo -e "    - No reverse phase data is provided. Skip distortion correciton."
fi


echo -e "\n## Motion correction"
Nvol=`fslinfo ${func_out} | grep -w 'dim4' | cut -f 3`
#SBRef=$(expr "$Nvol / 2" | bc)
SBRef=0
# Make SBRef image
fslroi ${func_out} ${volDir}/SBRef ${SBRef} 1
# motion correction
mcflirt -in ${func_out} -out ${volDir}/MC -mats -plots -refvol ${SBRef}
cp ${volDir}/MC.par ${volDir}/MC.1D # *.par: 1~3: translation (mm_x, mm_y, mm_z), 4~6: rotation (deg_x, deg_y, deg_z)
rm -rf ${volDir}/MC.mat
fsl_motion_outliers -i ${func_out} -o ${volDir}/FD_cfd -s ${volDir}/FD.1D -p ${volDir}/FD --fd 
rm -rf ${volDir}/FD_cfd

echo -e "\n## Brain extraction"
# Mean image
fslmaths ${volDir}/MC -Tmean ${volDir}/Mean

# Generate binary brain mask
bet2 ${volDir}/Mean ${volDir}/Mean -f 0.3 -n -m    # -m generate binary brain mask, -n don't generate the default brain image output, -f fractional intensity threshold (0->1); default=0.5; smaller values give larger brain outline estimates
fslmaths ${volDir}/MC -mas ${volDir}/Mean_mask ${volDir}/BET

thr_val=`fslstats ${volDir}/BET -p 2 -p 98 | cut -d ' ' -f 2`
thr_val=$(expr "scale=2; $thr_val / 10" | bc)
fslmaths ${volDir}/BET -thr ${thr_val} -Tmin -bin ${volDir}/Mean_mask -odt char
fslstats ${volDir}/MC -k ${volDir}/Mean_mask -p 50
fslmaths ${volDir}/Mean_mask -dilF ${volDir}/BET
fslmaths ${volDir}/MC -mas ${volDir}/BET ${volDir}/BETthr


echo -e "\n## Intensity normalization"
fslmaths ${volDir}/BETthr -ing 10000 ${volDir}/Filtered


echo -e "\n## Registration"
# Make Mean image
fslmaths ${volDir}/Filtered -Tmean ${volDir}/Mean4reg
fslmaths ${wbDir}/MNINonLinear/T1w_restore_brain ${volDir}/highres
fslmaths ${wbDir}/MNINonLinear/MNI152_T1_2mm_brain ${volDir}/standard

echo -e "    - Initial registration"
antsRegistrationSyN.sh -d 3  -m ${volDir}/Mean4reg.nii.gz -f ${volDir}/highres.nii.gz -o ${volDir}/Func2HR -t r
rm -rf ${volDir}/Func2HR*Inverse*
mv ${volDir}/Func2HRWarped.nii.gz ${volDir}/Func2HR.nii.gz
mv ${volDir}/Func2HR0GenericAffine.mat ${volDir}/Func2HR.mat

flirt -ref ${volDir}/highres -in ${volDir}/Mean4reg -omat ${volDir}/fsl_Func2HR.mat -cost mutualinfo -dof 6 -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -interp trilinear
${FuNP}/functions/convert_mat_decimal.sh ${volDir}/fsl_Func2HR.mat
mv -f ${volDir}/fsl_Func2HR.mat_conv ${volDir}/fsl_Func2HR.mat
convert_xfm -inverse -omat ${volDir}/fsl_HR2Func.mat ${volDir}/fsl_Func2HR.mat
${FuNP}/functions/convert_mat_decimal.sh ${volDir}/fsl_HR2Func.mat
mv -f ${volDir}/fsl_HR2Func.mat_conv ${volDir}/fsl_HR2Func.mat

echo -e "    - ICA-FIX"
if [[ ! -d "${volDir}/ICAFIX" ]]; then mkdir -m 777 -p $volDir/ICAFIX; fi
if [[ ! -d "${volDir}/ICAFIX/mc" ]]; then mkdir -m 777 -p $volDir/ICAFIX/mc; fi
if [[ ! -d "${volDir}/ICAFIX/reg" ]]; then mkdir -m 777 -p $volDir/ICAFIX/reg; fi

fslmaths ${volDir}/Filtered ${volDir}/ICAFIX/filtered_func_data
cp ${volDir}/MC.par ${volDir}/ICAFIX/mc/prefiltered_func_data_mcf.par
fslmaths ${volDir}/Mean4reg ${volDir}/ICAFIX/mean_func
fslmaths ${volDir}/ICAFIX/mean_func -bin ${volDir}/ICAFIX/mask
fslmaths ${volDir}/Mean4reg ${volDir}/ICAFIX/reg/example_func
fslmaths ${volDir}/highres ${volDir}/ICAFIX/reg/highres
cp ${volDir}/fsl_HR2Func.mat ${volDir}/ICAFIX/reg/highres2example_func.mat

melodic -i ${volDir}/ICAFIX/filtered_func_data.nii.gz -o ${volDir}/ICAFIX/filtered_func_data.ica -v --nobet --bgthreshold=3 --tr=${TR} --report -d 0 --mmthresh=0.5 --Ostats
fix -f ${volDir}/ICAFIX
fix -c ${volDir}/ICAFIX /usr/local/fix/training_files/${fix_train}.RData 20
fix -a ${volDir}/ICAFIX/fix4melview_${fix_train}_thr20.txt -m -h 0 -A   # bad component, motion condounds aggressive cleanup + linear detrending
fslmaths ${volDir}/ICAFIX/filtered_func_data_clean ${volDir}/Filtered_clean

echo -e "    - Final registration"
antsRegistrationSyN.sh -d 3 -m ${volDir}/highres.nii.gz -f ${volDir}/standard.nii.gz -o ${volDir}/HR2STD -t a
rm -rf ${volDir}/HR2STD*Inverse*
mv ${volDir}/HR2STDWarped.nii.gz ${volDir}/HR2STD.nii.gz
mv ${volDir}/HR2STD0GenericAffine.mat ${volDir}/HR2STD.mat
antsApplyTransforms --default-value 0 -e 3 --input ${volDir}/Mean4reg.nii.gz -r ${volDir}/standard.nii.gz -o ${volDir}/Func2STD.nii.gz -t ${volDir}/HR2STD.mat -t ${volDir}/Func2HR.mat --interpolation BSpline
antsApplyTransforms --default-value 0 -e 3 --input ${volDir}/Filtered_clean.nii.gz -r ${volDir}/standard.nii.gz -o ${volDir}/Func2STD_4D.nii.gz -t ${volDir}/HR2STD.mat -t ${volDir}/Func2HR.mat --interpolation BSpline

volOut=${volDir}/func_clean_vol
fslmaths ${volDir}/Func2STD_4D ${volOut}
fslroi ${volOut} ${volDir}/func_clean_vol_SBRef ${SBRef} 1


echo -e "\n## Subcortex processing"
run_first_all -i ${volDir}/highres -o ${volDir}/T1w -b
if [[ ! -f "${volDir}/T1w_all_fast_firstseg.nii.gz" ]]; then 
    Error "run_first_all failed, check the logs"
    exit;
else
    rm -rf ${volDir}/T1w.logs
    rm -rf ${volDir}/T1w.com*
    rm -rf ${volDir}/T1w_all_fast_origsegs.nii.gz
    rm -rf ${volDir}/T1w*.bvars
    rm -rf ${volDir}/T1w*.vtk
fi
mv ${volDir}/T1w_all_fast_firstseg.nii.gz ${volDir}/T1w_sctx.nii.gz
sctx="${volDir}/T1w_sctx.nii.gz"

echo -e "\n### Volume processing finished ###"




echo -e "\n### Start surface processing ###"
surfDir="${tmpDir}/surface"
if [[ ! -d "${surfDir}" ]]; then
    mkdir -m 777 -p $surfDir
fi

LowResMesh="32"
FWHM=5
RegName="reg.reg_LR"
ribbonDir=${surfDir}/RibbonVolumeToSurfaceMapping 
wb_LowResDir=${wbDir}/MNINonLinear/fsaverage_LR${LowResMesh}k
wb_NativeDir=${wbDir}/MNINonLinear/Native

echo -e "\n## Ribbon Volume To Surface Mapping"
# Make fMRI Ribbon
# Noisy Voxel Outlier Exclusion
# Ribbon-based Volume to Surface mapping and resampling to standard surface

if [[ ! -d "${surfDir}/RibbonVolumeToSurfaceMapping" ]]; then
    mkdir -m 777 -p $surfDir/RibbonVolumeToSurfaceMapping
fi

for Hemisphere in L R ; do
    if [ "$Hemisphere" == "L" ]; then
        hemi1="lh"
        hemi2="L"
        hemi3="LEFT"
    elif [ "$Hemisphere" == "R" ]; then
        hemi1="rh"
        hemi2="R"
        hemi3="RIGHT"
    fi
    echo -e "    - ${hemi3} hemisphere"

    OMP_NUM_THREADS=${threads} wb_command -create-signed-distance-volume ${wb_NativeDir}/${hemi2}.white.native.surf.gii ${volOut}_SBRef.nii.gz ${ribbonDir}/${hemi2}.white.native.nii.gz
    OMP_NUM_THREADS=${threads} wb_command -create-signed-distance-volume ${wb_NativeDir}/${hemi2}.pial.native.surf.gii ${volOut}_SBRef.nii.gz ${ribbonDir}/${hemi2}.pial.native.nii.gz
    fslmaths ${ribbonDir}/${hemi2}.white.native -thr 0 -bin -mul 255 ${ribbonDir}/${hemi2}.white_thr0.native
    fslmaths ${ribbonDir}/${hemi2}.white_thr0.native -bin ${ribbonDir}/${hemi2}.white_thr0.native
    fslmaths ${ribbonDir}/${hemi2}.pial.native -uthr 0 -abs -bin -mul 255 ${ribbonDir}/${hemi2}.pial_uthr0.native
    fslmaths ${ribbonDir}/${hemi2}.pial_uthr0.native -bin ${ribbonDir}/${hemi2}.pial_uthr0.native
    fslmaths ${ribbonDir}/${hemi2}.pial_uthr0.native -mas ${ribbonDir}/${hemi2}.white_thr0.native -mul 255 ${ribbonDir}/${hemi2}.ribbon
    fslmaths ${ribbonDir}/${hemi2}.ribbon -bin -mul 1 ${ribbonDir}/${hemi2}.ribbon
    rm -rf ${ribbonDir}/${hemi2}.white.native.nii.gz ${ribbonDir}/${hemi2}.white_thr0.native.nii.gz ${ribbonDir}/${hemi2}.pial.native.nii.gz ${ribbonDir}/${hemi2}.pial_uthr0.native.nii.gz
done

fslmaths ${ribbonDir}/L.ribbon -add ${ribbonDir}/R.ribbon ${ribbonDir}/ribbon_only
rm -rf ${ribbonDir}/L.ribbon.nii.gz ${ribbonDir}/R.ribbon.nii.gz

fslmaths ${volOut} -Tmean ${ribbonDir}/mean -odt float
fslmaths ${volOut} -Tstd ${ribbonDir}/std -odt float

fslmaths ${ribbonDir}/std -div ${ribbonDir}/mean ${ribbonDir}/cov
fslmaths ${ribbonDir}/cov -mas ${ribbonDir}/ribbon_only ${ribbonDir}/cov_ribbon
fslmaths ${ribbonDir}/cov_ribbon -div `fslstats ${ribbonDir}/cov_ribbon -M` ${ribbonDir}/cov_ribbon_norm
fslmaths ${ribbonDir}/cov_ribbon_norm -bin -s 5 ${ribbonDir}/SmoothNorm
fslmaths ${ribbonDir}/cov_ribbon_norm -s 5 -div ${ribbonDir}/SmoothNorm -dilD ${ribbonDir}/cov_ribbon_norm_s5
fslmaths ${ribbonDir}/cov -div `fslstats ${ribbonDir}/cov_ribbon -M` -div ${ribbonDir}/cov_ribbon_norm_s5 ${ribbonDir}/cov_norm_modulate
fslmaths ${ribbonDir}/cov_norm_modulate -mas ${ribbonDir}/ribbon_only ${ribbonDir}/cov_norm_modulate_ribbon

STD=`fslstats ${ribbonDir}/cov_norm_modulate_ribbon -S`
MEAN=`fslstats ${ribbonDir}/cov_norm_modulate_ribbon -M`
Lower=`echo "$MEAN - ($STD * 0.5)" | bc -l`
Upper=`echo "$MEAN + ($STD * 0.5)" | bc -l`

fslmaths ${ribbonDir}/mean -bin ${ribbonDir}/mask
fslmaths ${ribbonDir}/cov_norm_modulate -thr $Upper -bin -sub ${ribbonDir}/mask -mul -1 ${ribbonDir}/goodvoxels

for Hemisphere in L R ; do
    if [ "$Hemisphere" == "L" ]; then
        hemi1="lh"
        hemi2="L"
        hemi3="LEFT"
    elif [ "$Hemisphere" == "R" ]; then
        hemi1="rh"
        hemi2="R"
        hemi3="RIGHT"
    fi
    echo -e "    - ${hemi3} hemisphere"
  
    for Map in mean cov ; do
        echo -e "      - $Map"

        OMP_NUM_THREADS=${threads} wb_command -volume-to-surface-mapping ${ribbonDir}/${Map}.nii.gz ${wb_NativeDir}/${hemi2}.midthickness.native.surf.gii ${ribbonDir}/${hemi2}.${Map}.native.func.gii -ribbon-constrained ${wb_NativeDir}/${hemi2}.white.native.surf.gii ${wb_NativeDir}/${hemi2}.pial.native.surf.gii -volume-roi ${ribbonDir}/goodvoxels.nii.gz
        OMP_NUM_THREADS=${threads} wb_command -metric-dilate ${ribbonDir}/${hemi2}.${Map}.native.func.gii ${wb_NativeDir}/${hemi2}.midthickness.native.surf.gii 10 ${ribbonDir}/${hemi2}.${Map}.native.func.gii -nearest
        OMP_NUM_THREADS=${threads} wb_command -metric-mask ${ribbonDir}/${hemi2}.${Map}.native.func.gii ${wb_NativeDir}/${hemi2}.roi.native.shape.gii ${ribbonDir}/${hemi2}.${Map}.native.func.gii
        OMP_NUM_THREADS=${threads} wb_command -volume-to-surface-mapping ${ribbonDir}/${Map}.nii.gz ${wb_NativeDir}/${hemi2}.midthickness.native.surf.gii ${ribbonDir}/${hemi2}.${Map}_all.native.func.gii -ribbon-constrained ${wb_NativeDir}/${hemi2}.white.native.surf.gii ${wb_NativeDir}/${hemi2}.pial.native.surf.gii
        OMP_NUM_THREADS=${threads} wb_command -metric-mask ${ribbonDir}/${hemi2}.${Map}_all.native.func.gii ${wb_NativeDir}/${hemi2}.roi.native.shape.gii ${ribbonDir}/${hemi2}.${Map}_all.native.func.gii
        OMP_NUM_THREADS=${threads} wb_command -metric-resample ${ribbonDir}/${hemi2}.${Map}.native.func.gii ${wb_NativeDir}/${hemi2}.sphere.${RegName}.native.surf.gii ${wb_LowResDir}/${hemi2}.sphere.${LowResMesh}k_fs_LR.surf.gii ADAP_BARY_AREA ${ribbonDir}/${hemi2}.${Map}.${LowResMesh}k_fs_LR.func.gii -area-surfs ${wb_NativeDir}/${hemi2}.midthickness.native.surf.gii ${wb_LowResDir}/${hemi2}.midthickness.${LowResMesh}k_fs_LR.surf.gii -current-roi ${wb_NativeDir}/${hemi2}.roi.native.shape.gii
        OMP_NUM_THREADS=${threads} wb_command -metric-mask ${ribbonDir}/${hemi2}.${Map}.${LowResMesh}k_fs_LR.func.gii ${wb_LowResDir}/${hemi2}.atlasroi.${LowResMesh}k_fs_LR.shape.gii ${ribbonDir}/${hemi2}.${Map}.${LowResMesh}k_fs_LR.func.gii
        OMP_NUM_THREADS=${threads} wb_command -metric-resample ${ribbonDir}/${hemi2}.${Map}_all.native.func.gii ${wb_NativeDir}/${hemi2}.sphere.${RegName}.native.surf.gii ${wb_LowResDir}/${hemi2}.sphere.${LowResMesh}k_fs_LR.surf.gii ADAP_BARY_AREA ${ribbonDir}/${hemi2}.${Map}_all.${LowResMesh}k_fs_LR.func.gii -area-surfs ${wb_NativeDir}/${hemi2}.midthickness.native.surf.gii ${wb_LowResDir}/${hemi2}.midthickness.${LowResMesh}k_fs_LR.surf.gii -current-roi ${wb_NativeDir}/${hemi2}.roi.native.shape.gii
        OMP_NUM_THREADS=${threads} wb_command -metric-mask ${ribbonDir}/${hemi2}.${Map}_all.${LowResMesh}k_fs_LR.func.gii ${wb_LowResDir}/${hemi2}.atlasroi.${LowResMesh}k_fs_LR.shape.gii ${ribbonDir}/${hemi2}.${Map}_all.${LowResMesh}k_fs_LR.func.gii
    done

    echo -e "      - Volume to surface mapping: goodvoxels"
    OMP_NUM_THREADS=${threads} wb_command -volume-to-surface-mapping ${ribbonDir}/goodvoxels.nii.gz ${wb_NativeDir}/${hemi2}.midthickness.native.surf.gii ${ribbonDir}/${hemi2}.goodvoxels.native.func.gii -ribbon-constrained ${wb_NativeDir}/${hemi2}.white.native.surf.gii ${wb_NativeDir}/${hemi2}.pial.native.surf.gii
    OMP_NUM_THREADS=${threads} wb_command -metric-mask ${ribbonDir}/${hemi2}.goodvoxels.native.func.gii ${wb_NativeDir}/${hemi2}.roi.native.shape.gii ${ribbonDir}/${hemi2}.goodvoxels.native.func.gii
    OMP_NUM_THREADS=${threads} wb_command -metric-resample ${ribbonDir}/${hemi2}.goodvoxels.native.func.gii ${wb_NativeDir}/${hemi2}.sphere.${RegName}.native.surf.gii ${wb_LowResDir}/${hemi2}.sphere.${LowResMesh}k_fs_LR.surf.gii ADAP_BARY_AREA ${ribbonDir}/${hemi2}.goodvoxels.${LowResMesh}k_fs_LR.func.gii -area-surfs ${wb_NativeDir}/${hemi2}.midthickness.native.surf.gii ${wb_LowResDir}/${hemi2}.midthickness.${LowResMesh}k_fs_LR.surf.gii -current-roi ${wb_NativeDir}/${hemi2}.roi.native.shape.gii
    OMP_NUM_THREADS=${threads} wb_command -metric-mask ${ribbonDir}/${hemi2}.goodvoxels.${LowResMesh}k_fs_LR.func.gii ${wb_LowResDir}/${hemi2}.atlasroi.${LowResMesh}k_fs_LR.shape.gii ${ribbonDir}/${hemi2}.goodvoxels.${LowResMesh}k_fs_LR.func.gii

    echo -e "      - Volume to surface mapping: volume fMRI"
    OMP_NUM_THREADS=${threads} wb_command -volume-to-surface-mapping ${volOut}.nii.gz ${wb_NativeDir}/${hemi2}.midthickness.native.surf.gii ${surfDir}/${hemi2}.native.func.gii -ribbon-constrained ${wb_NativeDir}/${hemi2}.white.native.surf.gii ${wb_NativeDir}/${hemi2}.pial.native.surf.gii -volume-roi ${ribbonDir}/goodvoxels.nii.gz
    OMP_NUM_THREADS=${threads} wb_command -metric-dilate ${surfDir}/${hemi2}.native.func.gii ${wb_NativeDir}/${hemi2}.midthickness.native.surf.gii 10 ${surfDir}/${hemi2}.native.func.gii -nearest
    OMP_NUM_THREADS=${threads} wb_command -metric-mask  ${surfDir}/${hemi2}.native.func.gii ${wb_NativeDir}/${hemi2}.roi.native.shape.gii  ${surfDir}/${hemi2}.native.func.gii
    OMP_NUM_THREADS=${threads} wb_command -metric-resample ${surfDir}/${hemi2}.native.func.gii ${wb_NativeDir}/${hemi2}.sphere.${RegName}.native.surf.gii ${wb_LowResDir}/${hemi2}.sphere.${LowResMesh}k_fs_LR.surf.gii ADAP_BARY_AREA ${surfDir}/${hemi2}.atlasroi.${LowResMesh}k_fs_LR.func.gii -area-surfs ${wb_NativeDir}/${hemi2}.midthickness.native.surf.gii ${wb_LowResDir}/${hemi2}.midthickness.${LowResMesh}k_fs_LR.surf.gii -current-roi ${wb_NativeDir}/${hemi2}.roi.native.shape.gii
    OMP_NUM_THREADS=${threads} wb_command -metric-mask ${surfDir}/${hemi2}.atlasroi.${LowResMesh}k_fs_LR.func.gii ${wb_LowResDir}/${hemi2}.atlasroi.${LowResMesh}k_fs_LR.shape.gii ${surfDir}/${hemi2}.atlasroi.${LowResMesh}k_fs_LR.func.gii
done


echo -e "\n## Surface Smoothing"
Sigma=`echo "${FWHM} / ( 2 * ( sqrt ( 2 * l ( 2 ) ) ) )" | bc -l`
for Hemisphere in L R ; do
    if [ "$Hemisphere" == "L" ]; then
        hemi1="lh"
        hemi2="L"
        hemi3="LEFT"
    elif [ "$Hemisphere" == "R" ]; then
        hemi1="rh"
        hemi2="R"
        hemi3="RIGHT"
    fi
    echo -e "    - ${hemi3} hemisphere"

    OMP_NUM_THREADS=${threads} wb_command -metric-smoothing ${wb_LowResDir}/${hemi2}.midthickness.${LowResMesh}k_fs_LR.surf.gii ${surfDir}/${hemi2}.atlasroi.${LowResMesh}k_fs_LR.func.gii ${Sigma} ${surfDir}/s${FWHM}.atlasroi.${hemi2}.${LowResMesh}k_fs_LR.func.gii -roi ${wb_LowResDir}/${hemi2}.atlasroi.${LowResMesh}k_fs_LR.shape.gii
done


echo -e "\n## Create Dense TimeSeries for cortices"
echo -e "    - LEFT hemisphere"
OMP_NUM_THREADS=${threads} wb_command -cifti-create-dense-timeseries ${surfDir}/func.L.dtseries.nii -left-metric ${surfDir}/s${FWHM}.atlasroi.L.${LowResMesh}k_fs_LR.func.gii -roi-left ${wb_LowResDir}/L.atlasroi.${LowResMesh}k_fs_LR.shape.gii -timestep ${TR}
OMP_NUM_THREADS=${threads} wb_command -cifti-separate ${surfDir}/func.L.dtseries.nii COLUMN -metric CORTEX_LEFT ${surfDir}/func.L.func.gii

echo -e "    - RIGHT hemisphere"
OMP_NUM_THREADS=${threads} wb_command -cifti-create-dense-timeseries ${surfDir}/func.R.dtseries.nii -right-metric ${surfDir}/s${FWHM}.atlasroi.R.${LowResMesh}k_fs_LR.func.gii -roi-right ${wb_LowResDir}/R.atlasroi.${LowResMesh}k_fs_LR.shape.gii -timestep ${TR}
OMP_NUM_THREADS=${threads} wb_command -cifti-separate ${surfDir}/func.R.dtseries.nii COLUMN -metric CORTEX_RIGHT ${surfDir}/func.R.func.gii

echo -e "\n### Surface processing finished ###"


echo -e "\n## Build connectomes"
connDir="${surfDir}/connectomes"
if [[ ! -d "${connDir}" ]]; then
    mkdir -m 777 -p ${connDir}
fi

parcDir="${FuNP}/parcellations"
atlas_parc=($(ls ${parcDir}/*conte69.csv))
for parc in "${atlas_parc[@]}"; do
    parc_tmp=$(echo "${parc}" | rev | awk -F '/' '{print $1}' | rev )
    parc_str=$(echo "${parc_tmp}" | awk -F '.' '{print $1}' )
    echo -e "    - ${parc_str}"

    python ${FuNP}/functions/func_FC.py ${tmpDir} ${parc} ${sctx} ${connDir}
done


echo -e "\n## Organize intermediate files"
rm -rf ${volDir}/BET*
rm -rf ${volDir}/delNvol.nii.gz
rm -rf ${volDir}/Func2STD_4D.nii.gz
rm -rf ${volDir}/MC.nii.gz
rm -rf ${volDir}/MC.par
rm -rf ${volDir}/Mean*
rm -rf ${volDir}/RPI.nii.gz
rm -rf ${volDir}/SBRef.nii.gz

if [[ ! -d "${volDir}/reg" ]]; then
    mkdir -m 777 -p ${volDir}/reg
fi
mv ${volDir}/*.mat ${volDir}/reg/
mv ${volDir}/Func2* ${volDir}/reg/
mv ${volDir}/HR2* ${volDir}/reg/
mv ${volDir}/highres* ${volDir}/reg/
mv ${volDir}/standard* ${volDir}/reg/


echo -e "\n## Move data to the output directory"
cp -r ${tmpDir}/* ${outDir}
rm -rf ${tmpDir}

echo -e "\n## Finished"

