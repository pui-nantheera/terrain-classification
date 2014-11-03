% run classification discontinue or consistent path
clear all
addpath('../SUPPORTFILES/');
addpath('../CLASSIFICATION/');
addpath('../DTCWT/');

% directories store images for each class
dirName{1} = 'C:\Locomotion\results\code_motion\forTraining\pathcontinuity\continue\';
dirName{2} = 'C:\Locomotion\results\code_motion\forTraining\pathcontinuity\discontinue\';

% classification parameter
usePCA = 1;
numFeatures = 13;
numIteration = 200;

% file of features
filenameFeatures = 'C:\Locomotion\results\code_motion\forTraining\features\path_consistency.txt';

% feature parameters
% -------------------------------------------------------------------------
wlevels = 3;
numbins = 13;
numErrType = 3;

% read features
% -------------------------------------------------------------------------
featureMatrix = dlmread(filenameFeatures);
labelMatrix   = featureMatrix(:,1);
allfeatureMatrix = featureMatrix(:,2:end);
% adjust labels
labelMatrix(labelMatrix==1) = -1;
labelMatrix(labelMatrix==2) = 1;

% list of feature test
% -------------------------------------------------------------------------
selectedFeatures = genFeatureRange(numbins,wlevels,numErrType);

% for each feature group
% -------------------------------------------------------------------------
for ft = 1:length(selectedFeatures) %[40 6 41 28 38 5 33 26]%
    
    fprintf('%2d :',ft);
    accRBFAll    = zeros(1,numIteration);
    accLinearAll = zeros(1,numIteration);
    computeTimeAll = zeros(1,numIteration);
    bestcEachFtAll = zeros(1,numIteration);
    bestgEachFtAll = zeros(1,numIteration);
    probRBFAll = [];
    probLinearAll = [];
    for it = 1:numIteration
        fprintf('%2d ',it);
        tic
        % get selected features
        % -----------------------------------------------------------------
        featureMatrix = allfeatureMatrix(:,selectedFeatures{ft});
        featureMatrix(isnan(featureMatrix)) = 0;
        % remove features having only zeros for all samples
        removefeatures = sum(featureMatrix)==0;
        featureMatrix(:,removefeatures) = [];
        totalSamples = size(featureMatrix,1);
        % randomly choose samples for training
        numTraining = round(0.67*totalSamples);
        trainingSet = zeros(1,totalSamples);
        while sum(trainingSet)<numTraining
            trainingSet(unique(randi(totalSamples,1, numTraining))) = 1;
        end
        if sum(trainingSet)>numTraining
            numToRemove = sum(trainingSet) - numTraining;
            trainingSet(unique(randi(totalSamples,1, numToRemove))) = 0;
        end
        % training set
        trainingData = featureMatrix(trainingSet>0,:);
        trainingLabels = labelMatrix(trainingSet>0);
        % testing set
        testingData = featureMatrix(trainingSet==0,:);
        testingLabels = labelMatrix(trainingSet==0);
        
        % usePCA
        % -----------------------------------------------------------------
        if usePCA
            shiftdata = mean(trainingData);
            [coef,score,latent] = princomp(trainingData - repmat(shiftdata,[length(trainingLabels) 1]));
            dimchoose = 1:min(length(selectedFeatures{ft}),numFeatures);%(cumsum(latent)./sum(latent))<0.999;
            trainingData = score(:,dimchoose);
            % testing
            scoretesting = (testingData - repmat(shiftdata,[length(testingLabels) 1]))*coef;
            testingData = scoretesting(:,dimchoose);
        end
        
        % modelling
        % -----------------------------------------------------------------
        % modelling using rbf kernel
        [modelRBF, scaling1, scaling2, bestc, bestg] = getModelfromTraining(trainingData, trainingLabels, 'rbf',3.4,0.6, 1); %0.95,0.46, 1);
        % modelling using linear kernel
        [modelLinear] = getModelfromTraining(trainingData, trainingLabels, 'linear', [], [], 1);
        
        % Testing
        % -----------------------------------------------------------------
        % normalisation dataset
        data = testingData;
        testingData = (data - repmat(scaling1,size(data,1),1)).*(repmat(scaling2,size(data,1),1));
        % prediction process
        [~, accuracyRBF, prob_RBF]    = svmpredict(testingLabels, testingData, modelRBF, '-b 1');
        [~, accuracyLinear, prob_Linear] = svmpredict(testingLabels, testingData, modelLinear, '-b 1');
        
        % record results
        % -----------------------------------------------------------------
        computeTimeAll(it) = toc;
        accRBFAll(it) = accuracyRBF(1);
        accLinearAll(it) = accuracyLinear(1);
        curLabel = ceil((testingLabels+2)/2);
        probRBFAll = [probRBFAll; curLabel prob_RBF testingData];
        probLinearAll = [probLinearAll; curLabel prob_Linear testingData];
        
        bestcEachFtAll(it) = bestc;
        bestgEachFtAll(it) = bestg;
        fprintf('\n');
    end
    computeTime(ft) = mean(computeTimeAll);
    accRBF(ft) = mean(accRBFAll);
    accLinear(ft) = mean(accLinearAll);
    bestcEachFt(ft) = mean(bestcEachFtAll);
    bestgEachFt(ft) = mean(bestgEachFtAll);
    probRBF{ft} = probRBFAll;
    probLinear{ft} = probLinearAll;
end