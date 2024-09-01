#!/bin/bash

source "${FuNP}/functions/utilities.sh"

set -e

Usage() {
    cat <<EOF
Usage: struc.sh <t1> <proc_fs> <outDir> <procDir>
  
  <t1>          T1-weighted image (NIFTI) with full directory
  <proc_fs>     FreeSurfer recon-all directory if it has already been run
  <outDir>      Output directory
  <procDir>     Processing directory (default: /tmp)

EOF
    exit 1
}

############################# Settings #############################
t1="$1"
outDir="$2"
proc_fs="$3"
nthreads="$4"
procDir="$5"

### Check the inputs ###
input=($t1 $outDir)
if [ "${#input[@]}" -lt 2 ]; then
    Error "A processing flag is missing:
             -t1
             -out"
    exit 1;
fi

export OMP_NUM_THREADS=$nthreads
####################################################################

### Prepare the processing directory ###
tmpName=`tr -dc A-Za-z0-9 </dev/urandom | head -c 5`
tmpDir=${procDir}/${tmpName}
if [ ! -d ${tmpDir} ]; then mkdir -m 777 -p ${tmpDir}; fi

### FreeSurfer recon-all ###
if [ -d ${outDir}/fs_initial ]; then 
    Error "fs_initial already exists!!!"
    exit 1; 
fi

echo -e "\n### Start FreeSurfer processing ###"

if [[ ${proc_fs} != None ]]; then
    echo -e "    - Copy the entered FreeSurfer recon-all directory"
    cp -r -L ${proc_fs} ${outDir}/fs_initial
else
    recon-all -i ${t1} -sd ${tmpDir} -s fs_initial -all
    cp -r -L ${tmpDir}/fs_initial ${outDir}
    rm -rf ${tmpDir}
fi

echo -e "\n### FreeSurfer processing finished ###"


### Workbench processing ###
echo -e "\n### Start workbench processing ###"

if [ -d ${outDir}/wb_adjust ]; then 
    Error "wb_adjust already exists!!!"
    exit 1; 
else
    mkdir -m 777 -p ${outDir}/wb_adjust
fi

HighResMesh="164"
LowResMesh="32"
fsDir=${outDir}/fs_initial
wbDir=${outDir}/wb_adjust
wbDir_T1w=${wbDir}/T1w
wbDir_MNI=${wbDir}/MNINonLinear
wbDir_xfm=${wbDir}/MNINonLinear/xfms
wbDir_ROI=${wbDir}/MNINonLinear/ROIs
SurfaceAtlasDIR=${FuNP}/SurfaceAtlas
FreeSurferLabels=${SurfaceAtlasDIR}/FreeSurferAllLut.txt
SubcorticalGrayLabels=${SurfaceAtlasDIR}/FreeSurferSubcorticalLabelTableLut.txt
templateDir=${FuNP}/template

if [ ! -d ${wbDir} ]; then mkdir -m 777 -p ${wbDir}; fi
if [ ! -d ${wbDir_T1w} ]; then mkdir -m 777 -p ${wbDir_T1w}; fi
if [ ! -d ${wbDir_T1w}/Native ]; then mkdir -m 777 -p ${wbDir_T1w}/Native; fi
if [ ! -d ${wbDir_MNI} ]; then mkdir -m 777 -p ${wbDir_MNI}; fi
if [ ! -d ${wbDir_MNI}/Native ]; then mkdir -m 777 -p ${wbDir_MNI}/Native; fi
if [ ! -d ${wbDir_MNI}/fsaverage_LR"$HighResMesh"k ]; then mkdir -m 777 -p ${wbDir_MNI}/fsaverage_LR"$HighResMesh"k; fi
if [ ! -d ${wbDir_MNI}/fsaverage_LR"$LowResMesh"k ]; then mkdir -m 777 -p ${wbDir_MNI}/fsaverage_LR"$LowResMesh"k; fi
if [ ! -d ${wbDir_xfm} ]; then mkdir -m 777 -p ${wbDir_xfm}; fi
if [ ! -d ${wbDir_ROI} ]; then mkdir -m 777 -p ${wbDir_ROI}; fi

echo -e "\n## Prepare data"
# T1 data
mri_convert "$fsDir"/mri/orig.mgz "$wbDir_T1w"/temp.nii.gz
3dresample -orient RPI -prefix "$wbDir_T1w"/T1.nii.gz -inset "$wbDir_T1w"/temp.nii.gz
rm -rf "$wbDir_T1w"/temp.nii.gz
mri_convert "$fsDir"/mri/T1.mgz "$wbDir_T1w"/temp.nii.gz
3dresample -orient RPI -prefix "$wbDir_T1w"/T1w_restore.nii.gz -inset "$wbDir_T1w"/temp.nii.gz
rm -rf "$wbDir_T1w"/temp.nii.gz
mri_convert "$fsDir"/mri/brain.mgz "$wbDir_T1w"/temp.nii.gz
3dresample -orient RPI -prefix "$wbDir_T1w"/T1w_restore_brain.nii.gz -inset "$wbDir_T1w"/temp.nii.gz
rm -rf "$wbDir_T1w"/temp.nii.gz
# MNI template
fslmaths "$templateDir"/MNI152_T1_2mm_brain "$wbDir_MNI"/MNI152_T1_2mm_brain
fslmaths "$templateDir"/MNI152_T1_2mm_brain_mask "$wbDir_MNI"/MNI152_T1_2mm_brain_mask

echo -e "\n## Linear & non-linear registration from T1w_tal1mm to template"
flirt -interp spline -dof 12 -in "$wbDir_T1w"/T1w_restore_brain.nii.gz -ref "$wbDir_MNI"/MNI152_T1_2mm_brain -omat "$wbDir_xfm"/T1w2TempLinear.mat -out "$wbDir_xfm"/T1w2TempLinear.nii.gz
"$SurfaceAtlasDIR"/convert_mat_decimal.sh "$wbDir_xfm"/T1w2TempLinear.mat
fnirt --in="$wbDir_T1w"/T1w_restore_brain.nii.gz --ref="$wbDir_MNI"/MNI152_T1_2mm_brain --aff="$wbDir_xfm"/T1w2TempLinear.mat_conv --refmask="$wbDir_MNI"/MNI152_T1_2mm_brain_mask --fout="$wbDir_xfm"/T1w2Temp.nii.gz --jout="$wbDir_xfm"/NonlinearRegJacobians.nii.gz --refout="$wbDir_xfm"/IntensityModulatedT1.nii.gz --iout="$wbDir_xfm"/2mmReg.nii.gz --logout="$wbDir_xfm"/NonlinearReg.txt --intout="$wbDir_xfm"/NonlinearIntensities.nii.gz --cout="$wbDir_xfm"/NonlinearReg.nii.gz --config="$SurfaceAtlasDIR"/T1_2_Temp.cnf 
invwarp -w "$wbDir_xfm"/T1w2Temp.nii.gz -o "$wbDir_xfm"/T1w2TempInv.nii.gz -r "$wbDir_MNI"/MNI152_T1_2mm_brain

