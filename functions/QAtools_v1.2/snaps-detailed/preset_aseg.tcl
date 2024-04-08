#DETAILED ASEG SNAPS
LoadSegmentationVolume norm.mgz aseg.mgz $fshome/FreeSurferColorLUT.txt

SetOrientation 0
SetCursor 0 0 0 0
SetSlice 128
RedrawScreen
SaveTIFF $subjdir/QA/$subject/rgb/snaps/snapshot-aseg-C-128.rgb
 
SetOrientation 1
SetSlice 128
RedrawScreen
SaveTIFF $subjdir/QA/$subject/rgb/snaps/snapshot-aseg-H-128.rgb

SetOrientation 2
SetSlice 124
RedrawScreen
SaveTIFF $subjdir/QA/$subject/rgb/snaps/snapshot-aseg-S-124.rgb
SetSlice 132
SaveTIFF $subjdir/QA/$subject/rgb/snaps/snapshot-aseg-S-132.rgb
