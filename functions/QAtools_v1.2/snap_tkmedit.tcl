SetZoomLevel 1
RedrawScreen
set outpth "$env(SUBJECTS_DIR)/QA/$env(SUBJECT_NAME)/rgb/snaps"

##Talairachs

LoadVolumeDisplayTransform 0 talairach.xfm

#coronal
SetCursor 0 128 128 128
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_cor.tiff

#sagittal
SetOrientation 2
SetCursor 0 128 128 128
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_sag.tiff

#horizontal
SetOrientation 1
SetCursor 0 128 128 128
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_hor.tiff

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
SaveTIFF $outpth/$env(SUBJECT_NAME)_cor1.tiff
SetOrientation 0
SetCursor 0 128 128 135
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_cor2.tiff
SetCursor 0 128 128 150
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_cor3.tiff
SetCursor 0 128 128 180
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_cor4.tiff
SetCursor 0 128 128 60
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_cor5.tiff
SetCursor 0 128 128 80
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_cor6.tiff
SetCursor 0 128 128 120
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_cor7.tiff

#sagittal
SetOrientation 2
SetCursor 0 165 128 128
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_templh.tiff
SetCursor 0 95 128 128
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_temprh.tiff

UnloadAllSurfaces

##Asegs

LoadSegmentationVolume 0 aseg.mgz $env(FREESURFER_HOME)/FreeSurferColorLUT.txt
RedrawScreen

#coronal
SetOrientation 0
SetCursor 0 128 128 128
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor1.tiff
SetOrientation 0
SetCursor 0 128 128 135
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor2.tiff
SetCursor 0 128 128 150
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor3.tiff
SetCursor 0 128 128 180
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor4.tiff
SetCursor 0 128 128 60
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor5.tiff
SetCursor 0 128 128 80
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor6.tiff
SetCursor 0 128 128 120
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-cor7.tiff

#sagittal
SetOrientation 2
SetCursor 0 165 128 128
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-templh.tiff
SetCursor 0 95 128 128
RedrawScreen
SaveTIFF $outpth/$env(SUBJECT_NAME)_aseg-temprh.tiff

exit




