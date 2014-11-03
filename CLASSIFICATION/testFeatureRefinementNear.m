% This code for developing feature refinement method
clear all

addpath('../SUPPORTFILES/');
addpath(genpath('../FEATURES/'));
addpath('../DTCWT/');

% list of each class
% -------------------------------------------------------------------------
% 1. hard surface
% 2. soft surface
class{1} = {'bricks','cement','metal','tarmac','wood'};
class{2} = {'grass', 'sand', 'soil'};

% list of features
% -------------------------------------------------------------------------
intensity = 1:5;
runlength = 6:16;
glcmprop  = 17:23;
wavelet   = 24:135;
wavelet   = [wavelet(1:8) wavelet(17:64)]; % use only magnitude
waveletglcm = 136:142;
waveletrun  = 143:153;
lbphist   = 154:212;

selectedFeatures{1} = [wavelet lbphist];
selectedFeatures{2} = [wavelet];
selectedFeatures{3} = [lbphist];
selectedFeatures{4} = [intensity wavelet]; %**best performance
selectedFeatures{5} = [intensity lbphist];
selectedFeatures{6} = [intensity wavelet lbphist]; %**best performance
selectedFeatures{7} = [wavelet waveletrun];
selectedFeatures{8} = [wavelet waveletrun lbphist];
selectedFeatures{9} = [intensity runlength glcmprop wavelet lbphist];
selectedFeatures{10} = [intensity runlength glcmprop wavelet waveletrun lbphist];
% test wavelet 3 levels
selectedFeatures{11} = [wavelet(1:3) wavelet(5:7) wavelet(9:26) wavelet(33:50)];
% test wavelet only mean all subband
selectedFeatures{12} = [wavelet(1:8)];

%% CASE I randomly choose training set (half for training, half for testing)

