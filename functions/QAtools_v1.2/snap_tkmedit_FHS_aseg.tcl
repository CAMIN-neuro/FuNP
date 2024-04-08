SetZoomLevel 1
RedrawScreen
set outpth "$env(SUBJECTS_DIR)/QA_a100/$env(SUBJECT_NAME)/rgb/snaps"

##Asegs

LoadSegmentationVolume 0 aseg.mgz $env(FREESURFER_HOME)/FreeSurferColorLUT.txt
RedrawScreen

#coronal
SetOrientation 0
SetCursor 0 128 128 30
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor1.tiff
SetCursor 0 128 128 40
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor2.tiff
SetCursor 0 128 128 50
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor3.tiff
SetCursor 0 128 128 60
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor4.tiff
SetCursor 0 128 128 70
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor5.tiff
SetCursor 0 128 128 80
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor6.tiff
SetCursor 0 128 128 90
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor7.tiff
SetCursor 0 128 128 100
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor8.tiff
SetCursor 0 128 128 110
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor9.tiff
SetCursor 0 128 128 120
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor10.tiff
SetCursor 0 128 128 130
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor11.tiff
SetCursor 0 128 128 140
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor12.tiff
SetCursor 0 128 128 150
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor13.tiff
SetCursor 0 128 128 160
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor14.tiff
SetCursor 0 128 128 170
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor15.tiff
SetCursor 0 128 128 180
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor16.tiff
SetCursor 0 128 128 190
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor17.tiff
SetCursor 0 128 128 200
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor18.tiff
SetCursor 0 128 128 210
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor19.tiff
SetCursor 0 128 128 220
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor20.tiff

#sagittal
SetOrientation 2
SetCursor 0 160 128 128
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-templh.tiff
SetCursor 0 155 128 128
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-templh2.tiff
SetCursor 0 150 128 128
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-templh3.tiff
SetCursor 0 105 128 128
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-temprh3.tiff
SetCursor 0 100 128 128
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-temprh2.tiff
SetCursor 0 95 128 128
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-temprh.tiff

exit




