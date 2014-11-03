function [keypointMap, indi, indj] = findKeypoints(highcoef, windowSize)

% find key points using DT-CWT

if nargin < 2
    windowSize = 3;
end

% if input is image, not highpass coeff - apply transformation
addrow = 0; addcol = 0;
if ~iscell(highcoef)
    highcoef = double(highcoef);
    % check dimenstion
    [height width] = size(highcoef);
    if mod(height,16)
        addrow = ceil(height/16)*16 - height;
        highcoef(end+(1:addrow),:) = highcoef(end+(0:-1:-addrow+1),:);
    end
    if mod(width,16)
        addcol = ceil(width/16)*16 - width;
        highcoef(:,end+(1:addcol)) = highcoef(:,end+(0:-1:-addcol+1));
    end
    % DT-CWT
    [~,highcoef] = dtwavexfm2(highcoef,4,'near_sym_b','qshift_d');
end

% original frame dimension
height = size(highcoef{1},1)*2;
width = size(highcoef{1},2)*2;
wlevels = length(highcoef);

% FKA keypoint detector
accumulatedEnergy = zeros(height, width);
for level = 1:wlevels
    curHighcoef = highcoef{level};
    energyMap = prod(abs(curHighcoef).^(1/4),3);    % Harris's method
%     energyMap = min(abs(curHighcoef).^(1/4),[],3);    % Forstner's method
    energyMap = imresize(energyMap, 2^level);
    accumulatedEnergy = accumulatedEnergy +  energyMap;
end

% find local maxima windowSize x windowSize: paper used 3x3
keypointMap = zeros(height, width);
for k = 1:windowSize
    for n = 1:windowSize
        keypointMap(ceil(windowSize/2):end-floor(windowSize/2), ceil(windowSize/2):end-floor(windowSize/2)) = ...
            max(keypointMap(ceil(windowSize/2):end-floor(windowSize/2), ceil(windowSize/2):end-floor(windowSize/2)),...
            accumulatedEnergy(k:end-windowSize+k, n:end-windowSize+n));
    end
end
keypointMap = keypointMap==accumulatedEnergy;
% adjust dimenstion to original
if addrow>0
    keypointMap(end+(0:-1:-addrow+1),:) = [];
    keypointMap(end-1:end,:) = 0;
end
if addcol>0
    keypointMap(:,end+(0:-1:-addcol+1)) = [];
    keypointMap(:,end-1:end) = 0;
end
if nargout > 1
    [indi, indj] = find(keypointMap);
end