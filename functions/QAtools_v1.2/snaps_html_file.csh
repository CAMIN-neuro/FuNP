#!/bin/tcsh -f

set htmlfile = snapshots.html
echo '<html>\n<head>\n<style>body {font-family:Verdana;}</style>' > $htmlfile
echo "<title>Snapshots</title>" >> $htmlfile
echo '<center.,><font size="+2">'Snapshots'</font></center>' >> $htmlfile
echo '</head>\n<body bgcolor="#C0C0C0">\n<center>\n<TABLE>' >> $htmlfile
foreach f (*aseg-cor1.gif)
  echo '\n<TR>'  >> $htmlfile
  foreach reg (cor sag hor aseg-cor1 aseg-cor2 aseg-cor3 aseg-cor4 aseg-cor5 aseg-cor6 aseg-cor7 aseg-templh aseg-temprh cor1 cor2 cor3 cor4 cor5 cor6 cor7 templh temprh lh_lat lh_med lh_inf rh_lat rh_med rh_inf curv_lh_lat curv_lh_med curv_lh_inf curv_rh_lat curv_rh_med curv_rh_inf parc_lh_lat parc_lh_med parc_lh_inf parc_rh_lat parc_rh_med parc_rh_inf)
    echo '<TD ALIGN=CENTER VALIGN=BOTTOM>' >> $htmlfile
    echo '<IMG SRC="'${f:r:s/aseg-cor1//}${reg}.gif'" width="300" height="300">' >> $htmlfile
    echo '<div style="text-align: center">'"$f:r:s/aseg-cor1//</div></A></TD>" >> $htmlfile
  end
  echo '</TR>' >> $htmlfile
end
echo '</TR></TABLE>' >> $htmlfile
echo '</center></body>\n</html>' >> $htmlfile


