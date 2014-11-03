function [overlay,intolay,map,intmap, gsurf] = runseg(Im, t1,t2,hminfactor,dellowband,merge)
%% Segments Image (Im) as a colour image if it is colour RGB image or in
%% gray scale only if it is a gray image (one plane only).  All images
%% should be in the range 0 - 255

Levels = 1;

Im_RGB = Im;

%Im = rgb2ycbcr(Im_RGB);
Im = sum(Im_RGB,3);
%Im = Im(:,:,1);
ImSize = size(Im);
highcoef = cell(Levels, 1); %% removed for single im segmentation
% wavelet transform the images
%for a = 1:ImSize(3)  
    [lowcoef,highcoef] = dtwavexfm2(double(Im),Levels,'antonini','qshift_06');
    %end;  

if( dellowband )  
    lowcoef = mean2(lowcoef);
    %lowcoef(:,:,2) = mean2(lowcoef(:,:,2));
    %lowcoef(:,:,3) = mean2(lowcoef(:,:,3));
    %lowcoef(:,:,1) = medfilt2(lowcoef(:,:,1), [7 7]);
    %lowcoef(:,:,2) = medfilt2(lowcoef(:,:,2), [7 7]);
    %lowcoef(:,:,3) = medfilt2(lowcoef(:,:,3), [7 7]);

    % either mean or zero, it doesnt seem to make a difference
    %lowcoef(:,:,1) = 0;
    %lowcoef(:,:,2) = 0;
    %lowcoef(:,:,3) = 0;

    %highcoef{4,1} = zeros(size(highcoef{4,1}));
    %highcoef{4,2} = zeros(size(highcoef{4,2}));
    %highcoef{4,3} = zeros(size(highcoef{4,3}));

    imr = dtwaveifm2(lowcoef,highcoef,'antonini','qshift_06');
    %figure,imshow(ycbcr2rgb(uint8(imr)));
    %Im = imr;
else
    imr = Im;
end

%segment the images
[overlay,intolay,map,intmap, gsurf]=cmssegmm(imr, Im, highcoef, 'joint', Levels,t1,t2,hminfactor,merge);
for a = 1:3  
    overlay(:,:,a) = max(double(Im_RGB(:,:,a)), (map==0)*255);
    intolay(:,:,a) = max(double(Im_RGB(:,:,a)), (intmap==0)*255);
end;  
figure,imshow(uint8(overlay))
figure,imshow(uint8(intmap))
imwrite(uint8(overlay), 'working/16 overlay.png', 'png');
imwrite(uint8(intolay), 'working/17 pre speclust overlay.png', 'png');
imwrite(uint8(intmap), 'working/19 pre sc map.png', 'png');
imwrite(uint8(map), 'working/18 map.png', 'png');

