#!/bin/tcsh -f

#source $SUBJECTS_DIR/scripts/subjects.csh

#cp -r $SUBJECTS_DIR/rgb/snaps/ $SUBJECTS_DIR/rgb/snaps_copy

cd $SUBJECTS_DIR/QA/$s/rgb/snaps
foreach f (*.rgb)
convert -scale 300x300 $f ${f:r}.gif
rm $f
end

./snaps_html_file.csh


