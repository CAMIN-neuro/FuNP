#open_window
set outpth "$env(SUBJECTS_DIR)/QA_a100/$env(SUBJECT_NAME)/tiff/snaps"
set lablpth "$env(SUBJECTS_DIR)/$env(SUBJECT_NAME)/label"
do_lighting_model 0.4 0.0 0.6 0.2 0.7
redraw

##Inflated
make_lateral_view
redraw
set tiff "$outpth/$env(SUBJECT_NAME)_${hemi}_lat.tiff"
save_tiff $tiff
rotate_brain_x 90
redraw
set tiff "$outpth/$env(SUBJECT_NAME)_${hemi}_inf.tiff"
save_tiff $tiff
make_lateral_view
rotate_brain_y 180
redraw
set tiff "$outpth/$env(SUBJECT_NAME)_${hemi}_med.tiff"
save_tiff $tiff

##curv

read_binary_curv
make_lateral_view
redraw
set tiff "$outpth/$env(SUBJECT_NAME)_curv_${hemi}_lat.tiff"
save_tiff $tiff
rotate_brain_x 90
redraw
set tiff "$outpth/$env(SUBJECT_NAME)_curv_${hemi}_inf.tiff"
save_tiff $tiff
make_lateral_view
rotate_brain_y 180
redraw
set tiff "$outpth/$env(SUBJECT_NAME)_curv_${hemi}_med.tiff"
save_tiff $tiff

##parcellations desikan-killiany 
surf pial
labl_import_annotation "$lablpth/$hemi.aparc.annot"
make_lateral_view
redraw

set tiff "$outpth/$env(SUBJECT_NAME)_parc_${hemi}_lat.tiff"
save_tiff $tiff
rotate_brain_x 90
redraw
set tiff "$outpth/$env(SUBJECT_NAME)_parc_${hemi}_inf.tiff"
save_tiff $tiff
make_lateral_view
rotate_brain_y 180
redraw
set tiff "$outpth/$env(SUBJECT_NAME)_parc_${hemi}_med.tiff"
save_tiff $tiff

##parcellations destrieux
surf pial
labl_import_annotation "$lablpth/$hemi.aparc.a2009s.annot"
make_lateral_view
redraw

set tiff "$outpth/$env(SUBJECT_NAME)_parc2009_${hemi}_lat.tiff"
save_tiff $tiff
rotate_brain_x 90
redraw
set tiff "$outpth/$env(SUBJECT_NAME)_parc2009_${hemi}_inf.tiff"
save_tiff $tiff
make_lateral_view
rotate_brain_y 180
redraw
set tiff "$outpth/$env(SUBJECT_NAME)_parc2009_${hemi}_med.tiff"
save_tiff $tiff
exit
