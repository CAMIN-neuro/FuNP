set dir [string range [GetSubjectDir 0] 0 [expr [string last "mri" [GetSubjectDir 0]] - 2] ]

LoadMainSurface 0 lh.white
LoadMainSurface 1 rh.white

SetCursor 0 128 128 128
SetOrientation 0
SetCursor 0 0 0 0

for { set slice 35 } { $slice <= 215 } { incr slice 1 } {

    SetSlice $slice
    RedrawScreen
    SaveRGB $dir/rgb/snaps/snapshot-wm-C-$slice.rgb

}

UnloadSurface 0
UnloadSurface 1




exit
