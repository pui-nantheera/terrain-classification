function [classFar,prob_SVM] = predictSVMwithPCA(curarea,wlevels, mask, ...
                shiftdataPCAfar,coefPCAfar, maxNumFeaturesFar, scaling1far, scaling2far, modelTextureFar, probOption, timeconcern)

% wavelet transform
[lowcoef,highcoef] = dtwavexfm2(curarea,wlevels,'antonini','qshift_06');
% feature extraction
features = findTextureFeatures(curarea, lowcoef, highcoef, 8, [1 4 5], mask, 0);
if  timeconcern
    load('./FEATUREANALYSIS/sortErrInd.mat');
    features = features(:,sortErrInd(1:77,1));
end
% PCA transform
scoretesting = (features - shiftdataPCAfar)*coefPCAfar;
testingData = scoretesting(:,1:maxNumFeaturesFar);
% normalisation dataset
testingData = (testingData - scaling1far).*scaling2far;
% prediction 1. hard surface 2. soft surface
[classFar, ~, prob_SVM] = svmpredict(1, testingData, modelTextureFar, probOption);