##### Example script #####
FuNP="/data/camin/bypark/FuNP"
dataDir="/data/camin/bypark/FuNP/HCP_unproc/100206/unprocessed/3T"
outDir="/data/camin/bypark/FuNP/HCP_proc"
procDir="/data/camin/bypark/TempProcessing"

# Structural processing
${FuNP}/funp -struc -t1 ${dataDir}/T1w_MPR1/100206_3T_T1w_MPR1.nii.gz -out ${outDir} -threads 2 -procDir ${procDir}

# Diffusion processing
mrconvert ${dataDir}/Diffusion/100206_3T_DWI_dir95_RL.nii.gz -fslgrad ${dataDir}/Diffusion/100206_3T_DWI_dir95_RL.bvec ${dataDir}/Diffusion/100206_3T_DWI_dir95_RL.bval ${dataDir}/Diffusion/dwi.mif
dwiextract ${dataDir}/Diffusion/dwi.mif ${dataDir}/Diffusion/dwi_b0.mif -bzero
mrconvert ${dataDir}/Diffusion/dwi_b0.mif ${dataDir}/Diffusion/100206_3T_DWI_dir95_LR_rev.nii.gz

${FuNP}/funp -dwi -dwi_main ${dataDir}/Diffusion/100206_3T_DWI_dir95_LR.nii.gz -dwi_bval ${dataDir}/Diffusion/100206_3T_DWI_dir95_LR.bval -dwi_bvec ${dataDir}/Diffusion/100206_3T_DWI_dir95_LR.bvec -pe_dir LR -strucDir ${outDir}/struc -readout 0.111542 -out ${outDir} -threads 10 -procDir ${procDir}

# Functional processing
fslroi ${dataDir}/rfMRI_REST1_RL/100206_3T_rfMRI_REST1_RL.nii.gz ${dataDir}/rfMRI_REST1_RL/100206_3T_rfMRI_REST1_LR_rev.nii.gz 0 5

${FuNP}/funp -func -func_main ${dataDir}/rfMRI_REST1_LR/100206_3T_rfMRI_REST1_LR.nii.gz -wbDir ${outDir}/struc/wb_adjust -fix_train HCP_hp2000 -func_rev ${dataDir}/rfMRI_REST1_RL/100206_3T_rfMRI_REST1_LR_rev.nii.gz -readout 0.05162 -out ${outDir} -threads 10 -procDir ${procDir}

# Geodesic distance processing
${FuNP}/funp -gd -wbDir ${outDir}/struc/wb_adjust -out ${outDir} -threads 10 -procDir ${procDir}

# Microstructural processing
${FuNP}/funp -mpc -t1 ${dataDir}/T1w_MPR1/100206_3T_T1w_MPR1.nii.gz -t2 ${dataDir}/T2w_SPC1/100206_3T_T2w_SPC1.nii.gz -strucDir ${outDir}/struc -out ${outDir} -threads 10 -procDir ${procDir}
${FuNP}/funp -mpc -t1 ${dataDir}/T1w_restore_brain.nii.gz -strucDir ${outDir}/struc -out ${outDir} -threads 10 -procDir ${procDir}

# Quality control
${FuNP}/funp -qc -type func -dataDir ${outDir} -out ${outDir} -force
