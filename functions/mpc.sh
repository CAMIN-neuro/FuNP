#!/bin/bash

source "${FuNP}/functions/utilities.sh"

set -e

Usage() {
    cat <<EOF
Usage: mpc.sh <t1> <t2> <strucDir> <outDir> <threads>
  
  <t1>          T1-weighted image (NIFTI) with full directory
  <t2>          T2-weighted image (NIFTI) with full directory
  <strucDir>    Directory of structural processing (typically, ~/struc)
  <outDir>      Output directory
  <threads>     Number of threads (default: 5)

EOF
    exit 1
}

############################# Settings #############################
t1="$1"
t2="$2"
strucDir="$3"
outDir="$4"
threads="$5"

### Check the inputs ###
input=($t1 $t2 $strucDir $outDir)
if [ "${#input[@]}" -lt 4 ]; then
    Error "A processing flag is missing:
             -t1
             -t2
             -strucDir
             -out"
    exit 1;
fi
####################################################################

export OMP_NUM_THREADS=${threads}


echo -e "\n### Start microstructural processing ###"
HighResMesh="164"
LowResMesh="32"
fsDir=${strucDir}/fs_initial
wbDir=${strucDir}/wb_adjust
wbDir_T1w=${wbDir}/T1w
wbDir_T2w=${wbDir}/T2w
if [ ! -d ${wbDir_T2w} ]; then mkdir -m 777 -p ${wbDir_T2w}; fi
wbDir_MNI=${wbDir}/MNINonLinear
SurfaceAtlasDIR=${FuNP}/SurfaceAtlas
FreeSurferLabels=${SurfaceAtlasDIR}/FreeSurferAllLut.txt
templateDir=${FuNP}/template

echo -e "\n## Create ribbon image"
# prepare T1 in template
flirt -applyxfm -init ${wbDir}/MNINonLinear/xfms/T1w2TempLinear.mat -in ${wbDir}/T1w/T1w_restore.nii.gz -ref ${templateDir}/MNI152_T1_2mm -out ${wbDir}/MNINonLinear/T1w_restore.nii.gz -interp trilinear

echo -e "    - T1w space"
for Hemisphere in L R ; do
    if [ $Hemisphere = "L" ] ; then
        GreyRibbonValue=3
        WhiteMaskValue=2
        hemi1="lh"
        hemi2="L"
        hemi3="LEFT"
    elif [ $Hemisphere = "R" ] ; then
        GreyRibbonValue=42
        WhiteMaskValue=41
        hemi1="rh"
        hemi2="R"
        hemi3="RIGHT"
    fi    
    echo -e "      - ${hemi3} hemisphere"

    wb_command -create-signed-distance-volume ${wbDir_T1w}/Native/${hemi2}.white.native.surf.gii ${wbDir_T1w}/T1w_restore.nii.gz ${wbDir_T1w}/Native/${hemi2}.white.native.nii.gz
    wb_command -create-signed-distance-volume ${wbDir_T1w}/Native/${hemi2}.pial.native.surf.gii ${wbDir_T1w}/T1w_restore.nii.gz ${wbDir_T1w}/Native/${hemi2}.pial.native.nii.gz
    fslmaths ${wbDir_T1w}/Native/${hemi2}.white.native.nii.gz -thr 0 -bin -mul 255 ${wbDir_T1w}/Native/${hemi2}.white_thr0.native.nii.gz
    fslmaths ${wbDir_T1w}/Native/${hemi2}.white_thr0.native.nii.gz -bin ${wbDir_T1w}/Native/${hemi2}.white_thr0.native.nii.gz
    fslmaths ${wbDir_T1w}/Native/${hemi2}.pial.native.nii.gz -uthr 0 -abs -bin -mul 255 ${wbDir_T1w}/Native/${hemi2}.pial_uthr0.native.nii.gz
    fslmaths ${wbDir_T1w}/Native/${hemi2}.pial_uthr0.native.nii.gz -bin ${wbDir_T1w}/Native/${hemi2}.pial_uthr0.native.nii.gz
    fslmaths ${wbDir_T1w}/Native/${hemi2}.pial_uthr0.native.nii.gz -mas ${wbDir_T1w}/Native/${hemi2}.white_thr0.native.nii.gz -mul 255 ${wbDir_T1w}/Native/${hemi2}.ribbon.nii.gz
    fslmaths ${wbDir_T1w}/Native/${hemi2}.ribbon.nii.gz -bin -mul $GreyRibbonValue ${wbDir_T1w}/Native/${hemi2}.ribbon.nii.gz
    fslmaths ${wbDir_T1w}/Native/${hemi2}.white.native.nii.gz -uthr 0 -abs -bin -mul 255 ${wbDir_T1w}/Native/${hemi2}.white_uthr0.native.nii.gz
    fslmaths ${wbDir_T1w}/Native/${hemi2}.white_uthr0.native.nii.gz -bin ${wbDir_T1w}/Native/${hemi2}.white_uthr0.native.nii.gz
    fslmaths ${wbDir_T1w}/Native/${hemi2}.white_uthr0.native.nii.gz -mul $WhiteMaskValue ${wbDir_T1w}/Native/${hemi2}.white_mask.native.nii.gz
    fslmaths ${wbDir_T1w}/Native/${hemi2}.ribbon.nii.gz -add ${wbDir_T1w}/Native/${hemi2}.white_mask.native.nii.gz ${wbDir_T1w}/Native/${hemi2}.ribbon.nii.gz
    rm ${wbDir_T1w}/Native/${hemi2}.white.native.nii.gz ${wbDir_T1w}/Native/${hemi2}.white_thr0.native.nii.gz ${wbDir_T1w}/Native/${hemi2}.pial.native.nii.gz ${wbDir_T1w}/Native/${hemi2}.pial_uthr0.native.nii.gz ${wbDir_T1w}/Native/${hemi2}.white_uthr0.native.nii.gz ${wbDir_T1w}/Native/${hemi2}.white_mask.native.nii.gz
