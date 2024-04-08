SetZoomLevel 2
RedrawScreen
set outpth "$env(SUBJECTS_DIR)/QA/$env(SUBJECT_NAME)/rgb/snaps"

#UnloadAllSurfaces

##Asegs

LoadSegmentationVolume 0 aseg.mgz $env(FREESURFER_HOME)/FreeSurferColorLUT.txt
SetSegmentationAlpha 0.2
SetVolumeBrightnessContrast norm.mgz 0.5 10
RedrawScreen

#coronal
SetOrientation 0
SetCursor 0 128 128 80
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor1.tiff
SetOrientation 0
SetCursor 0 128 128 85
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor2.tiff
SetOrientation 0
SetCursor 0 128 128 90
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor3.tiff
SetOrientation 0
SetCursor 0 128 128 95
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor4.tiff
SetOrientation 0
SetCursor 0 128 128 100
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor5.tiff
SetOrientation 0
SetCursor 0 128 128 105
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor6.tiff
SetOrientation 0
SetCursor 0 128 128 110
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor7.tiff
SetOrientation 0
SetCursor 0 128 128 115
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor8.tiff
SetOrientation 0
SetCursor 0 128 128 120
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor9.tiff
SetOrientation 0
SetCursor 0 128 128 125
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor10.tiff
SetOrientation 0
SetCursor 0 128 128 130
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor11.tiff
SetOrientation 0
SetCursor 0 128 128 135
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor12.tiff
SetOrientation 0
SetCursor 0 128 128 140
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor13.tiff
SetOrientation 0
SetCursor 0 128 128 145
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor14.tiff

#sagittal
SetCursor 0 161 128 100
SetOrientation 2
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-templh.tiff
SetCursor 0 95 128 100
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-temprh.tiff

exit