echo -e "\n## Find c_ras offset between FreeSurfer surface and volume and generate matrix to transform surfaces"
MatrixX=`mri_info "$fsDir"/mri/brain.finalsurfs.mgz | grep "c_r" | cut -d "=" -f 5 | sed s/" "/""/g`
MatrixY=`mri_info "$fsDir"/mri/brain.finalsurfs.mgz | grep "c_a" | cut -d "=" -f 5 | sed s/" "/""/g`
MatrixZ=`mri_info "$fsDir"/mri/brain.finalsurfs.mgz | grep "c_s" | cut -d "=" -f 5 | sed s/" "/""/g`
echo -e "1 0 0 ""$MatrixX" > "$fsDir"/mri/c_ras.mat
echo -e "0 1 0 ""$MatrixY" >> "$fsDir"/mri/c_ras.mat
echo -e "0 0 1 ""$MatrixZ" >> "$fsDir"/mri/c_ras.mat
echo -e "0 0 0 1" >> "$fsDir"/mri/c_ras.mat

echo -e "\n## Convert FreeSurfer Volumes (wmparc, aparc.a2009s+aseg, aparc+aseg)"
for Image in wmparc aparc.a2009s+aseg aparc+aseg ; do
    echo -e "    - $Image"

    mri_convert "$fsDir"/mri/"$Image".mgz "$wbDir_T1w"/temp.nii.gz
    3dresample -orient RPI -prefix "$wbDir_T1w"/"$Image"_1mm.nii.gz -inset "$wbDir_T1w"/temp.nii.gz
    applywarp --rel --interp=nn -i "$wbDir_T1w"/"$Image"_1mm.nii.gz -r "$wbDir_xfm"/2mmReg.nii.gz --premat=$FSLDIR/etc/flirtsch/ident.mat -o "$wbDir_MNI"/"$Image".nii.gz
    applywarp --rel --interp=nn -i "$wbDir_T1w"/"$Image"_1mm.nii.gz -r "$wbDir_xfm"/2mmReg.nii.gz -w "$wbDir_xfm"/T1w2Temp.nii.gz -o "$wbDir_MNI"/"$Image".nii.gz
    wb_command -volume-label-import "$wbDir_T1w"/"$Image"_1mm.nii.gz "$FreeSurferLabels" "$wbDir_T1w"/"$Image"_1mm.nii.gz -drop-unused-labels
    wb_command -volume-label-import "$wbDir_MNI"/"$Image".nii.gz "$FreeSurferLabels" "$wbDir_MNI"/"$Image".nii.gz -drop-unused-labels
done

echo -e "\n## Create FreeSurfer Brain Mask"
fslmaths "$wbDir_T1w"/T1w_restore_brain -bin "$wbDir_T1w"/brainmask_fs_1mm
fslmaths "$wbDir_T1w"/brainmask_fs_1mm -ero "$wbDir_T1w"/brainmask_fs_1mm
applywarp --rel --interp=nn -i "$wbDir_T1w"/brainmask_fs_1mm.nii.gz -r "$wbDir_xfm"/2mmReg.nii.gz --premat="$wbDir_xfm"/T1w2TempLinear.mat_conv -o "$wbDir_MNI"/brainmask_fs.nii.gz

echo -e "\n## Add volume files to spec files"
wb_command -add-to-spec-file "$wbDir_T1w"/Native/native.wb.spec INVALID "$wbDir_T1w"/T1w_restore_brain.nii.gz 
wb_command -add-to-spec-file "$wbDir_MNI"/Native/native.wb.spec INVALID "$wbDir_xfm"/2mmReg.nii.gz 

echo -e "\n## Import Subcortical ROIs"
cp "$SurfaceAtlasDIR"/Atlas_ROIs.2mm.nii.gz "$wbDir_ROI"/Atlas_ROIs.2mm.nii.gz
applywarp --interp=nn -i "$wbDir_MNI"/wmparc.nii.gz -r "$wbDir_ROI"/Atlas_ROIs.2mm.nii.gz -o "$wbDir_ROI"/wmparc.2mm.nii.gz
wb_command -volume-label-import "$wbDir_ROI"/wmparc.2mm.nii.gz "$FreeSurferLabels" "$wbDir_ROI"/wmparc.2mm.nii.gz -drop-unused-labels
applywarp --interp=nn -i "$SurfaceAtlasDIR"/Avgwmparc.nii.gz -r "$wbDir_ROI"/Atlas_ROIs.2mm.nii.gz -o "$wbDir_ROI"/Atlas_wmparc.2mm.nii.gz
wb_command -volume-label-import "$wbDir_ROI"/Atlas_wmparc.2mm.nii.gz "$FreeSurferLabels" "$wbDir_ROI"/Atlas_wmparc.2mm.nii.gz -drop-unused-labels
wb_command -volume-label-import "$wbDir_ROI"/wmparc.2mm.nii.gz "$SubcorticalGrayLabels" "$wbDir_ROI"/ROIs.2mm.nii.gz -discard-others
applywarp --interp=spline -i "$wbDir_xfm"/2mmReg.nii.gz -r "$wbDir_ROI"/Atlas_ROIs.2mm.nii.gz -o "$wbDir_xfm"/2mmReg.2mm.nii.gz

cp "$wbDir_xfm"/2mmReg.nii.gz "$wbDir_MNI"/T1w_restore_brain.nii.gz
cp "$wbDir_xfm"/2mmReg.2mm.nii.gz "$wbDir_MNI"/T1w_restore_brain.2mm.nii.gz

echo -e "\n## Start main native mesh processing"

