#DETAILED WM SNAPS
LoadMainSurface 0 lh.white
LoadMainSurface 1 rh.white

SetCursor 0 128 128 128
SetOrientation 0
SetCursor 0 0 0 0

for { set slice 35 } { $slice <= 215 } { incr slice 1 } {

    SetSlice $slice
    RedrawScreen
    SaveTIFF $subjdir/QA/$subject/rgb/snaps/snapshot-wm-C-$slice.rgb

}

UnloadSurface 0
UnloadSurface 1