done

fslmaths ${wbDir_T1w}/Native/L.ribbon.nii.gz -add ${wbDir_T1w}/Native/R.ribbon.nii.gz ${wbDir_T1w}/ribbon.nii.gz
rm ${wbDir_T1w}/Native/L.ribbon.nii.gz ${wbDir_T1w}/Native/R.ribbon.nii.gz
wb_command -volume-label-import ${wbDir_T1w}/ribbon.nii.gz ${FreeSurferLabels} ${wbDir_T1w}/ribbon.nii.gz -drop-unused-labels


echo -e "    - MNI space"
for Hemisphere in L R ; do
    if [ $Hemisphere = "L" ] ; then
        GreyRibbonValue=3
        WhiteMaskValue=2
        hemi1="lh"
        hemi2="L"
        hemi3="LEFT"
    elif [ $Hemisphere = "R" ] ; then
        GreyRibbonValue=42
        WhiteMaskValue=41
        hemi1="rh"
        hemi2="R"
        hemi3="RIGHT"
    fi    
    echo -e "      - ${hemi3} hemisphere"

    wb_command -create-signed-distance-volume ${wbDir_MNI}/Native/${hemi2}.white.native.surf.gii ${wbDir_MNI}/T1w_restore.nii.gz ${wbDir_MNI}/Native/${hemi2}.white.native.nii.gz
    wb_command -create-signed-distance-volume ${wbDir_MNI}/Native/${hemi2}.pial.native.surf.gii ${wbDir_MNI}/T1w_restore.nii.gz ${wbDir_MNI}/Native/${hemi2}.pial.native.nii.gz
    fslmaths ${wbDir_MNI}/Native/${hemi2}.white.native.nii.gz -thr 0 -bin -mul 255 ${wbDir_MNI}/Native/${hemi2}.white_thr0.native.nii.gz
    fslmaths ${wbDir_MNI}/Native/${hemi2}.white_thr0.native.nii.gz -bin ${wbDir_MNI}/Native/${hemi2}.white_thr0.native.nii.gz
    fslmaths ${wbDir_MNI}/Native/${hemi2}.pial.native.nii.gz -uthr 0 -abs -bin -mul 255 ${wbDir_MNI}/Native/${hemi2}.pial_uthr0.native.nii.gz
    fslmaths ${wbDir_MNI}/Native/${hemi2}.pial_uthr0.native.nii.gz -bin ${wbDir_MNI}/Native/${hemi2}.pial_uthr0.native.nii.gz
    fslmaths ${wbDir_MNI}/Native/${hemi2}.pial_uthr0.native.nii.gz -mas ${wbDir_MNI}/Native/${hemi2}.white_thr0.native.nii.gz -mul 255 ${wbDir_MNI}/Native/${hemi2}.ribbon.nii.gz
    fslmaths ${wbDir_MNI}/Native/${hemi2}.ribbon.nii.gz -bin -mul $GreyRibbonValue ${wbDir_MNI}/Native/${hemi2}.ribbon.nii.gz
    fslmaths ${wbDir_MNI}/Native/${hemi2}.white.native.nii.gz -uthr 0 -abs -bin -mul 255 ${wbDir_MNI}/Native/${hemi2}.white_uthr0.native.nii.gz
    fslmaths ${wbDir_MNI}/Native/${hemi2}.white_uthr0.native.nii.gz -bin ${wbDir_MNI}/Native/${hemi2}.white_uthr0.native.nii.gz
    fslmaths ${wbDir_MNI}/Native/${hemi2}.white_uthr0.native.nii.gz -mul $WhiteMaskValue ${wbDir_MNI}/Native/${hemi2}.white_mask.native.nii.gz
    fslmaths ${wbDir_MNI}/Native/${hemi2}.ribbon.nii.gz -add ${wbDir_MNI}/Native/${hemi2}.white_mask.native.nii.gz ${wbDir_MNI}/Native/${hemi2}.ribbon.nii.gz
    rm ${wbDir_MNI}/Native/${hemi2}.white.native.nii.gz ${wbDir_MNI}/Native/${hemi2}.white_thr0.native.nii.gz ${wbDir_MNI}/Native/${hemi2}.pial.native.nii.gz ${wbDir_MNI}/Native/${hemi2}.pial_uthr0.native.nii.gz ${wbDir_MNI}/Native/${hemi2}.white_uthr0.native.nii.gz ${wbDir_MNI}/Native/${hemi2}.white_mask.native.nii.gz
