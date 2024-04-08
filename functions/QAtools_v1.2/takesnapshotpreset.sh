#!/bin/bash
#last update 7/6/06
#last update 8/25/11

debug=0
tal=0
skull=0
wm=0
aseg=0
customhtml=0
startslice=35
endslice=215

USAGE="
USAGE: takesnapshotpreset.sh [options...] subject(s)
Options:
    
    -t: talairach preset
    -s: skull strip preset
    -w: white matter preset
    -a: aseg preset
    -c: custom html index file
"

while 
  getopts tswadc opt
do  
   case "$opt"
   in
   d) debug=1;;
   t) tal=1;;
   s) skull=1;;
   w) wm=1;;
   a) aseg=1;;
   c) customhtml=1;;
   \?)  echo "$USAGE"
         exit 1;;
   esac
done

if [ ! $OPTIND -eq 0 ]; then
    shift $(($OPTIND - 1 ))
fi

if [ -z "$1" ]; then
    echo "$USAGE"
    exit 1
fi

subjlist="$1"
snaps_temp="$SUBJECTS_DIR/QA/snap_preset_tmp.tcl"

#create and assemble script
echo -e "set subject [GetSubjectName 0]" > $snaps_temp
echo -e "global env" >> $snaps_temp
echo -e "set subjdir \$env(SUBJECTS_DIR)" >> $snaps_temp
echo -e "set fshome \$env(FREESURFER_HOME)" >> $snaps_temp

filename=""

if [ $skull == 1 ]; then
    cat $RECON_CHECKER_SCRIPTS/snaps-detailed/preset_skull.tcl >> $snaps_temp
fi

if [ $tal == 1 ]; then
    cat $RECON_CHECKER_SCRIPTS/snaps-detailed/preset_tal.tcl >> $snaps_temp
fi

if [ $wm == 1 ]; then
    cat $RECON_CHECKER_SCRIPTS/snaps-detailed/preset_wm.tcl >> $snaps_temp
fi

if [ $aseg == 1 ]; then
    cat $RECON_CHECKER_SCRIPTS/snaps-detailed/preset_aseg.tcl >> $snaps_temp
fi

echo "exit 0" >> $snaps_temp

for s in $subjlist
do
    tkmedit $s brainmask.mgz -aux T1.mgz -tcl $snaps_temp 

    rm $snaps_temp
	
    echo "Converting files to .gif ..."
    filelist=$( ls -1 $SUBJECTS_DIR/QA/$s/rgb/snaps | grep ".*\.rgb" | cut -d "." -f 1 )
    for f in $filelist
    do
        convert $SUBJECTS_DIR/QA/$s/rgb/snaps/${f}.rgb $SUBJECTS_DIR/QA/$s/rgb/snaps/${f}.gif
	rm $SUBJECTS_DIR/QA/$s/rgb/snaps/${f}.rgb
    done
    echo "Done converting files."

if [ $skull == 1 ]; then
    filename="$SUBJECTS_DIR/QA/$s/rgb/snaps/$s-skullstrip-QA.html"
    QAname="Skullstrip"
    doc=`date`
    type="skull"
    echo "<html>
    <head>
	<title>$s $QAname QA</title>
    </head>
    <body> <p>$s $QAname QA (created on $doc using brainmask.mgz)</p>" > $filename

    #the following while loop puts the snapshots in numerical order
    #ls would by default order them in an unconventional fashion
    tmplist=`ls -1 $SUBJECTS_DIR/QA/$s/rgb/snaps/ | grep "snapshot-$type-C-[0-9][0-9]*.gif"`
    snaplist=""
    num=$startslice

    while [ $num -le $endslice ]; do
	snapname=`echo $tmplist | grep -o "snapshot-$type-C-$num.gif" | sort -d`
	snaplist="$snaplist $snapname"
	num=$(($num + 1))
    done

    #insert .gif files into html file with captions
    for snap in $snaplist; do
	snapnum=`echo $snap | grep -o "[0-9][0-9]*"`
	echo -e "   <img src=\"$snap\" />
   <p>Slice $snapnum</p>
   <br />" >> $filename
    done

    echo "   </body>
