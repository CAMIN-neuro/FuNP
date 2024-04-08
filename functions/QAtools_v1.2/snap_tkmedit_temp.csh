#!/bin/tcsh -f

cd $SUBJECTS_DIR
setenv SUBJECT_NAME $1

if (-e $1/mri/orig.mgz) tkmedit $1 orig.mgz -tcl $RECON_CHECKER_SCRIPTS/snap_tkmedit_temp.tcl

if (-e $1/mri/T2.anat.mgz) tkmedit $1 T2.anat.mgz -tcl $RECON_CHECKER_SCRIPTS/snap_tkmedit_temp1.tcl

#if (-e $1/mri/PD.anat.mgz) tkmedit $1 PD.anat.mgz -tcl $RECON_CHECKER_SCRIPTS/snap_tkmedit_temp2.tcl

#SetVolumeBrightnessContrast volume brightness contrast
#      Sets the brightness and contrast values for a volume. volume should be 0 for the Main volume, and 1 #for the Aux volume. brightness should be a floating point number from 0 to 1 (0 is brighter than 1) and #contrast should be a floating point number from 0 to 30. 
