#!/bin/tcsh -f

cd $SUBJECTS_DIR
setenv SUBJECT_NAME $1

if (-e $1/mri/brainmask.mgz) tkmedit $1 norm.mgz -tcl $RECON_CHECKER_SCRIPTS/snap_tkmedit_aseg.tcl

#SetVolumeBrightnessContrast volume brightness contrast
#      Sets the brightness and contrast values for a volume. volume should be 0 for the Main volume, and 1 #for the Aux volume. brightness should be a floating point number from 0 to 1 (0 is brighter than 1) and #contrast should be a floating point number from 0 to 30. 
