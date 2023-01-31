# pixel_tracking
Codes for computing range and azimuth offsets from SAR data.

There are two main steps to calculate the pixel offsets.
1. Compute the relative offset (relative to each pixel size) for each subpatch (subpatch is the aggregation of a few pixels). 

"""
ALOS2_xcorr.csh  stem_ref  stem_rep  nx  ny

	stem_ref - stem of master.PRM  
	stem_rep - stem of slave.PRM   
	nx - number of offsets to compute in the range direction (~num_rng/4)  
	ny - number of offsets to compute in the azimuth direction (~num_az/6)
"""
The comment is not exactly correct when you specify nx and ny. Since the range size of Sentinel-1 pixel is 2.3m, and azimuth size is 13.6m, it's better to specify nx and ny so that the subpatch has a shape close to the square. 
The reference and repeat SLCs need to be aligned first.

2. Convert relative offsets to true offsets along range and azimuth directions. 
3. 
"""
Usage: extract_filter_shift.csh  master.PRM  align.dat filter_size
"""

align.dat is the xcorr output from the first step. 
This part of theory can be traced in the GMTSAR documents (Section A4 and Equation B12)

The first step is currently very inefficient because it was done in the spatial domain. You'd better use cut_slc to cut the SLC in order to speed it up. 
Actually there's one way to speed it up using FFT, but I never have time to finish it. I have a preliminary version of MATLAB xcorr and haven't tested it yet. The efficient xcorr that uses FFT is from this repo: https://www.mathworks.com/matlabcentral/fileexchange/18401-efficient-subpixel-image-registration-by-cross-correlation. I may finish testing that script and send it to you if I have time later.