echo -e "\n## Convert and volumetrically reigster white and pial surfaces making linear and nonlinear copies, add each to the appropriate spec file"
for Surface in white pial ; do
  echo -e "    - $Surface"

    for Hemisphere in L R; do
        if [ "$Hemisphere" == "L" ]; then
            hemi1="lh"
            hemi2="L"
            hemi3="LEFT"
        elif [ "$Hemisphere" == "R" ]; then
            hemi1="rh"
            hemi2="R"
            hemi3="RIGHT"
        fi
        echo -e "      - ${hemi3} hemisphere"

        mris_convert "$fsDir"/surf/"$hemi1"."$Surface" "$wbDir_T1w"/Native/"$hemi2"."$Surface".native.surf.gii
        wb_command -set-structure "$wbDir_T1w"/Native/"$hemi2"."$Surface".native.surf.gii CORTEX_"$hemi3" -surface-type ANATOMICAL -surface-secondary-type GRAY_WHITE
        wb_command -surface-apply-affine "$wbDir_T1w"/Native/"$hemi2"."$Surface".native.surf.gii "$fsDir"/mri/c_ras.mat "$wbDir_T1w"/Native/"$hemi2"."$Surface".native.surf.gii
        wb_command -add-to-spec-file "$wbDir_T1w"/Native/native.wb.spec CORTEX_"$hemi3" "$wbDir_T1w"/Native/"$hemi2"."$Surface".native.surf.gii 
        wb_command -surface-apply-affine "$wbDir_T1w"/Native/"$hemi2"."$Surface".native.surf.gii "$wbDir_xfm"/T1w2TempLinear.mat_conv "$wbDir_MNI"/Native/"$hemi2"."$Surface".native.surf.gii -flirt "$wbDir_T1w"/T1w_restore_brain.nii.gz "$wbDir_MNI"/MNI152_T1_2mm_brain.nii.gz 
        wb_command -add-to-spec-file "$wbDir_MNI"/Native/native.wb.spec CORTEX_"$hemi3" "$wbDir_MNI"/Native/"$hemi2"."$Surface".native.surf.gii 
    done
done

echo -e "\n## Create midthickness by averaging white and pial surfaces and use it to make inflated surfacess"
echo -e "## Get number of vertices from native file"
echo -e "## HCP fsaverage_LR32k used -iterations-scale 0.75. Compute new param value for native mesh density"

for Hemisphere in L R; do
    if [ "$Hemisphere" == "L" ]; then
        hemi1="lh"
        hemi2="L"
        hemi3="LEFT"
    elif [ "$Hemisphere" == "R" ]; then
        hemi1="rh"
        hemi2="R"
        hemi3="RIGHT"
    fi
    echo -e "    - ${hemi3}, T1w"

    echo -e "      - T1w"
    # Create midthickness by averaging white and pial surfaces and use it to make inflated surfacess
    wb_command -surface-average "$wbDir_T1w"/Native/"$hemi2".midthickness.native.surf.gii -surf "$wbDir_T1w"/Native/"$hemi2".white.native.surf.gii -surf "$wbDir_T1w"/Native/"$hemi2".pial.native.surf.gii 
    wb_command -set-structure "$wbDir_T1w"/Native/"$hemi2".midthickness.native.surf.gii CORTEX_"$hemi3" -surface-type ANATOMICAL -surface-secondary-type MIDTHICKNESS
    wb_command -add-to-spec-file "$wbDir_T1w"/Native/native.wb.spec CORTEX_"$hemi3" "$wbDir_T1w"/Native/"$hemi2".midthickness.native.surf.gii

    # Get number of vertices from native file
    NativeVerts=`wb_command -file-information "$wbDir_T1w"/Native/"$hemi2".midthickness.native.surf.gii | grep 'Number of Vertices:' | cut -f2 -d: | tr -d '[:space:]'`

    # HCP fsaverage_LR32k used -iterations-scale 0.75. Compute new param value for native mesh density
    NativeInflationScale=`echo -e "scale=4; 1 * 0.75 * $NativeVerts / 32492" | bc -l`
    wb_command -surface-generate-inflated "$wbDir_T1w"/Native/"$hemi2".midthickness.native.surf.gii "$wbDir_T1w"/Native/"$hemi2".inflated.native.surf.gii "$wbDir_T1w"/Native/"$hemi2".very_inflated.native.surf.gii -iterations-scale $NativeInflationScale
    wb_command -add-to-spec-file "$wbDir_T1w"/Native/native.wb.spec CORTEX_"$hemi3" "$wbDir_T1w"/Native/"$hemi2".inflated.native.surf.gii 
    wb_command -add-to-spec-file "$wbDir_T1w"/Native/native.wb.spec CORTEX_"$hemi3" "$wbDir_T1w"/Native/"$hemi2".very_inflated.native.surf.gii 


    echo -e "      - MNINonLinear"
    # Create midthickness by averaging white and pial surfaces and use it to make inflated surfacess
    wb_command -surface-average "$wbDir_MNI"/Native/"$hemi2".midthickness.native.surf.gii -surf "$wbDir_MNI"/Native/"$hemi2".white.native.surf.gii -surf "$wbDir_MNI"/Native/"$hemi2".pial.native.surf.gii 
    wb_command -set-structure "$wbDir_MNI"/Native/"$hemi2".midthickness.native.surf.gii CORTEX_"$hemi3" -surface-type ANATOMICAL -surface-secondary-type MIDTHICKNESS
    wb_command -add-to-spec-file "$wbDir_MNI"/Native/native.wb.spec CORTEX_"$hemi3" "$wbDir_MNI"/Native/"$hemi2".midthickness.native.surf.gii

    # Get number of vertices from native file
    NativeVerts=`wb_command -file-information "$wbDir_MNI"/Native/"$hemi2".midthickness.native.surf.gii | grep 'Number of Vertices:' | cut -f2 -d: | tr -d '[:space:]'`

    # HCP fsaverage_LR32k used -iterations-scale 0.75. Compute new param value for native mesh density
    NativeInflationScale=`echo -e "scale=4; 1 * 0.75 * $NativeVerts / 32492" | bc -l`
    wb_command -surface-generate-inflated "$wbDir_MNI"/Native/"$hemi2".midthickness.native.surf.gii "$wbDir_MNI"/Native/"$hemi2".inflated.native.surf.gii "$wbDir_MNI"/Native/"$hemi2".very_inflated.native.surf.gii -iterations-scale $NativeInflationScale
    wb_command -add-to-spec-file "$wbDir_MNI"/Native/native.wb.spec CORTEX_"$hemi3" "$wbDir_MNI"/Native/"$hemi2".inflated.native.surf.gii 
    wb_command -add-to-spec-file "$wbDir_MNI"/Native/native.wb.spec CORTEX_"$hemi3" "$wbDir_MNI"/Native/"$hemi2".very_inflated.native.surf.gii 