done

fslmaths ${wbDir_MNI}/Native/L.ribbon.nii.gz -add ${wbDir_MNI}/Native/R.ribbon.nii.gz ${wbDir_MNI}/ribbon.nii.gz
rm ${wbDir_MNI}/Native/L.ribbon.nii.gz ${wbDir_MNI}/Native/R.ribbon.nii.gz
wb_command -volume-label-import ${wbDir_MNI}/ribbon.nii.gz "$FreeSurferLabels" ${wbDir_MNI}/ribbon.nii.gz -drop-unused-labels



MyelinMappingFWHM=5
SurfaceSmoothingFWHM=4
MyelinMappingSigma=`echo "$MyelinMappingFWHM / ( 2 * ( sqrt ( 2 * l ( 2 ) ) ) )" | bc -l`
SurfaceSmoothingSigma=`echo "$SurfaceSmoothingFWHM / ( 2 * ( sqrt ( 2 * l ( 2 ) ) ) )" | bc -l`
LowResMeshes=`echo ${LowResMesh} | sed 's/@/ /g'`
CorrectionSigma=$(echo "sqrt(200)" | bc -l)

echo -e "\n## T2 bias field correction"
fslmaths ${t2} ${wbDir_T2w}/orig_t2
N4BiasFieldCorrection -d 3 -i ${wbDir_T2w}/orig_t2.nii.gz -r -o ${wbDir_T2w}/T2_restore.nii.gz -v

echo -e "\n## T2 to T1 registration"
flirt -in ${wbDir_T2w}/T2_restore -ref ${wbDir_T1w}/T1w_restore -out ${wbDir_T1w}/T2w_restore -dof 6 -interp trilinear

echo -e "\n## Create T1w/T2w maps"
wb_command -volume-math "clamp((T1w / T2w), 0, 100)" ${wbDir_T1w}/T1wDividedByT2w.nii.gz -var T1w ${wbDir_T1w}/T1w_restore.nii.gz -var T2w ${wbDir_T1w}/T2w_restore.nii.gz -fixnan 0
wb_command -volume-palette ${wbDir_T1w}/T1wDividedByT2w.nii.gz MODE_AUTO_SCALE_PERCENTAGE -pos-percent 4 96 -interpolate true -palette-name videen_style -disp-pos true -disp-neg false -disp-zero false
wb_command -add-to-spec-file ${wbDir_T1w}/Native/native.wb.spec INVALID ${wbDir_T1w}/T1wDividedByT2w.nii.gz
wb_command -volume-math "(T1w / T2w) * (((ribbon > (3 - 0.01)) * (ribbon < (3 + 0.01))) + ((ribbon > (42 - 0.01)) * (ribbon < (42 + 0.01))))" ${wbDir_T1w}/T1wDividedByT2w_ribbon.nii.gz -var T1w ${wbDir_T1w}/T1w_restore.nii.gz -var T2w ${wbDir_T1w}/T2w_restore.nii.gz -var ribbon ${wbDir_T1w}/ribbon.nii.gz
wb_command -volume-palette ${wbDir_T1w}/T1wDividedByT2w_ribbon.nii.gz MODE_AUTO_SCALE_PERCENTAGE -pos-percent 4 96 -interpolate true -palette-name videen_style -disp-pos true -disp-neg false -disp-zero false
wb_command -add-to-spec-file ${wbDir_T1w}/Native/native.wb.spec INVALID ${wbDir_T1w}/T1wDividedByT2w_ribbon.nii.gz

