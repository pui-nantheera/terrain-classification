function [overlay,intolay,map,intmap, gsurf] = runseg2(Im,Levels,t1,t2,t3,hminfactor,dellowband,merge, filterNoErode)
% Segments Image (Im) as a colour image if it is colour RGB image or in
% gray scale only if it is a gray image (one plane only).  All images
% should be in the range 0 - 255

Im_RGB = Im;
Im = mean(Im_RGB,3);

% wavelet transform the images
[lowcoef,highcoef] = dtwavexfm2(double(Im),Levels,'antonini','qshift_06');
if( dellowband )  
    lowcoef = mean2(lowcoef);
    imr = dtwaveifm2(lowcoef,highcoef,'antonini','qshift_06');
else
    imr = Im;
end

%segment the images
[overlay,intolay,map,intmap, gsurf]=cmssegmm(imr, Im, highcoef, Levels,t1,t2, t3,hminfactor,merge, filterNoErode);


