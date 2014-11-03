function [modelTrain, scaling1, scaling2, coefPCA, shiftdataPCA, maxNumFeatures, varProb] = getPathConsistencyModel(...
    kernelType,usePCA,maxNumFeatures,testPredict,typefeature)

% classification parameter
if isempty(kernelType)
    kernelType = 'rbf';
end
if nargin < 2
    usePCA = 1;
end
if nargin < 3
    maxNumFeatures = 13;
end
if nargin < 4
    testPredict = 1;
end
if nargin < 5
    typefeature = 6;
end
% directories store images for each class
dirName{1} = 'C:\Locomotion\results\code_motion\forTraining\pathcontinuity\continue\';
dirName{2} = 'C:\Locomotion\results\code_motion\forTraining\pathcontinuity\discontinue\';

% file of features
filenameFeatures = 'C:\Locomotion\results\code_motion\forTraining\features\path_consistency.txt';

% feature parameters
% -------------------------------------------------------------------------
wlevels = 3;
numbins = 13;
numErrType = 3;
selectedFeatures = genFeatureRange(numbins,wlevels,numErrType);

% read features
% -------------------------------------------------------------------------
featureMatrix = dlmread(filenameFeatures);
labelMatrix   = featureMatrix(:,1);
allfeatureMatrix = featureMatrix(:,2:end);
% adjust labels
if testPredict==0
    labelMatrix(labelMatrix==1) = -1;
    labelMatrix(labelMatrix==2) = 1;
end


% get selected features
% -----------------------------------------------------------------
featureMatrix = allfeatureMatrix(:,selectedFeatures{typefeature});
featureMatrix(isnan(featureMatrix)) = 0;

% training set
trainingData = featureMatrix;
trainingLabels = labelMatrix;

% usePCA
% -----------------------------------------------------------------
if usePCA
    shiftdataPCA = mean(trainingData);
    [coefPCA,score,latent] = princomp(trainingData - repmat(shiftdataPCA,[length(trainingLabels) 1]));
    if maxNumFeatures==0
        dimchoose = (cumsum(latent)./sum(latent))<0.999;
        maxNumFeatures = sum(dimchoose);
    else
        dimchoose = 1:min(size(trainingData,2),maxNumFeatures);
        maxNumFeatures = length(dimchoose);
    end
    trainingDataCur = score(:,dimchoose);
else
    coefPCA = [];
    shiftdataPCA = [];
    maxNumFeatures = size(featureMatrix,2);
    trainingDataCur = trainingData;
end

% modelling
% -----------------------------------------------------------------
if strcmpi(kernelType,'linear')
    [modelTrain, scaling1, scaling2] = getModelfromTraining(trainingDataCur, trainingLabels, 'linear', [], [], 1);
else
    [modelTrain, scaling1, scaling2] = getModelfromTraining(trainingDataCur, trainingLabels, 'rbf', 3.4,0.6, 1);
end
        
% test prediction
% -----------------------------------------------------------------
if testPredict
    % normalisation dataset
    data = trainingDataCur;
    trainingDataCur = (data - repmat(scaling1,size(data,1),1)).*(repmat(scaling2,size(data,1),1));
    [~, accuracyRBF, probTrain] = svmpredict(trainingLabels, trainingDataCur, modelTrain, '-b 1');
    % compute variance
    varProb = zeros(2,size(probTrain,2));
    for k = 1:size(probTrain,2)
        varProb(1,k) = var(probTrain(trainingLabels==k,k));
        data  = probTrain(trainingLabels==k,[1:k-1 k+1:size(probTrain,2)]);
        varProb(2,k) = var(data(:));
    end
else
    varProb = [];
end
        
 