MapListFunc="corrThickness@shape MyelinMap@func SmoothedMyelinMap@func"
for Hemisphere in L R ; do
    if [ $Hemisphere = "L" ] ; then
        ribbon=3
        hemi1="lh"
        hemi2="L"
        hemi3="LEFT"
    elif [ $Hemisphere = "R" ] ; then
        ribbon=42
        hemi1="rh"
        hemi2="R"
        hemi3="RIGHT"
    fi
    echo -e "    - ${hemi3} hemisphere"

    RegSphere="${wbDir_MNI}/Native/${hemi2}.sphere.reg.reg_LR.native.surf.gii"

    wb_command -metric-regression ${wbDir_MNI}/Native/${hemi2}.thickness.native.shape.gii ${wbDir_MNI}/Native/${hemi2}.corrThickness.native.shape.gii -roi ${wbDir_MNI}/Native/${hemi2}.roi.native.shape.gii -remove ${wbDir_MNI}/Native/${hemi2}.curvature.native.shape.gii

    #Reduce memory usage by smoothing on downsampled mesh
    LowResMesh=`echo ${LowResMeshes} | cut -d " " -f 1`  

    wb_command -volume-math "(ribbon > ($ribbon - 0.01)) * (ribbon < ($ribbon + 0.01))" ${wbDir_T1w}/temp_ribbon.nii.gz -var ribbon ${wbDir_T1w}/ribbon.nii.gz
    wb_command -volume-to-surface-mapping ${wbDir_T1w}/T1wDividedByT2w.nii.gz ${wbDir_T1w}/Native/${hemi2}.midthickness.native.surf.gii ${wbDir_MNI}/Native/${hemi2}.MyelinMap.native.func.gii -myelin-style ${wbDir_T1w}/temp_ribbon.nii.gz ${wbDir_MNI}/Native/${hemi2}.thickness.native.shape.gii ${MyelinMappingSigma}
    rm ${wbDir_T1w}/temp_ribbon.nii.gz
    wb_command -metric-smoothing ${wbDir_T1w}/Native/${hemi2}.midthickness.native.surf.gii ${wbDir_MNI}/Native/${hemi2}.MyelinMap.native.func.gii ${SurfaceSmoothingSigma} ${wbDir_MNI}/Native/${hemi2}.SmoothedMyelinMap.native.func.gii -roi ${wbDir_MNI}/Native/${hemi2}.roi.native.shape.gii  

    for Map in MyelinMap ; do
        echo -e "      - ${Map}"

        wb_command -metric-resample ${wbDir_MNI}/Native/${hemi2}.${Map}.native.func.gii ${RegSphere} ${wbDir_MNI}/fsaverage_LR${LowResMesh}k/${hemi2}.sphere.${LowResMesh}k_fs_LR.surf.gii ADAP_BARY_AREA ${wbDir_MNI}/fsaverage_LR${LowResMesh}k/${hemi2}.${Map}.${LowResMesh}k_fs_LR.func.gii -area-surfs ${wbDir_T1w}/Native/${hemi2}.midthickness.native.surf.gii ${wbDir_MNI}/fsaverage_LR${LowResMesh}k/${hemi2}.midthickness.${LowResMesh}k_fs_LR.surf.gii -current-roi ${wbDir_MNI}/Native/${hemi2}.roi.native.shape.gii
        wb_command -metric-smoothing ${wbDir_MNI}/fsaverage_LR${LowResMesh}k/${hemi2}.midthickness.${LowResMesh}k_fs_LR.surf.gii ${wbDir_MNI}/fsaverage_LR${LowResMesh}k/${hemi2}.${Map}.${LowResMesh}k_fs_LR.func.gii ${CorrectionSigma} ${wbDir_MNI}/fsaverage_LR${LowResMesh}k/${hemi2}.${Map}_s${CorrectionSigma}.${LowResMesh}k_fs_LR.func.gii -roi ${wbDir_MNI}/fsaverage_LR${LowResMesh}k/${hemi2}.atlasroi.${LowResMesh}k_fs_LR.shape.gii
        wb_command -metric-resample ${wbDir_MNI}/fsaverage_LR${LowResMesh}k/${hemi2}.${Map}_s${CorrectionSigma}.${LowResMesh}k_fs_LR.func.gii ${wbDir_MNI}/fsaverage_LR${LowResMesh}k/${hemi2}.sphere.${LowResMesh}k_fs_LR.surf.gii ${RegSphere} ADAP_BARY_AREA ${wbDir_MNI}/Native/${hemi2}.${Map}_s${CorrectionSigma}.native.func.gii -area-surfs ${wbDir_MNI}/fsaverage_LR${LowResMesh}k/${hemi2}.midthickness.${LowResMesh}k_fs_LR.surf.gii ${wbDir_T1w}/Native/${hemi2}.midthickness.native.surf.gii -current-roi ${wbDir_MNI}/fsaverage_LR${LowResMesh}k/${hemi2}.atlasroi.${LowResMesh}k_fs_LR.shape.gii
        wb_command -metric-dilate ${wbDir_MNI}/Native/${hemi2}.${Map}_s${CorrectionSigma}.native.func.gii ${wbDir_T1w}/Native/${hemi2}.midthickness.native.surf.gii 30 ${wbDir_MNI}/Native/${hemi2}.${Map}_s${CorrectionSigma}.native.func.gii -nearest
        wb_command -metric-mask ${wbDir_MNI}/Native/${hemi2}.${Map}_s${CorrectionSigma}.native.func.gii ${wbDir_MNI}/Native/${hemi2}.roi.native.shape.gii ${wbDir_MNI}/Native/${hemi2}.${Map}_s${CorrectionSigma}.native.func.gii
        rm ${wbDir_MNI}/fsaverage_LR${LowResMesh}k/${hemi2}.${Map}.${LowResMesh}k_fs_LR.func.gii ${wbDir_MNI}/fsaverage_LR${LowResMesh}k/${hemi2}.${Map}_s${CorrectionSigma}.${LowResMesh}k_fs_LR.func.gii
    done

    for STRING in $MapListFunc ; do
        echo -e "      - ${STRING}"
        Map=`echo $STRING | cut -d "@" -f 1`
        Ext=`echo $STRING | cut -d "@" -f 2`

        wb_command -set-map-name ${wbDir_MNI}/Native/${hemi2}.${Map}.native.${Ext}.gii 1 ${hemi2}_${Map}
        wb_command -metric-palette ${wbDir_MNI}/Native/${hemi2}.${Map}.native.${Ext}.gii MODE_AUTO_SCALE_PERCENTAGE -pos-percent 4 96 -interpolate true -palette-name videen_style -disp-pos true -disp-neg false -disp-zero false
        wb_command -metric-resample ${wbDir_MNI}/Native/${hemi2}.${Map}.native.${Ext}.gii ${RegSphere} ${wbDir_MNI}/fsaverage_LR${HighResMesh}k/${hemi2}.sphere.${HighResMesh}k_fs_LR.surf.gii ADAP_BARY_AREA ${wbDir_MNI}/fsaverage_LR${HighResMesh}k/${hemi2}.${Map}.${HighResMesh}k_fs_LR.${Ext}.gii -area-surfs ${wbDir_T1w}/Native/${hemi2}.midthickness.native.surf.gii ${wbDir_MNI}/fsaverage_LR${HighResMesh}k/${hemi2}.midthickness.${HighResMesh}k_fs_LR.surf.gii -current-roi ${wbDir_MNI}/Native/${hemi2}.roi.native.shape.gii
        wb_command -metric-mask ${wbDir_MNI}/fsaverage_LR${HighResMesh}k/${hemi2}.${Map}.${HighResMesh}k_fs_LR.${Ext}.gii ${wbDir_MNI}/fsaverage_LR${HighResMesh}k/${hemi2}.atlasroi.${HighResMesh}k_fs_LR.shape.gii ${wbDir_MNI}/fsaverage_LR${HighResMesh}k/${hemi2}.${Map}.${HighResMesh}k_fs_LR.${Ext}.gii

        for LowResMesh in ${LowResMeshes} ; do
          wb_command -metric-resample ${wbDir_MNI}/Native/${hemi2}.${Map}.native.${Ext}.gii ${RegSphere} ${wbDir_MNI}/fsaverage_LR${LowResMesh}k/${hemi2}.sphere.${LowResMesh}k_fs_LR.surf.gii ADAP_BARY_AREA ${wbDir_MNI}/fsaverage_LR${LowResMesh}k/${hemi2}.${Map}.${LowResMesh}k_fs_LR.${Ext}.gii -area-surfs ${wbDir_T1w}/Native/${hemi2}.midthickness.native.surf.gii ${wbDir_MNI}/fsaverage_LR${LowResMesh}k/${hemi2}.midthickness.${LowResMesh}k_fs_LR.surf.gii -current-roi ${wbDir_MNI}/Native/${hemi2}.roi.native.shape.gii
          wb_command -metric-mask ${wbDir_MNI}/fsaverage_LR${LowResMesh}k/${hemi2}.${Map}.${LowResMesh}k_fs_LR.${Ext}.gii ${wbDir_MNI}/fsaverage_LR${LowResMesh}k/${hemi2}.atlasroi.${LowResMesh}k_fs_LR.shape.gii ${wbDir_MNI}/fsaverage_LR${LowResMesh}k/${hemi2}.${Map}.${LowResMesh}k_fs_LR.${Ext}.gii
        done
    done