done

echo -e "\n## Convert original and registered spherical surfaces and add them to the nonlinear spec file"
for Surface in sphere.reg sphere ; do
    echo -e "    - $Surface"

    for Hemisphere in L R; do
        if [ "$Hemisphere" == "L" ]; then
            hemi1="lh"
            hemi2="L"
            hemi3="LEFT"
        elif [ "$Hemisphere" == "R" ]; then
            hemi1="rh"
            hemi2="R"
            hemi3="RIGHT"
        fi

        echo -e "      - ${hemi3} hemisphere"
        mris_convert "$fsDir"/surf/"$hemi1"."$Surface" "$wbDir_MNI"/Native/"$hemi2"."$Surface".native.surf.gii
        wb_command -set-structure "$wbDir_MNI"/Native/"$hemi2"."$Surface".native.surf.gii CORTEX_"$hemi3" -surface-type SPHERICAL
    done
done

wb_command -add-to-spec-file "$wbDir_MNI"/Native/native.wb.spec CORTEX_LEFT "$wbDir_MNI"/Native/L.sphere.native.surf.gii 
wb_command -add-to-spec-file "$wbDir_MNI"/Native/native.wb.spec CORTEX_RIGHT "$wbDir_MNI"/Native/R.sphere.native.surf.gii 

echo -e "\n## Add more files to the spec file and convert other FreeSurfer surface data to metric/GIFTI including sulc, curv, and thickness"
for Map in sulc@sulc@Sulc thickness@thickness@Thickness curv@curvature@Curvature ; do
    echo -e "    - $Map"

    fsname=`echo $Map | cut -d "@" -f 1`
    wbname=`echo $Map | cut -d "@" -f 2`
    mapname=`echo $Map | cut -d "@" -f 3`

    for Hemisphere in L R; do
        if [ "$Hemisphere" == "L" ]; then
            hemi1="lh"
            hemi2="L"
            hemi3="LEFT"
        elif [ "$Hemisphere" == "R" ]; then
            hemi1="rh"
            hemi2="R"
            hemi3="RIGHT"
        fi

        echo -e "      - "${hemi3}" hemisphere"
        mris_convert -c "$fsDir"/surf/"$hemi1"."$fsname" "$fsDir"/surf/"$hemi1".white "$wbDir_MNI"/Native/"$hemi2"."$wbname".native.shape.gii
        wb_command -set-structure "$wbDir_MNI"/Native/"$hemi2"."$wbname".native.shape.gii CORTEX_"$hemi3"
        wb_command -metric-math "var * -1" "$wbDir_MNI"/Native/"$hemi2"."$wbname".native.shape.gii -var var "$wbDir_MNI"/Native/"$hemi2"."$wbname".native.shape.gii 
        wb_command -set-map-names "$wbDir_MNI"/Native/"$hemi2"."$wbname".native.shape.gii -map 1 "$hemi2"_"$mapname"
        wb_command -metric-palette "$wbDir_MNI"/Native/"$hemi2"."$wbname".native.shape.gii MODE_AUTO_SCALE_PERCENTAGE -pos-percent 2 98 -palette-name Gray_Interp -disp-pos true -disp-neg true -disp-zero true
    done
done

echo -e "\n## Thickness specific operations"
for Hemisphere in L R ; do
    wb_command -metric-math "abs(thickness)" "$wbDir_MNI"/Native/"$Hemisphere".thickness.native.shape.gii -var thickness "$wbDir_MNI"/Native/"$Hemisphere".thickness.native.shape.gii
    wb_command -metric-palette "$wbDir_MNI"/Native/"$Hemisphere".thickness.native.shape.gii MODE_AUTO_SCALE_PERCENTAGE -pos-percent 4 96 -interpolate true -palette-name videen_style -disp-pos true -disp-neg false -disp-zero false
    wb_command -metric-math "thickness > 0" "$wbDir_MNI"/Native/"$Hemisphere".roi.native.shape.gii -var thickness "$wbDir_MNI"/Native/"$Hemisphere".thickness.native.shape.gii
    wb_command -metric-fill-holes "$wbDir_MNI"/Native/"$Hemisphere".midthickness.native.surf.gii "$wbDir_MNI"/Native/"$Hemisphere".roi.native.shape.gii "$wbDir_MNI"/Native/"$Hemisphere".roi.native.shape.gii
    wb_command -metric-remove-islands "$wbDir_MNI"/Native/"$Hemisphere".midthickness.native.surf.gii "$wbDir_MNI"/Native/"$Hemisphere".roi.native.shape.gii "$wbDir_MNI"/Native/"$Hemisphere".roi.native.shape.gii
    wb_command -set-map-names "$wbDir_MNI"/Native/"$Hemisphere".roi.native.shape.gii -map 1 "$Hemisphere"_ROI
    wb_command -metric-dilate "$wbDir_MNI"/Native/"$Hemisphere".thickness.native.shape.gii "$wbDir_MNI"/Native/"$Hemisphere".midthickness.native.surf.gii 10 "$wbDir_MNI"/Native/"$Hemisphere".thickness.native.shape.gii -nearest
    wb_command -metric-dilate "$wbDir_MNI"/Native/"$Hemisphere".curvature.native.shape.gii "$wbDir_MNI"/Native/"$Hemisphere".midthickness.native.surf.gii 10 "$wbDir_MNI"/Native/"$Hemisphere".curvature.native.shape.gii -nearest
done

echo -e "\n## Label operations"
for Map in aparc aparc.a2009s BA_exvivo ; do
    echo -e "    - $Map"

    for Hemisphere in L R; do
        if [ "$Hemisphere" == "L" ]; then
            hemi1="lh"
            hemi2="L"
            hemi3="LEFT"
        elif [ "$Hemisphere" == "R" ]; then
            hemi1="rh"
            hemi2="R"
            hemi3="RIGHT"
        fi

        echo -e "      - "${hemi3}" hemisphere"
        mris_convert --annot "$fsDir"/label/"$hemi1"."$Map".annot "$fsDir"/surf/"$hemi1".white "$wbDir_MNI"/Native/"$hemi2"."$Map".native.label.gii
        wb_command -set-structure "$wbDir_MNI"/Native/"$hemi2"."$Map".native.label.gii CORTEX_"$hemi3"
        wb_command -set-map-names "$wbDir_MNI"/Native/"$hemi2"."$Map".native.label.gii -map 1 "$hemi2"_"$Map"
        wb_command -gifti-label-add-prefix "$wbDir_MNI"/Native/"$hemi2"."$Map".native.label.gii "$hemi2"_ "$wbDir_MNI"/Native/"$hemi2"."$Map".native.label.gii 
    done
