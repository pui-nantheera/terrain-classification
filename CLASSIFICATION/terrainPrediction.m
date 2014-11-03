function resultMap = terrainPrediction(curImage, lowcoef, highcoef, segMap, modelTexture, scaling1, scaling2, classifyByRange, boundarywidth)

% resultMap = terrainPrediction(frames, lowcoef, highcoef, segMap, modelTexture, scaling1, scaling2, classifyByRange, boundarywidth)
%       find terrain type for each region
%       inputs:
%           curImage is grayscale image
%           lowcoef is low-pass subbands of DT-CWT (see dtwavexfm2.m)
%           highcoef is high-pass subbands of DT-CWT (see dtwavexfm2.m)
%           segMap is segmentation map (see cmssegmm.m)
%               lowcoef, highcoef and segMap may be input as empty matrix,
%               i.e. [], default parameters will be used to generate them
%           modelTexture is model of svm classification (to generate this, refer getModelfromTraining.m)
%           scaling1 and scaling2 are normalisation parameters (see getModelfromTraining.m)
%           classifyByRange (option) for dividing image input three ranges  of distance: near, middle and far
%           boundarywidth (option) identifies where in the image will be far, middle and far ranges
%       output:
%           resultMap is the index map for terrain type according to modelTexture
%
%   7-02-2013 by N. Anantrasirichai, University of Bristol

% check inputs
if nargin < 8
    classifyByRange = 0;
    boundarywidth = 1;
end
if (nargin < 9)&&(classifyByRange>0)
    boundarywidth = [0.3 0.2 0.5]; % for near, middle and far area, respectively
end
% do transform if coefficients aren't provided
if isempty(lowcoef) || isempty(highcoef)
    [lowcoef,highcoef] = dtwavexfm2(curImage,4,'antonini','qshift_06');
end
% ignore boundarywidth if classifyByRange will not be employed
if classifyByRange==0
    boundarywidth = 1;
end

% dimension
[height, width] = size(curImage);

% create range map
rangeMap = ones(height, width);
if classifyByRange
    rangeMap(1:round(boundarywidth(end)*height),:) = 3;
    rangeMap(round(boundarywidth(end)*height)+(1:round(boundarywidth(2)*height)),:) = 2;
end
% create addArea to prevent too small region when running classification
addArea = zeros(height, width);
if classifyByRange
    % for adding the small area to the next range
    % intial areas around boundaries
    addArea(round(boundarywidth(end)*height) + (-32:0),:) = 1;
    addArea(round(boundarywidth(end)*height) + (1:32),:)  = -1;
    addArea(round(sum(boundarywidth(2:3))*height) + (-32:0),:) = 2;
    addArea(round(sum(boundarywidth(2:3))*height) + (1:32),:)  = -2;
    for k = [-1 1 -2 2]
        segMapInRange = segMap.*(addArea==k);
        indBigReg = unique(segMapInRange(round([boundarywidth(end) sum(boundarywidth(2:3))]*height)-sign(k)*32,:));
        % remove big region from addArea
        for j = indBigReg(2:end)'
            addArea(segMapInRange==j) = 0;
        end
    end
    rangeMap = rangeMap-round(addArea/2);
end

% classification
resultMap = zeros(height,width);
for regnum = 1:max(segMap(:))
    for k = 1:length(boundarywidth)
        curArea = segMap==regnum;
        curArea = (curArea.*(rangeMap==k))>0;
        if sum(curArea(:))>0
            % find texture features
            features = findTextureFeatures(curImage, lowcoef, highcoef, 8, [1 3 4 5], curArea);
            % texture prediction
            if ~classifyByRange
                textureType = svmPrediction(features, modelTexture, scaling1, scaling2);
            else
                textureType = svmPrediction(features, modelTexture{k}, scaling1{k}, scaling2{k});
            end
            % record result for this region
            resultMap(curArea) = textureType;
        end
    end
end