done

LowResMeshList=""
for LowResMesh in ${LowResMeshes} ; do
    LowResMeshList+="${wbDir_MNI}/fsaverage_LR${LowResMesh}k@${LowResMesh}k_fs_LR@atlasroi "
done

echo -e "\n## Create CIFTI Files"
for STRING in ${wbDir_MNI}/Native@native@roi ${wbDir_MNI}/"fsaverage_LR${HighResMesh}k"@${HighResMesh}k_fs_LR@atlasroi ${LowResMeshList} ; do
    echo -e "    - ${STRING}"
    Folder=`echo $STRING | cut -d "@" -f 1`
    Mesh=`echo $STRING | cut -d "@" -f 2`
    ROI=`echo $STRING | cut -d "@" -f 3`

    for STRINGII in $MapListFunc ; do
        echo -e "      - ${STRINGII}"
        Map=`echo $STRINGII | cut -d "@" -f 1`
        Ext=`echo $STRINGII | cut -d "@" -f 2`

        wb_command -cifti-create-dense-scalar ${Folder}/${Map}.${Mesh}.dscalar.nii -left-metric ${Folder}/L.${Map}.${Mesh}.${Ext}.gii -roi-left ${Folder}/L.${ROI}.${Mesh}.shape.gii -right-metric ${Folder}/R.${Map}.${Mesh}.${Ext}.gii -roi-right ${Folder}/R.${ROI}.${Mesh}.shape.gii
        wb_command -set-map-names ${Folder}/${Map}.${Mesh}.dscalar.nii -map 1 ${Map}