done

echo -e "\n## End main native mesh processing"


echo -e "\n## HighResMesh"
#Copy Atlas Files
for Hemisphere in L R; do
    if [ "$Hemisphere" == "L" ]; then
        hemi1="lh"
        hemi2="L"
        hemi3="LEFT"
    elif [ "$Hemisphere" == "R" ]; then
        hemi1="rh"
        hemi2="R"
        hemi3="RIGHT"
    fi

    echo -e "    - "${hemi3}" hemisphere"
    cp "$SurfaceAtlasDIR"/fs_"$hemi2"/fsaverage."$hemi2".sphere."$HighResMesh"k_fs_"$hemi2".surf.gii "$wbDir_MNI"/fsaverage_LR"$HighResMesh"k/"$hemi2".sphere."$HighResMesh"k_fs_"$hemi2".surf.gii
    cp "$SurfaceAtlasDIR"/fs_"$hemi2"/fs_"$hemi2"-to-fs_LR_fsaverage."$hemi2"_LR.spherical_std."$HighResMesh"k_fs_"$hemi2".surf.gii "$wbDir_MNI"/fsaverage_LR"$HighResMesh"k/"$hemi2".def_sphere."$HighResMesh"k_fs_"$hemi2".surf.gii
    cp "$SurfaceAtlasDIR"/fsaverage."$hemi2"_LR.spherical_std."$HighResMesh"k_fs_LR.surf.gii "$wbDir_MNI"/fsaverage_LR"$HighResMesh"k/"$hemi2".sphere."$HighResMesh"k_fs_LR.surf.gii
    wb_command -add-to-spec-file "$wbDir_MNI"/fsaverage_LR"$HighResMesh"k/"$HighResMesh"k_fs_LR.wb.spec CORTEX_"$hemi3" "$wbDir_MNI"/fsaverage_LR"$HighResMesh"k/"$hemi2".sphere."$HighResMesh"k_fs_LR.surf.gii
    cp "$SurfaceAtlasDIR"/"$hemi2".atlasroi."$HighResMesh"k_fs_LR.shape.gii "$wbDir_MNI"/fsaverage_LR"$HighResMesh"k/"$hemi2".atlasroi."$HighResMesh"k_fs_LR.shape.gii
    cp "$SurfaceAtlasDIR"/"$hemi2".refsulc."$HighResMesh"k_fs_LR.shape.gii "$wbDir_MNI"/fsaverage_LR"$HighResMesh"k/"$hemi2".refsulc."$HighResMesh"k_fs_LR.shape.gii
    if [ -e "$SurfaceAtlasDIR"/colin.cerebral."$hemi2".flat."$HighResMesh"k_fs_LR.surf.gii ] ; then
        cp "$SurfaceAtlasDIR"/colin.cerebral."$hemi2".flat."$HighResMesh"k_fs_LR.surf.gii "$wbDir_MNI"/fsaverage_LR"$HighResMesh"k/"$hemi2".flat."$HighResMesh"k_fs_LR.surf.gii
        wb_command -add-to-spec-file "$wbDir_MNI"/fsaverage_LR"$HighResMesh"k/"$HighResMesh"k_fs_LR.wb.spec CORTEX_"$hemi3" "$wbDir_MNI"/fsaverage_LR"$HighResMesh"k/"$hemi2".flat."$HighResMesh"k_fs_LR.surf.gii
    fi
done

echo -e "\n## Concatinate FS registration to FS --> FS_LR registration"
for Hemisphere in L R; do
    if [ "$Hemisphere" == "L" ]; then
        hemi1="lh"
        hemi2="L"
        hemi3="LEFT"
    elif [ "$Hemisphere" == "R" ]; then
        hemi1="rh"
        hemi2="R"
        hemi3="RIGHT"
    fi

    echo -e "    - "${hemi3}" hemisphere"
    wb_command -surface-sphere-project-unproject "$wbDir_MNI"/Native/"$hemi2".sphere.reg.native.surf.gii "$wbDir_MNI"/fsaverage_LR"$HighResMesh"k/"$hemi2".sphere."$HighResMesh"k_fs_"$hemi2".surf.gii "$wbDir_MNI"/fsaverage_LR"$HighResMesh"k/"$hemi2".def_sphere."$HighResMesh"k_fs_"$hemi2".surf.gii "$wbDir_MNI"/Native/"$hemi2".sphere.reg.reg_LR.native.surf.gii
done

echo -e "\n## Make FreeSurfer Registration Areal Distortion Maps"
for Hemisphere in L R; do
    if [ "$Hemisphere" == "L" ]; then
        hemi1="lh"
        hemi2="L"
        hemi3="LEFT"
    elif [ "$Hemisphere" == "R" ]; then
        hemi1="rh"
        hemi2="R"
        hemi3="RIGHT"
    fi

    echo -e "    - "${hemi3}" hemisphere"
    wb_command -surface-vertex-areas "$wbDir_MNI"/Native/"$hemi2".sphere.native.surf.gii "$wbDir_MNI"/Native/"$hemi2".sphere.native.shape.gii
    wb_command -surface-vertex-areas "$wbDir_MNI"/Native/"$hemi2".sphere.reg.reg_LR.native.surf.gii "$wbDir_MNI"/Native/"$hemi2".sphere.reg.reg_LR.native.shape.gii
    wb_command -metric-math "ln(spherereg / sphere) / ln(2)" "$wbDir_MNI"/Native/"$hemi2".ArealDistortion_FS.native.shape.gii -var sphere "$wbDir_MNI"/Native/"$hemi2".sphere.native.shape.gii -var spherereg "$wbDir_MNI"/Native/"$hemi2".sphere.reg.reg_LR.native.shape.gii
    rm -rf "$wbDir_MNI"/Native/"$hemi2".sphere.native.shape.gii "$wbDir_MNI"/Native/"$hemi2".sphere.reg.reg_LR.native.shape.gii
    wb_command -set-map-names "$wbDir_MNI"/Native/"$hemi2".ArealDistortion_FS.native.shape.gii -map 1 "$hemi2"_Areal_Distortion_FS
    wb_command -metric-palette "$wbDir_MNI"/Native/"$hemi2".ArealDistortion_FS.native.shape.gii MODE_AUTO_SCALE -palette-name ROY-BIG-BL -thresholding THRESHOLD_TYPE_NORMAL THRESHOLD_TEST_SHOW_OUTSIDE -1 1
