#!/bin/tcsh -f

cd $SUBJECTS_DIR
setenv SUBJECT_NAME $1

  foreach h (rh lh)
        tksurfer $1 $h inflated -tcl $RECON_CHECKER_SCRIPTS/snap_tksurfer.tcl
  end