scaling = 1; % upsampling far area
wlevels = 4;
usePCA = 1;
numIteration = 100;
accRBF    = zeros(length(selectedFeatures),1);
% accLinear = zeros(length(selectedFeatures),1);
computeTime = zeros(length(selectedFeatures),1);
bestcEachFt = zeros(length(selectedFeatures),1); 
bestgEachFt = zeros(length(selectedFeatures),1);
for ft = 6%1:length(selectedFeatures)
    fprintf('%2d :',ft);
    accRBFAll    = zeros(1,numIteration);
    accLinearAll = zeros(1,numIteration);
    computeTimeAll = zeros(1,numIteration);
    bestcEachFtAll = zeros(1,numIteration);
    bestgEachFtAll = zeros(1,numIteration);
    probRBFAll = [];
    for it = 1:numIteration
        fprintf('%2d ',it);
        tic
        % data from class 1
        trainingData = [];
        testingData = [];
        trainingLabels = [];
        testingLabels = [];
        for numClass = 1:2
            for c1 = 1:length(class{numClass})
                terraintype = class{numClass}{c1};
                
                % get feature for training
                % ---------------------------------------------------------
                featureMatrix = dlmread(['C:\Locomotion\results\code_motion\forTraining\features\',terraintype,'near.txt']);
                featureMatrix = featureMatrix(:,2:end); % remove index order
                % get selected features
                featureMatrix = featureMatrix(:,selectedFeatures{ft});
                featureMatrix(isnan(featureMatrix)) = 0;
                totalSamples = size(featureMatrix,1);
                % randomly choose samples for training
                numTraining = max(min(totalSamples,15),round(0.67*totalSamples));
                trainingSet = [];
                while length(trainingSet)<numTraining
                    trainingSet = unique([trainingSet randi(totalSamples,1, numTraining)]);
                end
                if length(trainingSet)>numTraining
                    numToRemove = length(trainingSet) - numTraining;
                    idxRemove = unique(randi(length(trainingSet),1, numToRemove));
                    trainingSet(idxRemove) = [];
                end
                % gather with other types
                trainingData = [trainingData; featureMatrix(trainingSet,:)];
                trainingLabels = [trainingLabels; (2*numClass-3)*ones(length(trainingSet),1)];
                
                % get feature for testing
                % ---------------------------------------------------------
                featureMatrix = dlmread(['C:\Locomotion\results\code_motion\forTraining\features\',terraintype,'far.txt']);
                featureMatrix = featureMatrix(:,2:end); % remove index order
                % get selected features
                featureMatrix = featureMatrix(:,selectedFeatures{ft});
                featureMatrix(isnan(featureMatrix)) = 0;
                % randomly choose samples for training
                totalSamples = size(featureMatrix,1);
                numTesting = numTraining;
                testingSet = [];
                while length(testingSet)<numTesting
                    testingSet = unique([testingSet randi(totalSamples,1, numTesting)]);
                end
                if length(testingSet)>numTesting
                    numToRemove = length(testingSet) - numTesting;
                    idxRemove = unique(randi(length(testingSet),1, numToRemove));
                    testingSet(idxRemove) = [];
                end
                if scaling
                    clear featureMatrix
                    % read test image names
                    file_id = fopen(['C:\Locomotion\results\code_motion\forTraining\features\',terraintype,'farName.txt']);
                    segarray = textscan(file_id, '%4d %25s');
                    fclose(file_id);
                    for n = testingSet
                        curName = ['C:\Locomotion\results\code_motion\forTraining\',terraintype,'_featureExtracted\',segarray{2}{n},'.png'];
                        curImage = im2double(imread(curName));
                        % scaling
                        curImage = imresize(curImage, 4);
                        curImage = imresize(curImage, 0.5);
                        % convert to grayscale
                        if size(curImage,3)>1
                            yuv = rgb2ycbcr(curImage);
                            curImage = yuv(:,:,1);
                        end
                        % wavelet transform
                        [lowcoef,highcoef] = dtwavexfm2(curImage,wlevels,'antonini','qshift_06');
                        % texture features
                        features = findTextureFeatures(curImage, lowcoef, highcoef, 8, [1 4 5], [], 0);
                        features(isnan(features)) = 0;
                        % gather with other types
                        testingData  = [testingData; features];
                    end
                else
                    % gather with other types
                    testingData  = [testingData; featureMatrix(testingSet,:)];
                end
                testingLabels  = [testingLabels;  (2*numClass-3)*ones(length(testingSet),1)];
            end
        end
        
        % usePCA
        if usePCA
            shiftdata = mean(trainingData);
            [coef,score,latent] = princomp(trainingData - repmat(shiftdata,[length(trainingLabels) 1]));
            dimchoose = 1:min(length(selectedFeatures{ft}),12);%(cumsum(latent)./sum(latent))<0.999;
            trainingData = score(:,dimchoose);
            % testing
            scoretesting = (testingData - repmat(shiftdata,[length(testingLabels) 1]))*coef;
            testingData = scoretesting(:,dimchoose);
        end
        
        % modelling
        % -------------------------------------------------------------------------
        % modelling using rbf kernel
        [modelRBF, scaling1, scaling2, bestc, bestg] = getModelfromTraining(trainingData, trainingLabels, 'rbf',[],[], 1);
        % modelling using linear kernel
        [modelLinear] = getModelfromTraining(trainingData, trainingLabels, 'linear', [], [], 1);
        
        % Testing
        % -------------------------------------------------------------------------
        % normalisation dataset
        data = testingData;
        testingData = (data - repmat(scaling1,size(data,1),1)).*(repmat(scaling2,size(data,1),1));
        % prediction process
        [~, accuracyRBF, prob_RBF]    = svmpredict(testingLabels, testingData, modelRBF, '-b 1');
        [~, accuracyLinear, prob_Linear] = svmpredict(testingLabels, testingData, modelLinear, '-b 1');
        
        % record results
        % -------------------------------------------------------------------------
        computeTimeAll(it) = toc;
        accRBFAll(it) = accuracyRBF(1);
        accLinearAll(it) = accuracyLinear(1);
        curLabel = ceil((testingLabels+2)/2);
        probRBFAll = [probRBFAll; curLabel prob_RBF];

        bestcEachFtAll(it) = bestc;
        bestgEachFtAll(it) = bestg;
        fprintf('\n');
    end
    computeTime(ft) = mean(computeTimeAll);
    accRBF(ft) = mean(accRBFAll);
    accLinear(ft) = mean(accLinearAll);
    bestcEachFt(ft) = mean(bestcEachFtAll);
    bestgEachFt(ft) = mean(bestgEachFtAll);
end

%%
var1 = var(probRBFAll(probRBFAll==1,2)); % hard
var2 = var(probRBFAll(probRBFAll==2,3)); % soft
['test with various bestc and bestg']