done

echo -e "\n## Ensure no zeros in atlas medial wall ROI"
for Hemisphere in L R; do
    if [ "$Hemisphere" == "L" ]; then
        hemi1="lh"
        hemi2="L"
        hemi3="LEFT"
    elif [ "$Hemisphere" == "R" ]; then
        hemi1="rh"
        hemi2="R"
        hemi3="RIGHT"
    fi

    echo -e "    - "${hemi3}" hemisphere"
    RegSphere="${wbDir_MNI}/Native/${hemi2}.sphere.reg.reg_LR.native.surf.gii"
    wb_command -metric-resample "$wbDir_MNI"/fsaverage_LR"$HighResMesh"k/"$hemi2".atlasroi."$HighResMesh"k_fs_LR.shape.gii "$wbDir_MNI"/fsaverage_LR"$HighResMesh"k/"$hemi2".sphere."$HighResMesh"k_fs_LR.surf.gii ${RegSphere} BARYCENTRIC "$wbDir_MNI"/Native/"$hemi2".atlasroi.native.shape.gii -largest
    wb_command -metric-math "(atlas + individual) > 0" "$wbDir_MNI"/Native/"$hemi2".roi.native.shape.gii -var atlas "$wbDir_MNI"/Native/"$hemi2".atlasroi.native.shape.gii -var individual "$wbDir_MNI"/Native/"$hemi2".roi.native.shape.gii
    wb_command -metric-mask "$wbDir_MNI"/Native/"$hemi2".thickness.native.shape.gii "$wbDir_MNI"/Native/"$hemi2".roi.native.shape.gii "$wbDir_MNI"/Native/"$hemi2".thickness.native.shape.gii
    wb_command -metric-mask "$wbDir_MNI"/Native/"$hemi2".curvature.native.shape.gii "$wbDir_MNI"/Native/"$hemi2".roi.native.shape.gii "$wbDir_MNI"/Native/"$hemi2".curvature.native.shape.gii
done

echo -e "\n## Populate Highres fs_LR spec file"
#Deform surfaces and other data according to native to folding-based registration selected above.  Regenerate inflated surfaces.
for Surface in white midthickness pial ; do
    echo -e "    - $Surface"

    for Hemisphere in L R; do
        if [ "$Hemisphere" == "L" ]; then
            hemi1="lh"
            hemi2="L"
            hemi3="LEFT"
        elif [ "$Hemisphere" == "R" ]; then
            hemi1="rh"
            hemi2="R"
            hemi3="RIGHT"
        fi

        echo -e "      - "${hemi3}" hemisphere"
        wb_command -surface-resample "$wbDir_MNI"/Native/"$hemi2"."$Surface".native.surf.gii "$wbDir_MNI"/Native/"$hemi2".sphere.reg.reg_LR.native.surf.gii "$wbDir_MNI"/fsaverage_LR"$HighResMesh"k/"$hemi2".sphere."$HighResMesh"k_fs_LR.surf.gii BARYCENTRIC "$wbDir_MNI"/fsaverage_LR"$HighResMesh"k/"$hemi2"."$Surface"."$HighResMesh"k_fs_LR.surf.gii
        wb_command -add-to-spec-file "$wbDir_MNI"/fsaverage_LR"$HighResMesh"k/"$HighResMesh"k_fs_LR.wb.spec CORTEX_"$hemi3" "$wbDir_MNI"/fsaverage_LR"$HighResMesh"k/"$hemi2"."$Surface"."$HighResMesh"k_fs_LR.surf.gii
    done
done

echo -e "    - Surface inflate"
for Hemisphere in L R; do
    if [ "$Hemisphere" == "L" ]; then
        hemi1="lh"
        hemi2="L"
        hemi3="LEFT"
    elif [ "$Hemisphere" == "R" ]; then
        hemi1="rh"
        hemi2="R"
        hemi3="RIGHT"
    fi

    echo -e "      - "${hemi3}" hemisphere"
    wb_command -surface-generate-inflated "$wbDir_MNI"/fsaverage_LR"$HighResMesh"k/"$hemi2".midthickness."$HighResMesh"k_fs_LR.surf.gii "$wbDir_MNI"/fsaverage_LR"$HighResMesh"k/"$hemi2".inflated."$HighResMesh"k_fs_LR.surf.gii "$wbDir_MNI"/fsaverage_LR"$HighResMesh"k/"$hemi2".very_inflated."$HighResMesh"k_fs_LR.surf.gii -iterations-scale 2.5
    wb_command -add-to-spec-file "$wbDir_MNI"/fsaverage_LR"$HighResMesh"k/"$HighResMesh"k_fs_LR.wb.spec CORTEX_"$hemi3" "$wbDir_MNI"/fsaverage_LR"$HighResMesh"k/"$hemi2".inflated."$HighResMesh"k_fs_LR.surf.gii
    wb_command -add-to-spec-file "$wbDir_MNI"/fsaverage_LR"$HighResMesh"k/"$HighResMesh"k_fs_LR.wb.spec CORTEX_"$hemi3" "$wbDir_MNI"/fsaverage_LR"$HighResMesh"k/"$hemi2".very_inflated."$HighResMesh"k_fs_LR.surf.gii
done

