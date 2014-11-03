function runLengthStat = findRunLengthProp(cubeImg, bitsperpixel, mask)

addpath('./FEATURES/GLRL/');

%  1) Short Run Emphasis (SRE)
%  2) Long Run Emphasis (LRE)
%  3) Gray-Level Nonuniformity (GLN)
%  4) Run Length Nonuniformity (RLN)
%  5) Run Percentage (RP)
%  6) Low Gray-Level Run Emphasis (LGRE)
%  7) High Gray-Level Run Emphasis (HGRE)
%  8) Short Run Low Gray-Level Emphasis (SRLGE)
%  9) Short Run High Gray-Level Emphasis (SRHGE)
%  10) Long Run Low Gray-Level Emphasis (LRLGE)
%  11) Long Run High Gray-Level Emphasis (LRHGE)

% compute 3D Run-length matric
SI = round(imlincomb(bitsperpixel-1,cubeImg,1,'double'));
% 1. (1,0,0)
oneGLRLM{1} = rle_0(SI,bitsperpixel);
% 2. (1,1,0)
seq = [];
for z = 1:size(SI,3)
    seq = horzcat(seq,zigzag(SI(:,:,z)));
end
oneGLRLM{2}  = rle_45(seq,bitsperpixel);
% 3. (0,1,0)
oneGLRLM{3} = rle_0(SI,bitsperpixel,1);
% 4. (-1,1,0)
seq = [];
for z = 1:size(SI,3)
    seq = horzcat(seq,zigzag(fliplr(SI(:,:,z))));
end
oneGLRLM{4} = rle_45(seq,bitsperpixel);
% 5. (1,0,1)
SIreorder = permute(SI, [1 3 2]);
seq = [];
for z = 1:size(SIreorder,3)
    seq = horzcat(seq,zigzag(SIreorder(:,:,z)));
end
oneGLRLM{5}  = rle_45(seq,bitsperpixel);
% 6. (-1,0,1)
seq = [];
for z = 1:size(SIreorder,3)
    seq = horzcat(seq,zigzag(fliplr(SIreorder(:,:,z))));
end
oneGLRLM{6} = rle_45(seq,bitsperpixel);
% 7. (0,1,1)
SIreorder = permute(SI, [3 2 1]);
seq = [];
for z = 1:size(SIreorder,3)
    seq = horzcat(seq,zigzag(SIreorder(:,:,z)));
end
oneGLRLM{7}  = rle_45(seq,bitsperpixel);
% 8. (-1,0,1)
seq = [];
for z = 1:size(SIreorder,3)
    seq = horzcat(seq,zigzag(fliplr(SIreorder(:,:,z))));
end
oneGLRLM{8} = rle_45(seq,bitsperpixel);
% 9. (0,0,1)
oneGLRLM{9} = rle_0(SIreorder,bitsperpixel,1);
% state property
stats = grayrlprops(oneGLRLM);
stats(isnan(stats)) = 0;

% average value
runLengthStat = mean(stats);