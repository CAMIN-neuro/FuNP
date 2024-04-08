#!/bin/tcsh -f

cd $SUBJECTS_DIR
setenv SUBJECT_NAME $1

#Snapshots of norm_diff_A with base norm
if (-e $1/mri/norm.mgz) then
	
	if (-e $1/mri/diff_norm_brainmask.mgz) then
	freeview -v ./$1/mri/norm.mgz ./$1/mri/diff_norm_brainmask.mgz:colormap=heat:opacity=1.0 -viewport sagittal -slice 128 128 128 -ss $SUBJECTS_DIR/QA/$1/rgb/snaps/$1_sag_norm_brainmask.tiff -quit
	freeview -v ./$1/mri/norm.mgz ./$1/mri/diff_norm_brainmask.mgz:colormap=heat:opacity=1.0 -viewport coronal -slice 128 128 128 -ss $SUBJECTS_DIR/QA/$1/rgb/snaps/$1_cor_norm_brainmask.tiff -quit
	freeview -v ./$1/mri/norm.mgz ./$1/mri/diff_norm_brainmask.mgz:colormap=heat:opacity=1.0 -viewport axial -slice 128 128 128 -ss $SUBJECTS_DIR/QA/$1/rgb/snaps/$1_hor_norm_brainmask.tiff -quit
	endif

endif

#SetVolumeBrightnessContrast volume brightness contrast
#      Sets the brightness and contrast values for a volume. volume should be 0 for the Main volume, and 1 #for the Aux volume. brightness should be a floating point number from 0 to 1 (0 is brighter than 1) and #contrast should be a floating point number from 0 to 30. 
