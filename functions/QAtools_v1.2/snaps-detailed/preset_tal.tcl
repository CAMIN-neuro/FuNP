#DETAILED TAL SNAPS
LoadVolumeDisplayTransform 0 talairach.xfm

SetOrientation 0
SetSlice 128
RedrawScreen
SaveTIFF $subjdir/QA/$subject/rgb/snaps/snapshot-talairach-C-128.rgb

SetOrientation 1
SetSlice 128
RedrawScreen
SaveTIFF $subjdir/QA/$subject/rgb/snaps/snapshot-talairach-H-128.rgb

SetOrientation 2
SetSlice 124
RedrawScreen
SaveTIFF $subjdir/QA/$subject/rgb/snaps/snapshot-talairach-S-124.rgb
SetSlice 132
SaveTIFF $subjdir/QA/$subject/rgb/snaps/snapshot-talairach-S-132.rgb

UnloadVolumeDisplayTransform 0
