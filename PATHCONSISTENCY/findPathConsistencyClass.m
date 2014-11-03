function [classPath, prob_Path] = findPathConsistencyClass(pathImg,featurePathType,modelPath, scaling1Path, scaling2Path, coefPCAPath, shiftdataPCAPath, maxNumFeaturesPath)

% feature parameters
% -------------------------------------------------------------------------
wlevels = 3;
numbins = 13;
numErrType = 3;
selectedFeatures = genFeatureRange(numbins,wlevels,numErrType);

% dimenstion
width = size(pathImg,2);
[~,highcoef] = dtwavexfm2(pathImg,3,'antonini','qshift_06');

% Feature extraction - this process can be speed up when we know what
% features will be used at the end (best performance)
% -------------------------------------------------------------------------
features = [];
for level = 1:min(3,wlevels)
    % creat gradient line at the middle of the image - assuming we're
    % walking forward
    curMap = abs(highcoef{level});
    gradientMap = mean(curMap(:,:,2:5),3);
    midline = round(width/2^(level+1));
    sizeband = min(floor(size(gradientMap,2)/2),20*(wlevels-level+1));
    gradientMap = gradientMap(:,midline+(-sizeband+1:sizeband));
    gradientMap = gradientMap./max(gradientMap(:));
    gradientMap = imfilter(gradientMap,fspecial('average',floor([sizeband/2 sizeband/2])));
    midline = round(size(gradientMap,2)/2);
    sizeband = min(floor(size(gradientMap,2)/2)-ceil(sizeband/4),15*(wlevels-level+1));
    gradientMap = gradientMap(sizeband:end-sizeband,midline+(-sizeband+1:sizeband));
    gradientLine = mean(gradientMap,2);
    % detect change
    p = polyfit(1:length(gradientLine), gradientLine', 2);
    smthGradient2 = polyval(p,1:length(gradientLine));
    error2 = abs(gradientLine'-smthGradient2);
    p = polyfit(1:length(gradientLine), gradientLine', 3);
    smthGradient3 = polyval(p,1:length(gradientLine));
    error3 = abs(gradientLine'-smthGradient3);
    p = polyfit(1:length(gradientLine), gradientLine', 4);
    smthGradient4 = polyval(p,1:length(gradientLine));
    error4 = abs(gradientLine'-smthGradient4);
    % histogram
    [normh2, bin2] = normHistogram(error2, 0:0.005:0.06);%max([error2 error3]));
    [normh3, bin3] = normHistogram(error3, 0:0.005:0.06);%max([error2 error3]));
    [normh4, bin4] = normHistogram(error4, 0:0.005:0.06);%max([error2 error3]));
    features = [features normh2 normh3 normh4];
end

% get selected features
% -------------------------------------------------------------------------
features = features(:,selectedFeatures{featurePathType});
features(isnan(features)) = 0;
        
% PCA transform
% -------------------------------------------------------------------------
scoretesting = (features - shiftdataPCAPath)*coefPCAPath;
testingData = scoretesting(:,1:maxNumFeaturesPath);

% normalisation dataset
% -------------------------------------------------------------------------
testingData = (testingData - scaling1Path).*scaling2Path;

% prediction 
% -------------------------------------------------------------------------
[classPath, ~, prob_Path] = svmpredict(1, testingData, modelPath, '-b 1');