#        wb_command -cifti-palette ${Folder}/${Map}.${Mesh}.dscalar.nii MODE_AUTO_SCALE_PERCENTAGE ${Folder}/${Map}.${Mesh}.dscalar.nii -pos-percent 4 96 -interpolate true -palette-name videen_style -disp-pos true -disp-neg false -disp-zero false
    done
done

echo -e "\n## Add CIFTI Maps to Spec Files"
MapListDscalar="corrThickness@dscalar MyelinMap@dscalar SmoothedMyelinMap@dscalar"

LowResMeshListII=""
for LowResMesh in ${LowResMeshes} ; do
  LowResMeshListII+="${wbDir_MNI}/fsaverage_LR${LowResMesh}k@${wbDir_MNI}/fsaverage_LR${LowResMesh}k@${LowResMesh}k_fs_LR "
done

for STRING in ${wbDir_T1w}/Native@${wbDir_MNI}/Native@native ${wbDir_MNI}/Native@${wbDir_MNI}/Native@native ${wbDir_MNI}/"fsaverage_LR${HighResMesh}k"@${wbDir_MNI}/"fsaverage_LR${HighResMesh}k"@${HighResMesh}k_fs_LR ${LowResMeshListII} ; do
    FolderI=`echo $STRING | cut -d "@" -f 1`
    FolderII=`echo $STRING | cut -d "@" -f 2`
    Mesh=`echo $STRING | cut -d "@" -f 3`
    echo -e "    - ${Mesh}"

    for STRINGII in $MapListDscalar ; do
        echo -e "      - ${STRINGII}"
        Map=`echo $STRINGII | cut -d "@" -f 1`
        Ext=`echo $STRINGII | cut -d "@" -f 2`

        wb_command -add-to-spec-file ${FolderI}/${Mesh}.wb.spec INVALID ${FolderII}/${Map}.${Mesh}.${Ext}.nii
    done