echo -e "    - Metric resample"
for Hemisphere in L R; do
    if [ "$Hemisphere" == "L" ]; then
        hemi1="lh"
        hemi2="L"
        hemi3="LEFT"
    elif [ "$Hemisphere" == "R" ]; then
        hemi1="rh"
        hemi2="R"
        hemi3="RIGHT"
    fi

    echo -e "      - "${hemi3}" hemisphere"

    for Map in thickness curvature ; do
        echo -e "        - $Map"
        RegSphere="${wbDir_MNI}/Native/${hemi2}.sphere.reg.reg_LR.native.surf.gii"
        wb_command -metric-resample "$wbDir_MNI"/Native/"$hemi2"."$Map".native.shape.gii ${RegSphere} "$wbDir_MNI"/fsaverage_LR"$HighResMesh"k/"$hemi2".sphere."$HighResMesh"k_fs_LR.surf.gii ADAP_BARY_AREA "$wbDir_MNI"/fsaverage_LR"$HighResMesh"k/"$hemi2"."$Map"."$HighResMesh"k_fs_LR.shape.gii -area-surfs "$wbDir_T1w"/Native/"$hemi2".midthickness.native.surf.gii "$wbDir_MNI"/fsaverage_LR"$HighResMesh"k/"$hemi2".midthickness."$HighResMesh"k_fs_LR.surf.gii -current-roi "$wbDir_MNI"/Native/"$hemi2".roi.native.shape.gii
        wb_command -metric-mask "$wbDir_MNI"/fsaverage_LR"$HighResMesh"k/"$hemi2"."$Map"."$HighResMesh"k_fs_LR.shape.gii "$wbDir_MNI"/fsaverage_LR"$HighResMesh"k/"$hemi2".atlasroi."$HighResMesh"k_fs_LR.shape.gii "$wbDir_MNI"/fsaverage_LR"$HighResMesh"k/"$hemi2"."$Map"."$HighResMesh"k_fs_LR.shape.gii
    done  

    wb_command -metric-resample "$wbDir_MNI"/Native/"$hemi2".ArealDistortion_FS.native.shape.gii ${RegSphere} "$wbDir_MNI"/fsaverage_LR"$HighResMesh"k/"$hemi2".sphere."$HighResMesh"k_fs_LR.surf.gii ADAP_BARY_AREA "$wbDir_MNI"/fsaverage_LR"$HighResMesh"k/"$hemi2".ArealDistortion_FS."$HighResMesh"k_fs_LR.shape.gii -area-surfs "$wbDir_T1w"/Native/"$hemi2".midthickness.native.surf.gii "$wbDir_MNI"/fsaverage_LR"$HighResMesh"k/"$hemi2".midthickness."$HighResMesh"k_fs_LR.surf.gii
    wb_command -metric-resample "$wbDir_MNI"/Native/"$hemi2".sulc.native.shape.gii ${RegSphere} "$wbDir_MNI"/fsaverage_LR"$HighResMesh"k/"$hemi2".sphere."$HighResMesh"k_fs_LR.surf.gii ADAP_BARY_AREA "$wbDir_MNI"/fsaverage_LR"$HighResMesh"k/"$hemi2".sulc."$HighResMesh"k_fs_LR.shape.gii -area-surfs "$wbDir_T1w"/Native/"$hemi2".midthickness.native.surf.gii "$wbDir_MNI"/fsaverage_LR"$HighResMesh"k/"$hemi2".midthickness."$HighResMesh"k_fs_LR.surf.gii

    for Map in aparc aparc.a2009s ; do
        echo -e "        - $Map"

        wb_command -label-resample "$wbDir_MNI"/Native/"$hemi2"."$Map".native.label.gii ${RegSphere} "$wbDir_MNI"/fsaverage_LR"$HighResMesh"k/"$hemi2".sphere."$HighResMesh"k_fs_LR.surf.gii BARYCENTRIC "$wbDir_MNI"/fsaverage_LR"$HighResMesh"k/"$hemi2"."$Map"."$HighResMesh"k_fs_LR.label.gii -largest
    done
done


echo -e "\n## LowResMesh"
#Copy Atlas Files
for Hemisphere in L R; do
    if [ "$Hemisphere" == "L" ]; then
        hemi1="lh"
        hemi2="L"
        hemi3="LEFT"
    elif [ "$Hemisphere" == "R" ]; then
        hemi1="rh"
        hemi2="R"
        hemi3="RIGHT"
    fi

    echo -e "    - "${hemi3}" hemisphere"

    cp "$SurfaceAtlasDIR"/"$hemi2".sphere."$LowResMesh"k_fs_LR.surf.gii "$wbDir_MNI"/fsaverage_LR"$LowResMesh"k/"$hemi2".sphere."$LowResMesh"k_fs_LR.surf.gii
    wb_command -add-to-spec-file "$wbDir_MNI"/fsaverage_LR"$LowResMesh"k/"$LowResMesh"k_fs_LR.wb.spec CORTEX_"$hemi3" "$wbDir_MNI"/fsaverage_LR"$LowResMesh"k/"$hemi2".sphere."$LowResMesh"k_fs_LR.surf.gii
    cp "$SurfaceAtlasDIR"/"$hemi2".atlasroi."$LowResMesh"k_fs_LR.shape.gii "$wbDir_MNI"/fsaverage_LR"$LowResMesh"k/"$hemi2".atlasroi."$LowResMesh"k_fs_LR.shape.gii

    if [ -e "$SurfaceAtlasDIR"/colin.cerebral."$hemi2".flat."$LowResMesh"k_fs_LR.surf.gii ] ; then
        cp "$SurfaceAtlasDIR"/colin.cerebral."$hemi2".flat."$LowResMesh"k_fs_LR.surf.gii "$wbDir_MNI"/fsaverage_LR"$LowResMesh"k/"$hemi2".flat."$LowResMesh"k_fs_LR.surf.gii
        wb_command -add-to-spec-file "$wbDir_MNI"/fsaverage_LR"$LowResMesh"k/"$LowResMesh"k_fs_LR.wb.spec CORTEX_"$hemi3" "$wbDir_MNI"/fsaverage_LR"$LowResMesh"k/"$hemi2".flat."$LowResMesh"k_fs_LR.surf.gii
    fi
done

echo -e "\n## Create downsampled fs_LR spec files"
for Surface in white midthickness pial ; do
  echo -e "    - $Surface"

    for Hemisphere in L R; do
        if [ "$Hemisphere" == "L" ]; then
            hemi1="lh"
            hemi2="L"
            hemi3="LEFT"
        elif [ "$Hemisphere" == "R" ]; then
            hemi1="rh"
            hemi2="R"
            hemi3="RIGHT"
        fi

        echo -e "      - "${hemi3}" hemisphere"
        wb_command -surface-resample "$wbDir_MNI"/Native/"$hemi2"."$Surface".native.surf.gii "$wbDir_MNI"/Native/"$hemi2".sphere.reg.reg_LR.native.surf.gii "$wbDir_MNI"/fsaverage_LR"$LowResMesh"k/"$hemi2".sphere."$LowResMesh"k_fs_LR.surf.gii BARYCENTRIC "$wbDir_MNI"/fsaverage_LR"$LowResMesh"k/"$hemi2"."$Surface"."$LowResMesh"k_fs_LR.surf.gii
        wb_command -add-to-spec-file "$wbDir_MNI"/fsaverage_LR"$LowResMesh"k/"$LowResMesh"k_fs_LR.wb.spec CORTEX_"$hemi3" "$wbDir_MNI"/fsaverage_LR"$LowResMesh"k/"$hemi2"."$Surface"."$LowResMesh"k_fs_LR.surf.gii
    done
