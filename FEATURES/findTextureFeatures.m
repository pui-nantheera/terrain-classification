function features = findTextureFeatures(cubeImg, lowcoef, highcoef, bitsperpixel, listfeature, mask, withphase)

if (nargin<6) || (isempty(mask))
    mask = ones(size(cubeImg));
end
if nargin<5
    listfeature = 1:6;
end

if isempty(lowcoef) || isempty(highcoef) 
    % wavelet transform
    [lowcoef,highcoef] = dtwavexfm2(cubeImg,4,'antonini','qshift_06');
end

if sum(size(cubeImg)==1)>0
    addMat = (size(cubeImg)==1)*2 + 1;
    cubeImg = repmat(cubeImg, addMat);
end

if max(cubeImg(:))>1
    cubeImg = cubeImg/255;
    cubeImg(cubeImg>1) = 1;
end
if nargin < 7
    withphase = 1;
end
% -------------------------------------------------------------------------
% I. Intensity level distribution
% -------------------------------------------------------------------------
if sum(listfeature==1)
    
%     % 1) mean
%     meanCube = mean(cubeImg(mask(:)>0));
%     % 2) variance
%     varCube = var(cubeImg(mask(:)>0));
%     % 3) skewness
%     skewCube = skewness(cubeImg(mask(:)>0));
%     % 4) kurtosis
%     kurtCube = kurtosis(cubeImg(mask(:)>0));
%     % 5) entropy
%     entropyCube = entropy(cubeImg(mask(:)>0));

    intensityFeatures = findIntensityDistFeatures_mex(cubeImg(mask(:)>0));
   
else
    meanCube = [];
    varCube = [];
    skewCube = [];
    kurtCube = [];
    entropyCube = [];
end

% -------------------------------------------------------------------------
% II. Run length measures
% -------------------------------------------------------------------------
if sum(listfeature==2)
    
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
    runLengthStat = findRunLengthProp(cubeImg, bitsperpixel, mask);
else
    runLengthStat = [];
end

% -------------------------------------------------------------------------
% III. Co-occurrence matrix
% -------------------------------------------------------------------------
if sum(listfeature==3)
    
    % 1) angular second moment or energy
    % 2) correlation
    % 3) contrast or inertia
    % 4) entropy
    % 5) Cluster Shade
    % 6) inverse difference moment
    % 7) Homogeneity
    glcmStat = findGLCMProp(cubeImg, mask);
else
    glcmStat = [];
end

% -------------------------------------------------------------------------
% IV. Wavelet transform
% -------------------------------------------------------------------------
if sum(listfeature==4)

% 1) mean and variance (2 levels)
% 2) kurtosis measures (2 levels)
% 3) fractal dimension
    [cwtParameters,cwtglcmStat,cwtrunLengthStat] = findCWTProp(lowcoef, highcoef, sum(listfeature==2), bitsperpixel, mask, withphase);
else
    cwtParameters = [];
    cwtglcmStat = [];
    cwtrunLengthStat = [];
end


% -------------------------------------------------------------------------
% V. Local Binary Pattern Histogram
% -------------------------------------------------------------------------
if sum(listfeature==5)
    LBPhist = findLBPhist(cubeImg, mask);
else
    LBPhist = [];
end

% -------------------------------------------------------------------------
% VI. Granulometry
% -------------------------------------------------------------------------
if sum(listfeature==6)
    Granhist = findGranulometry(cubeImg);
else
    Granhist = [];
end

% -------------------------------------------------------------------------
% All features;
% -------------------------------------------------------------------------
features = [intensityFeatures runLengthStat glcmStat cwtParameters cwtglcmStat cwtrunLengthStat LBPhist Granhist];