done

flirt -applyxfm -init ${wbDir_MNI}/xfms/T1w2TempLinear.mat -in ${wbDir_T1w}/T1wDividedByT2w.nii.gz -ref ${templateDir}/MNI152_T1_2mm -out ${wbDir_MNI}/T1wDividedByT2w.nii.gz -interp trilinear


echo -e "\n## Parcel-wise microstructure"
parcDir="${FuNP}/parcellations"
atlas_parc=($(ls ${parcDir}/*conte69.csv))
for parc in "${atlas_parc[@]}"; do
    parc_tmp=$(echo "${parc}" | rev | awk -F '/' '{print $1}' | rev )
    parc_str=$(echo "${parc_tmp}" | awk -F '.' '{print $1}' )
    echo -e "    - ${parc_str}"

    python ${FuNP}/functions/mpc_micro.py ${wbDir_MNI}/fsaverage_LR${LowResMesh}k ${parc} ${outDir}
done


echo -e "\n## Build microstructural profile covariance"
if [ ! -d ${outDir}/Native ]; then 
    mkdir -m 777 -p ${outDir}/Native
fi
if [ ! -d ${outDir}/fsaverage_LR${HighResMesh}k ]; then 
    mkdir -m 777 -p ${outDir}/fsaverage_LR${HighResMesh}k
fi
if [ ! -d ${outDir}/fsaverage_LR${LowResMesh}k ]; then 
    mkdir -m 777 -p ${outDir}/fsaverage_LR${LowResMesh}k
fi

mri_convert ${wbDir_T1w}/T1wDividedByT2w.nii.gz ${outDir}/Native/T1wDividedByT2w.mgz

export SUBJECTS_DIR=${strucDir}
num_surfs=14
for hemi in lh rh ; do
    if [ "$hemi" == "lh" ]; then
        hemi1="lh"
        hemi2="L"
        hemi3="LEFT"
    elif [ "$hemi" == "rh" ]; then
        hemi1="rh"
        hemi2="R"
        hemi3="RIGHT"
    fi
    echo -e "  - ${hemi3} hemisphere"

    echo -e "    - Generate equivolumetric surfaces"
    unset LD_LIBRARY_PATH
    tot_surfs=$((num_surfs + 2))
    python ${FuNP}/functions/generate_equivolumetric_surfaces.py \
        ${fsDir}/surf/${hemi1}.pial \
        ${fsDir}/surf/${hemi1}.white \
        ${tot_surfs} \
        ${fsDir}/surf/${hemi1}.${num_surfs}surfs \
        ${fsDir}/ \
        --software freesurfer --subject_id fs_initial

    # Remove top and bottom surface
    rm -rfv "${fsDir}/surf/${hemi}.${num_surfs}surfs0.0.pial" "${fsDir}/surf/${hemi1}.${num_surfs}surfs1.0.pial"


    echo -e "    - Map microstructural image to each surface"
    RegSphere="${wbDir_MNI}/Native/${hemi2}.sphere.reg.reg_LR.native.surf.gii"
    x=$(ls -t ${fsDir}/surf/${hemi}.${num_surfs}surfs*)
    for n in $(seq 1 1 ${num_surfs}) ; do
        tmp=$(sed -n ${n}p <<< ${x})
        tmp2=$(echo "${tmp}" | rev | awk -F '/' '{print $1}' | rev )
        which_surf=`echo ${tmp2:3}`
        echo -e "      >> ${which_surf}"
        
        echo -e "      - fsnative space"
        mri_vol2surf --mov ${outDir}/Native/T1wDividedByT2w.mgz --regheader fs_initial --hemi ${hemi} --out_type mgh --out ${outDir}/Native/${hemi}.${n}by${num_surfs}surf_micro.native.mgh --surf ${which_surf}

        echo -e "      - Map to Conte69 space"
        mris_convert -c ${outDir}/Native/${hemi}.${n}by${num_surfs}surf_micro.native.mgh ${fsDir}/surf/${hemi1}.white ${outDir}/Native/${hemi2}.${n}by${num_surfs}surf_micro.native.shape.gii
          wb_command -set-structure ${outDir}/Native/${hemi2}.${n}by${num_surfs}surf_micro.native.shape.gii CORTEX_${hemi3}
          wb_command -set-map-names ${outDir}/Native/${hemi2}.${n}by${num_surfs}surf_micro.native.shape.gii -map 1 ${hemi2}_"$mapname"
          wb_command -metric-palette ${outDir}/Native/${hemi2}.${n}by${num_surfs}surf_micro.native.shape.gii MODE_AUTO_SCALE_PERCENTAGE -pos-percent 2 98 -palette-name Gray_Interp -disp-pos true -disp-neg true -disp-zero true

        echo -e "      - High resolution processing"
        wb_command -metric-resample ${outDir}/Native/${hemi2}.${n}by${num_surfs}surf_micro.native.shape.gii ${RegSphere} ${wbDir_MNI}/fsaverage_LR${HighResMesh}k/${hemi2}.sphere.${HighResMesh}k_fs_LR.surf.gii ADAP_BARY_AREA ${outDir}/fsaverage_LR${HighResMesh}k/${hemi2}.${n}by${num_surfs}surf_micro.${HighResMesh}k_fs_LR.shape.gii -area-surfs ${wbDir_T1w}/Native/${hemi2}.midthickness.native.surf.gii ${wbDir_MNI}/fsaverage_LR${HighResMesh}k/${hemi2}.midthickness.${HighResMesh}k_fs_LR.surf.gii -current-roi ${wbDir_MNI}/Native/${hemi2}.roi.native.shape.gii
        wb_command -metric-mask ${outDir}/fsaverage_LR${HighResMesh}k/${hemi2}.${n}by${num_surfs}surf_micro.${HighResMesh}k_fs_LR.shape.gii ${wbDir_MNI}/fsaverage_LR${HighResMesh}k/${hemi2}.atlasroi.${HighResMesh}k_fs_LR.shape.gii ${outDir}/fsaverage_LR${HighResMesh}k/${hemi2}.${n}by${num_surfs}surf_micro.${HighResMesh}k_fs_LR.shape.gii

        echo -e "      - Low resolution processing"
        wb_command -metric-resample ${outDir}/Native/${hemi2}.${n}by${num_surfs}surf_micro.native.shape.gii ${RegSphere} ${wbDir_MNI}/fsaverage_LR${LowResMesh}k/${hemi2}.sphere.${LowResMesh}k_fs_LR.surf.gii ADAP_BARY_AREA ${outDir}/fsaverage_LR${LowResMesh}k/${hemi2}.${n}by${num_surfs}surf_micro.${LowResMesh}k_fs_LR.shape.gii -area-surfs ${wbDir_T1w}/Native/${hemi2}.midthickness.native.surf.gii ${wbDir_MNI}/fsaverage_LR${LowResMesh}k/${hemi2}.midthickness.${LowResMesh}k_fs_LR.surf.gii -current-roi ${wbDir_MNI}/Native/${hemi2}.roi.native.shape.gii
        wb_command -metric-mask ${outDir}/fsaverage_LR${LowResMesh}k/${hemi2}.${n}by${num_surfs}surf_micro.${LowResMesh}k_fs_LR.shape.gii ${wbDir_MNI}/fsaverage_LR${LowResMesh}k/${hemi2}.atlasroi.${LowResMesh}k_fs_LR.shape.gii ${outDir}/fsaverage_LR${LowResMesh}k/${hemi2}.${n}by${num_surfs}surf_micro.${LowResMesh}k_fs_LR.shape.gii
    done
done

echo -e "\n## Construct the MPC matrix"
parcDir="${FuNP}/parcellations"
atlas_parc=($(ls ${parcDir}/*conte69.csv))
for parc in "${atlas_parc[@]}"; do
    parc_tmp=$(echo "${parc}" | rev | awk -F '/' '{print $1}' | rev )
    parc_str=$(echo "${parc_tmp}" | awk -F '.' '{print $1}' )
    echo -e "    - ${parc_str}"

    python ${FuNP}/functions/mpc_mat.py ${outDir}/fsaverage_LR${LowResMesh}k ${num_surfs} ${parc} ${outDir}
done

echo -e "\n### Microstructural processing finished ###"