done

echo -e "    - Surface inflate"
for Hemisphere in L R; do
    if [ "$Hemisphere" == "L" ]; then
        hemi1="lh"
        hemi2="L"
        hemi3="LEFT"
    elif [ "$Hemisphere" == "R" ]; then
        hemi1="rh"
        hemi2="R"
        hemi3="RIGHT"
    fi

    echo -e "      - "${hemi3}" hemisphere"
    wb_command -surface-generate-inflated "$wbDir_MNI"/fsaverage_LR"$LowResMesh"k/"$hemi2".midthickness."$LowResMesh"k_fs_LR.surf.gii "$wbDir_MNI"/fsaverage_LR"$LowResMesh"k/"$hemi2".inflated."$LowResMesh"k_fs_LR.surf.gii "$wbDir_MNI"/fsaverage_LR"$LowResMesh"k/"$hemi2".very_inflated."$LowResMesh"k_fs_LR.surf.gii -iterations-scale 0.75
    wb_command -add-to-spec-file "$wbDir_MNI"/fsaverage_LR"$LowResMesh"k/"$LowResMesh"k_fs_LR.wb.spec CORTEX_"$hemi3" "$wbDir_MNI"/fsaverage_LR"$LowResMesh"k/"$hemi2".inflated."$LowResMesh"k_fs_LR.surf.gii
    wb_command -add-to-spec-file "$wbDir_MNI"/fsaverage_LR"$LowResMesh"k/"$LowResMesh"k_fs_LR.wb.spec CORTEX_"$hemi3" "$wbDir_MNI"/fsaverage_LR"$LowResMesh"k/"$hemi2".very_inflated."$LowResMesh"k_fs_LR.surf.gii
done

echo -e "    - Metric resample"
for Hemisphere in L R; do
    if [ "$Hemisphere" == "L" ]; then
        hemi1="lh"
        hemi2="L"
        hemi3="LEFT"
    elif [ "$Hemisphere" == "R" ]; then
        hemi1="rh"
        hemi2="R"
        hemi3="RIGHT"
    fi

    echo -e "      - "${hemi3}" hemisphere"
    RegSphere="${wbDir_MNI}/Native/${hemi2}.sphere.reg.reg_LR.native.surf.gii"
    for Map in sulc thickness curvature ; do
        echo -e "        - $Map"
        wb_command -metric-resample "$wbDir_MNI"/Native/"$hemi2"."$Map".native.shape.gii ${RegSphere} "$wbDir_MNI"/fsaverage_LR"$LowResMesh"k/"$hemi2".sphere."$LowResMesh"k_fs_LR.surf.gii ADAP_BARY_AREA "$wbDir_MNI"/fsaverage_LR"$LowResMesh"k/"$hemi2"."$Map"."$LowResMesh"k_fs_LR.shape.gii -area-surfs "$wbDir_T1w"/Native/"$hemi2".midthickness.native.surf.gii "$wbDir_MNI"/fsaverage_LR"$LowResMesh"k/"$hemi2".midthickness."$LowResMesh"k_fs_LR.surf.gii -current-roi "$wbDir_MNI"/Native/"$hemi2".roi.native.shape.gii
        wb_command -metric-mask "$wbDir_MNI"/fsaverage_LR"$LowResMesh"k/"$hemi2"."$Map"."$LowResMesh"k_fs_LR.shape.gii "$wbDir_MNI"/fsaverage_LR"$LowResMesh"k/"$hemi2".atlasroi."$LowResMesh"k_fs_LR.shape.gii "$wbDir_MNI"/fsaverage_LR"$LowResMesh"k/"$hemi2"."$Map"."$LowResMesh"k_fs_LR.shape.gii
    done  

    wb_command -metric-resample "$wbDir_MNI"/Native/"$hemi2".ArealDistortion_FS.native.shape.gii ${RegSphere} "$wbDir_MNI"/fsaverage_LR"$LowResMesh"k/"$hemi2".sphere."$LowResMesh"k_fs_LR.surf.gii ADAP_BARY_AREA "$wbDir_MNI"/fsaverage_LR"$LowResMesh"k/"$hemi2".ArealDistortion_FS."$LowResMesh"k_fs_LR.shape.gii -area-surfs "$wbDir_T1w"/Native/"$hemi2".midthickness.native.surf.gii "$wbDir_MNI"/fsaverage_LR"$LowResMesh"k/"$hemi2".midthickness."$LowResMesh"k_fs_LR.surf.gii
    wb_command -metric-resample "$wbDir_MNI"/Native/"$hemi2".sulc.native.shape.gii ${RegSphere} "$wbDir_MNI"/fsaverage_LR"$LowResMesh"k/"$hemi2".sphere."$LowResMesh"k_fs_LR.surf.gii ADAP_BARY_AREA "$wbDir_MNI"/fsaverage_LR"$LowResMesh"k/"$hemi2".sulc."$LowResMesh"k_fs_LR.shape.gii -area-surfs "$wbDir_T1w"/Native/"$hemi2".midthickness.native.surf.gii "$wbDir_MNI"/fsaverage_LR"$LowResMesh"k/"$hemi2".midthickness."$LowResMesh"k_fs_LR.surf.gii

    for Map in aparc aparc.a2009s ; do
        echo -e "        - $Map"
        wb_command -label-resample "$wbDir_MNI"/Native/"$hemi2"."$Map".native.label.gii ${RegSphere} "$wbDir_MNI"/fsaverage_LR"$LowResMesh"k/"$hemi2".sphere."$LowResMesh"k_fs_LR.surf.gii BARYCENTRIC "$wbDir_MNI"/fsaverage_LR"$LowResMesh"k/"$hemi2"."$Map"."$LowResMesh"k_fs_LR.label.gii -largest
    done
done

echo -e "\n### Workbench processing finished ###\n"

rm -rf ${tmpDir}

