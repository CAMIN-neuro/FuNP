SetZoomLevel 1
RedrawScreen
set outpth "$env(SUBJECTS_DIR)/QA/$env(SUBJECT_NAME)/rgb/snaps"

##Talairachs

LoadVolumeDisplayTransform 0 talairach.xfm

#coronal
SetCursor 0 128 128 128
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_cor.rgb

#sagittal
SetOrientation 2
SetCursor 0 128 128 128
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_sag.rgb

#horizontal
SetOrientation 1
SetCursor 0 128 128 128
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_hor.rgb

UnloadVolumeDisplayTransform 0

##Surfaces

LoadMainSurface 0 lh.white
LoadMainSurface 1 rh.white
SetSurfaceLineWidth 0 0 2
SetSurfaceLineWidth 0 2 2
SetSurfaceLineWidth 1 0 2
SetSurfaceLineWidth 1 2 2
SetDisplayFlag 5 0
RedrawScreen

#coronal
SetOrientation 0
SetCursor 0 128 128 128
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_cor1.rgb
SetOrientation 0
SetCursor 0 128 128 135
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_cor2.rgb
SetCursor 0 128 128 150
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_cor3.rgb
SetCursor 0 128 128 180
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_cor4.rgb
SetCursor 0 128 128 60
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_cor5.rgb
SetCursor 0 128 128 80
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_cor6.rgb
SetCursor 0 128 128 120
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_cor7.rgb

#sagittal
SetOrientation 2
SetCursor 0 165 128 128
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_templh.rgb
SetCursor 0 95 128 128
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_temprh.rgb

UnloadAllSurfaces

##Asegs

LoadSegmentationVolume 0 aseg.mgz $env(FREESURFER_HOME)/FreeSurferColorLUT.txt
RedrawScreen

#coronal
SetOrientation 0
SetCursor 0 128 128 128
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor1.rgb
SetOrientation 0
SetCursor 0 128 128 135
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor2.rgb
SetCursor 0 128 128 150
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor3.rgb
SetCursor 0 128 128 180
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor4.rgb
SetCursor 0 128 128 60
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor5.rgb
SetCursor 0 128 128 80
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor6.rgb
SetCursor 0 128 128 120
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor7.rgb

#sagittal
SetOrientation 2
SetCursor 0 165 128 128
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-templh.rgb
SetCursor 0 95 128 128
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-temprh.rgb

exit