</html>" >> $filename
fi

if [ $tal == 1 ]; then
    filename="$SUBJECTS_DIR/QA/$s/rgb/snaps/$s-talairach-QA.html"
    doc=`date`
	echo "<html>
    <head>
       <title>$s Talairach QA</title>
    </head>
    <body> <p>$s Talairach QA (created on $doc using talairach.xfm)</p>

    <img src=\"$SUBJECTS_DIR/QA/$s/rgb/snaps/snapshot-talairach-C-128.gif\" /><br />
    <p>Coronal View</p>
    <br />
    <img src=\"$SUBJECTS_DIR/QA/$s/rgb/snaps/snapshot-talairach-H-128.gif\" /><br />
    <p>Horizontal View</p>
    <br />
    <img src=\"$SUBJECTS_DIR/QA/$s/rgb/snaps/snapshot-talairach-S-124.gif\" /><br />
    <p>Parasagittal View - Slice 124</p>
    <br />
    <img src=\"$SUBJECTS_DIR/QA/$s/rgb/snaps/snapshot-talairach-S-132.gif\" /><br />
    <p>Parasagittal View - Slice 132</p>

    <br />

    </body>
</html>" > $filename
fi

if [ $wm == 1 ]; then
    filename="$SUBJECTS_DIR/QA/$s/rgb/snaps/$s-whitematter-QA.html"
    QAname="White Matter"
    doc=`date`
    type="wm"
    echo "<html>
    <head>
	<title>$s $QAname QA</title>
    </head>
    <body> <p>$s $QAname QA (created on $doc using lh.white and rh.white)</p>" > $filename

    #the following while loop puts the snapshots in numerical order
    #ls would by default order them in an unconventional fashion
    tmplist=`ls -1 $SUBJECTS_DIR/QA/$s/rgb/snaps | grep "snapshot-$type-C-[0-9][0-9]*.gif"`
    snaplist=""
    num=$startslice

    while [ $num -le $endslice ]; do
	snapname=`echo $tmplist | grep -o "snapshot-$type-C-$num.gif" | sort -d`
	snaplist="$snaplist $snapname"
	num=$(($num + 1))
    done

    #insert .gif files into html file with captions
    for snap in $snaplist; do
	snapnum=`echo $snap | grep -o "[0-9][0-9]*"`
	echo -e "   <img src=\"$snap\" />
   <p>Slice $snapnum</p>
   <br />" >> $filename

    done

    echo "</body>
</html>" >> $filename
fi

if [ $aseg == 1 ]; then
    filename="$SUBJECTS_DIR/QA/$s/rgb/snaps/$s-aseg-QA.html"
    doc=`date`
    echo "<html>
    <head>
       <title>$s Automatic Segmentation QA</title>
    </head>
    <body><p>$s Automatic Segmentation QA (created on $doc using aseg.mgz)</p>

    <img src=\"$SUBJECTS_DIR/QA/$s/rgb/snaps/snapshot-aseg-C-128.gif\" /><br />
    <p>Coronal View</p>
    <br />
    <img src=\"$SUBJECTS_DIR/QA/$s/rgb/snaps/snapshot-aseg-H-128.gif\" /><br />
    <p>Horizontal View</p>
    <br />
    <img src=\"$SUBJECTS_DIR/QA/$s/rgb/snaps/snapshot-aseg-S-124.gif\" /><br />
    <p>Parasagittal View - Slice 124</p>
    <br />
    <img src=\"$SUBJECTS_DIR/QA/$s/rgb/snaps/snapshot-aseg-S-132.gif\" /><br />
    <p>Parasagittal View - Slice 132</p>

    <br />

    </body>
</html>" > $filename
fi

done

    
