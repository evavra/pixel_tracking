#!/usr/bin/csh -f

if ($#argv != 4) then
  echo ""
  echo "ALOS2_xcorr.csh  stem_ref  stem_rep  nx  ny"
  echo ""
  echo "	stem_ref - stem of master.PRM  "
  echo "	stem_rep - stem of slave.PRM   "
  echo "	nx - number of offsets to compute in the range direction (~num_rng/4)  "
  echo "	ny - number of offsets to compute in the azimuth direction (~num_az/6) "
  exit 1
endif

set master = $1
set slave = $2
set nx = $3
set ny = $4

rm -f freq_xcorr.dat freq_alos2.dat

xcorr $master.PRM $slave.PRM -xsearch 64 -ysearch 64 -nx $nx -ny $ny -noshift
# awk '{print $4}' < freq_xcorr.dat > tmp.dat
# set amedian = `sort -n tmp.dat | awk ' { a[i++]=$1; } END { print a[int(i/2)]; }'`
# set amax = `echo $amedian | awk '{print $1+3}'`
# set amin = `echo $amedian | awk '{print $1-3}'`
awk '{if($4 > -1.1 && $4 < 1.1) print $0}' < freq_xcorr.dat > freq_alos2.dat

