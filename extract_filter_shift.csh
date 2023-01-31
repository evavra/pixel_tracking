#!/usr/bin/csh -f
## This script is writtern by Zeyu Jin on 24th Oct. 2018
## used to generate the range/azimuth offset in geographical coordinates
## and filter the result with Guassian function
## modified by Zeyu Jin on 4th Dec. 2018
## add the scaling ratio by Earth radius and height.
## modified by Zeyu Jin on 2nd May. 2019

if ($#argv != 3) then
   echo ""
   echo "Usage: extract_filter_shift.csh  master.PRM  align.dat filter_size" 
   echo ""
   exit 1
endif

# delete previous results
rm -f gmt.* *_tmp.grd 
rm -f rng_offset*.grd azi_offset*.grd
rm -f rng_off_filt*.grd azi_off_filt*.grd
rm -f raln.grd ralt.grd

set master = $1
set xcorr_data = $2
set filter_size = $3

awk '{if ($2>-1.1 && $2<1.1) print $1,$3,$2,$5}' $xcorr_data > rshift_SNR.xyz
awk '{if ($4>-1.1 && $4<1.1) print $1,$3,$4,$5}' $xcorr_data > ashift_SNR.xyz

set nx = `awk '{print $1}' rshift_SNR.xyz | sort -n | uniq | wc -l`
set ny = `awk '{print $2}' rshift_SNR.xyz | sort -n | uniq | wc -l`
echo $nx $ny

# # project offset map from range/azimuth coordinates into lon/lat coordinates
# proj_ra2ll_ascii.csh trans.dat rshift.xyz roff_ll.xyz
# proj_ra2ll_ascii.csh trans.dat ashift.xyz aoff_ll.xyz

# set master = 150727_cut.PRM 
set PRF = `grep PRF $master |awk -F"=" '{print $2}'`
set SC_vel = `grep SC_vel $master|awk -F"=" '{print $2}'`
echo "Ground velocity: "$SC_vel
# set azi_size = `echo $SC_vel $PRF|awk '{printf "%10.5f",$1/$2}'`
# echo "Azimuth pixel size: "$azi_size
set Re = `grep earth_radius $master | awk -F"=" '{print $2}'`
set H = `grep SC_height $master | awk -F"=" '{print $2}'`
set ratio = `echo $Re $H | awk '{printf "%10.5f", sqrt($1/($1+$2))}'`  # from GMTSAR tutorial
# echo "Scaling factor: "$ratio
set azi_size = `echo $SC_vel $PRF $ratio | awk '{printf "%10.5f",$1/$2*$3}'`
echo "Azimuth pixel size: $azi_size (m)"

set rng_samp_rate = `grep rng_samp_rate $master | awk -F"=" '{print $2}'`
set c_light = "299792458"
set rng_size = `echo $c_light $rng_samp_rate | awk '{printf "%10.5f", $1/$2/2}'`
echo "Range pixel size: $rng_size (m)"

set xmin = `gmt gmtinfo rshift_SNR.xyz -C | awk '{print $1}'`
set xmax = `gmt gmtinfo rshift_SNR.xyz -C | awk '{print $2}'`
set ymin = `gmt gmtinfo rshift_SNR.xyz -C | awk '{print $3}'`
set ymax = `gmt gmtinfo rshift_SNR.xyz -C | awk '{print $4}'`
set xinc = `echo $xmax $xmin $nx |awk '{printf "%12.5f", ($1-$2)/($3-1)}'`
set yinc = `echo $ymax $ymin $ny |awk '{printf "%12.5f", ($1-$2)/($3-1)}'`
# set xinc = `echo $xinc | awk '{print $1*4}'`
# set yinc = `echo $yinc | awk '{print $1*4}'`

# Construct weighted median values for each block
gmt blockmedian rshift_SNR.xyz -R$xmin/$xmax/$ymin/$ymax -I$xinc/$yinc -Wi | awk '{print $1,$2,$3}' > rshift.xyz
gmt xyz2grd rshift.xyz -R$xmin/$xmax/$ymin/$ymax -I$xinc/$yinc -r -Grshift_tmp.grd
gmt grdmath rshift_tmp.grd $rng_size MUL = rng_offset.grd 

gmt blockmedian ashift_SNR.xyz -R$xmin/$xmax/$ymin/$ymax -I$xinc/$yinc -Wi | awk '{print $1,$2,$3}' > ashift.xyz
gmt xyz2grd ashift.xyz -R$xmin/$xmax/$ymin/$ymax -I$xinc/$yinc -r -Gashift_tmp.grd
gmt grdmath ashift_tmp.grd $azi_size MUL = azi_offset.grd
rm -f rshift_tmp.grd ashift_tmp.grd 

# project offset map from range/azimuth coordinates into lon/lat coordinates
if (! -f trans.dat) then
   echo "No trans.dat exists! "
   exit 1
endif
# proj_ra2ll_ascii.csh trans.dat rshift.xyz roff_ll.xyz
# proj_ra2ll_ascii.csh trans.dat ashift.xyz aoff_ll.xyz
# set xmin2 = `gmt gmtinfo roff_ll.xyz -C |awk '{print $1}'`
# set xmax2 = `gmt gmtinfo roff_ll.xyz -C |awk '{print $2}'`
# set ymin2 = `gmt gmtinfo roff_ll.xyz -C |awk '{print $3}'`
# set ymax2 = `gmt gmtinfo roff_ll.xyz -C |awk '{print $4}'`
# set xinc2 = `echo $xmax2 $xmin2 $nx |awk '{printf "%12.5f", ($1-$2)/($3-1)}'`
# set yinc2 = `echo $ymax2 $ymin2 $ny |awk '{printf "%12.5f", ($1-$2)/($3-1)}'`
# 
# gmt xyz2grd roff_ll.xyz -R$xmin2/$xmax2/$ymin2/$ymax2 -I$xinc2/$yinc2 -r -fg -Grshift_tmp.grd
# gmt grdmath rshift_tmp.grd $rng_size MUL = rng_offset_ll.grd
# gmt xyz2grd aoff_ll.xyz -R$xmin2/$xmax2/$ymin2/$ymax2 -I$xinc2/$yinc2 -r -fg -Gashift_tmp.grd 
# gmt grdmath ashift_tmp.grd $azi_size MUL = azi_offset_ll.grd
# rm -f rshift_tmp.grd ashift_tmp.grd 

# copy the gauss_* file
proj_ra2ll_new.csh trans.dat rng_offset.grd rng_offset_ll.grd
proj_ra2ll_new.csh trans.dat azi_offset.grd azi_offset_ll.grd

# filter the grid with gaussian function
# the aperture is twice of largest gird interval
# solve the bug of "sort", with the numerical order
set range = `awk '{print $1}' rshift.xyz | sort -n | uniq`
set azimuth = `awk '{print $2}' rshift.xyz | sort -n | uniq`
@ rinv = $range[2] - $range[1]
@ ainv = $azimuth[2] - $azimuth[1]
@ filtx = $rinv * $filter_size
@ filty = $ainv * $filter_size
# echo $rinv $ainv
# if ($rinv < $ainv) then
#    @ filt_wavelength = $ainv * 15
#    echo $filt_wavelength
# else
#    @ filt_wavelength = $rinv * 15
#    echo $filt_wavelength
# endif
echo "filter size in range: "$filtx
echo "filter size in azimuth: "$filty
# set filt_width = `echo $filt_wavelength | awk '{printf "%.3f",$1/1000}'`
gmt grdfilter azi_offset.grd -Gazi_off_filt.grd -D0 -Fm$filtx/$filty -Ni
gmt grdfilter rng_offset.grd -Grng_off_filt.grd -D0 -Fm$filtx/$filty -Ni

proj_ra2ll_new.csh trans.dat azi_off_filt.grd azi_off_filt_ll.grd
proj_ra2ll_new.csh trans.dat rng_off_filt.grd rng_off_filt_ll.grd

rm -f *.xyz
# rm -f azi_offset.grd  rng_offset.grd
rm -f azi_off_filt.grd  rng_off_filt.grd
# gmt grdmath rng_ll_filt.grd rng_ll_filt.grd MEAN SUB = tmp1.grd
# gmt grdmath azi_ll_filt.grd azi_ll_filt.grd MEAN SUB = tmp2.grd
# mv tmp1.grd rng_ll_filt.grd
# mv tmp2.grd azi_ll_filt.grd
# mv azi_ll.grd azi_ll_filt.grd
# rm rng_ll.grd azi_ll.grd

