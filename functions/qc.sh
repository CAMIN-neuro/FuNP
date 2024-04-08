#!/bin/bash

source "${FuNP}/functions/utilities.sh"

set -e

Usage() {
    cat <<EOF
Usage: qc.sh <type> <outDir>
  
  <type>        Specify modality types for QC (struc, dwi, func, gd, mpc)
  <outDir>      Output directory

EOF
    exit 1
}

############################# Settings #############################
type="$1"
outDir="$2"

### Check the inputs ###
input=($type $outDir)
if [ "${#input[@]}" -lt 2 ]; then
    Error "A processing flag is missing:
             -type
             -out"
    exit 1;
fi
####################################################################

echo ${type}
tmp=`echo ${type:1:-1}`
type_all=(`echo $tmp | tr "," "\n"`)

for ta in ${type_all[@]}; do
    echo -e "\n## Quality control: ${ta} processing"

    if [ "$ta" == "struc" ]; then
        export SUBJECTS_DIR=${outDir}
        export QA_TOOLS="${FuNP}/functions/QAtools_v1.2"

        ${QA_TOOLS}/recon_checker -s fs_initial -snaps-only 

        qcDir="${outDir}/fs_initial_QC"
        if [ ! -d ${qcDir} ]; then mkdir -m 777 -p ${qcDir}; fi
        mv ${outDir}/QA/fs_initial/rgb/snaps/* ${qcDir}/
        rm -rf ${outDir}/QA
        rm -rf ${outDir}/surfer.log

    elif [ "$ta" == "dwi" ]; then
        
    elif [ "$ta" == "func" ]; then

    elif [ "$ta" == "gd" ]; then

    elif [ "$ta" == "mpc" ]; then
        
    fi
done







