#!/bin/bash

source "${FuNP}/functions/utilities.sh"

set -e

Usage() {
    cat <<EOF
Usage: qc.sh <type> <dataDir>
  
  <type>        Specify modality types for QC (struc, dwi, func, gd, mpc)
  <dataDir>     Directory that data were stored 

EOF
    exit 1
}

############################# Settings #############################
type="$1"
dataDir="$2"
force="$3"

### Check the inputs ###
input=($type $qcDir)
if [ "${#input[@]}" -lt 1 ]; then
    Error "A processing flag is missing:
             -type
             -dataDir"
    exit 1;
fi
####################################################################

echo ${type}
tmp=`echo ${type:1:-1}`
type_all=(`echo $tmp | tr "," "\n"`)

for ta in ${type_all[@]}; do
    echo -e "\n## Quality control: ${ta} processing"

    if [ "$ta" == "struc" ]; then
        strucDir=${dataDir}/struc
        qcDir=${dataDir}/qc/struc

        if [ -d ${qcDir} ]; then 
            if [ $force == TRUE ]; then
                Warning "output directory will be overwritten!!!"
                rm -rf ${qcDir}
                mkdir -m 777 -p ${qcDir}
            else
                Error "~/qc/struc directory already exists!!! Use -force option to overwrite outputs"
                exit 1; 
            fi
        else
            mkdir -m 777 -p ${qcDir}
        fi

        python ${FuNP}/functions/qc_struc.py ${strucDir} ${qcDir}

    elif [ "$ta" == "dwi" ]; then
        dwiDir=${dataDir}/dwi
        qcDir=${dataDir}/qc/dwi

        if [ -d ${qcDir} ]; then 
            if [ $force == TRUE ]; then
                Warning "output directory will be overwritten!!!"
                rm -rf ${qcDir}
                mkdir -m 777 -p ${qcDir}
            else
                Error "~/qc/dwi directory already exists!!! Use -force option to overwrite outputs"
                exit 1; 
            fi
        else
            mkdir -m 777 -p ${qcDir}
        fi

        mrconvert ${dwiDir}/dwi_b0.mif ${dwiDir}/dwi_b0.nii.gz -force
        mrconvert ${dwiDir}/dwi_b0_brain.mif ${dwiDir}/dwi_b0_brain.nii.gz -force
        mrconvert ${dwiDir}/dwi_mask.mif ${dwiDir}/dwi_mask.nii.gz -force
        fslsplit ${dwiDir}/5TT2b0.nii.gz ${dwiDir}/5TT2b0_split -t

        python ${FuNP}/functions/qc_dwi.py ${dwiDir} ${qcDir} ${FuNP}

        rm -rf ${dwiDir}/dwi_b0.nii.gz
        rm -rf ${dwiDir}/dwi_b0_brain.nii.gz
        rm -rf ${dwiDir}/dwi_b0_mask.nii.gz
        rm -rf ${dwiDir}/5TT2b0_split*.nii.gz

    elif [ "$ta" == "func" ]; then
        funcDir=${dataDir}/func
        qcDir=${dataDir}/qc/func

        if [ -d ${qcDir} ]; then 
            if [ $force == TRUE ]; then
                Warning "output directory will be overwritten!!!"
                rm -rf ${qcDir}
                mkdir -m 777 -p ${qcDir}
            else
                Error "~/qc/func directory already exists!!! Use -force option to overwrite outputs"
                exit 1; 
            fi
        else
            mkdir -m 777 -p ${qcDir}
        fi

        python ${FuNP}/functions/qc_func.py ${funcDir} ${qcDir} ${FuNP}

    elif [ "$ta" == "gd" ]; then
        gdDir=${dataDir}/gd
        qcDir=${dataDir}/qc/gd

        if [ -d ${qcDir} ]; then 
            if [ $force == TRUE ]; then
                Warning "output directory will be overwritten!!!"
                rm -rf ${qcDir}
                mkdir -m 777 -p ${qcDir}
            else
                Error "~/qc/gd directory already exists!!! Use -force option to overwrite outputs"
                exit 1; 
            fi
        else
            mkdir -m 777 -p ${qcDir}
        fi

        python ${FuNP}/functions/qc_gd.py ${gdDir} ${qcDir} ${FuNP}

    elif [ "$ta" == "mpc" ]; then
        mpcDir=${dataDir}/mpc
        strucDir=${dataDir}/struc
        qcDir=${dataDir}/qc/mpc

        if [ -d ${qcDir} ]; then 
            if [ $force == TRUE ]; then
                Warning "output directory will be overwritten!!!"
                rm -rf ${qcDir}
                mkdir -m 777 -p ${qcDir}
            else
                Error "~/qc/mpc directory already exists!!! Use -force option to overwrite outputs"
                exit 1; 
            fi
        else
            mkdir -m 777 -p ${qcDir}
        fi

        python ${FuNP}/functions/qc_mpc.py ${mpcDir} ${strucDir} ${qcDir} ${FuNP}

    fi
done


