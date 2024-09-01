#!/bin/bash

source "${FuNP}/functions/utilities.sh"

set -e

Usage() {
    cat <<EOF
Usage: gd.sh <wbDir> <outDir> <threads> <procDir>
  
  <wbDir>       wb_adjust folder (typically, ~/struc/wb_adjust)
  <outDir>      Output directory
  <threads>     Number of threads (default: 5)
  <procDir>     Processing directory (default: /tmp)

EOF
    exit 1
}

############################# Settings #############################
wbDir="$1"
outDir="$2"
threads="$3"
procDir="$4"

### Check the inputs ###
input=($wbDir $outDir)
if [ "${#input[@]}" -lt 2 ]; then
    Error "A processing flag is missing:
             -wbDir
             -out"
    exit 1;
fi
####################################################################

export OMP_NUM_THREADS=${threads}

### Prepare the processing directory ###
tmpName=`tr -dc A-Za-z0-9 </dev/urandom | head -c 5`
tmpDir=${procDir}/${tmpName}
if [ ! -d ${tmpDir} ]; then mkdir -m 777 -p ${tmpDir}; fi


echo -e "\n### Start geodesic distance processing ###"
lh_surf="${wbDir}/MNINonLinear/fsaverage_LR32k/L.midthickness.32k_fs_LR.surf.gii"
rh_surf="${wbDir}/MNINonLinear/fsaverage_LR32k/R.midthickness.32k_fs_LR.surf.gii"

parcDir="${FuNP}/parcellations"
atlas_parc=($(ls ${parcDir}/*conte69.csv))
for parc in "${atlas_parc[@]}"; do
    parc_tmp=$(echo "${parc}" | rev | awk -F '/' '{print $1}' | rev )
    parc_str=$(echo "${parc_tmp}" | awk -F '.' '{print $1}' )
    echo -e "    - ${parc_str}"

    lh_parc="${parcDir}/${parc_str}_lh.label.gii"
    rh_parc="${parcDir}/${parc_str}_rh.label.gii"

    python ${FuNP}/functions/gd_map.py ${lh_surf} ${rh_surf} ${lh_parc} ${rh_parc} ${parc_str} ${tmpDir} 
done

echo -e "\n## Move data to the output directory"
cp -r ${tmpDir}/* ${outDir}
rm -rf ${tmpDir}

echo -e "\n### Geodesic distance processing finished ###"

