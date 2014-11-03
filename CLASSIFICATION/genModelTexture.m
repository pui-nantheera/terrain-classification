function [modelTexture, scaling1, scaling2, coefPCA, shiftdataPCA, maxNumFeatures, varProb, trainingData, trainingLabels] = genModelTexture(...
    genModelTextureClassify,classList,kernelType,areatype,featuresList,usePCA,maxNumFeatures,testPredict,typefeature,...
    addfeatures, timeconcern,saveoption)

% input param:
% areatype = 'far' or 'near'
% kernelType = 'rbf' or 'linear'

if nargin<8
    testPredict = 0;
end
if nargin<9
    typefeature = 'best';
end
if strcmpi(typefeature,'all');
    typefeatureName = '';
elseif strcmpi(typefeature,'plus')
    typefeatureName = 'best_';
else
    typefeatureName = [typefeature,'_'];%,'256_'];
end
if nargin < 10
    addfeatures = [];
end
if nargin < 11
    timeconcern = 0;
end
if nargin < 12
    saveoption = 0;
end
if iscell(areatype)
    areatypeAll = areatype; clear areatype;
else
    areatypeAll{1} = areatype; clear areatype;
end

featureDir = 'C:\Locomotion\results\code_motion\forTraining\features\';
totalNumClass = length(classList);

if genModelTextureClassify
    if isempty(maxNumFeatures)
        maxNumFeatures = 0;
    end
    
    trainingLabels = [];
    trainingData   = [];
    for type = 1:length(areatypeAll)
        for numClass = 1:totalNumClass
            for c1 = 1:length(classList{numClass})
                terraintype = classList{numClass}{c1};
                featureMatrix = dlmread([featureDir,typefeatureName,terraintype,areatypeAll{type},'.txt']);
                featureMatrix = featureMatrix(:,2:end); % remove index order
                % get selected features
                if strcmpi(typefeature,'all')% get some features from all
                    featureMatrix = featureMatrix(:,featuresList);
                end
                if  strcmpi(typefeature,'plus')
                    featureMatrix2 = dlmread([featureDir,terraintype,areatypeAll{type},'.txt']);
                    featureMatrix2 = featureMatrix2(:,featuresList);
                    featureMatrix  = [featureMatrix; featureMatrix2];
                end
                featureMatrix(isnan(featureMatrix)) = 0;
                totalSamples = size(featureMatrix,1);
                % gather with other types
                trainingData = [trainingData; featureMatrix];
                trainingLabels = [trainingLabels; numClass*ones(totalSamples,1)];
            end
        end
    end
    
    if ~isempty(addfeatures)
        trainingData = [trainingData; addfeatures(:,2:end)];
        trainingLabels = [trainingLabels; addfeatures(:,1)];
    end
    
    if  timeconcern
        load('./FEATUREANALYSIS/sortErrInd.mat');
        trainingData = trainingData(:,sortErrInd(1:77,1));
    end
    
    
    if usePCA
        shiftdataPCA = mean(trainingData);
        [coefPCA,score,latent] = princomp(trainingData - repmat(shiftdataPCA,[length(trainingLabels) 1]));
        if maxNumFeatures==0
            dimchoose = (cumsum(latent)./sum(latent))<0.99;
            maxNumFeatures = sum(dimchoose);
        else
            dimchoose = 1:min(length(featuresList),maxNumFeatures);%(cumsum(latent)./sum(latent))<0.999;
            maxNumFeatures = length(dimchoose);
        end
        trainingDataCur = score(:,dimchoose);
    else
        coefPCA = [];
        shiftdataPCA = [];
        maxNumFeatures = length(featuresList);
        trainingDataCur = trainingData;
    end
    
    % modelling with decision value
    % -------------------------------------------------------------------------
    % modelling using rbf kernel
    if strcmpi(kernelType,'linear')
        [modelTexture, scaling1, scaling2] = getModelfromTraining(trainingDataCur, trainingLabels, 'linear', [], [], 1);
    else
        if strcmpi(typefeature,'all') || strcmpi(typefeature,'best') || strcmpi(typefeature,'plus')
            [modelTexture, scaling1, scaling2] = getModelfromTraining(trainingDataCur, trainingLabels, 'rbf', 7, 7.8, 1);
        else
            if strcmpi(areatypeAll,'far')
                [modelTexture, scaling1, scaling2] = getModelfromTraining(trainingDataCur, trainingLabels, 'rbf', 8, 0.25, 1);
            else
                [modelTexture, scaling1, scaling2] = getModelfromTraining(trainingDataCur, trainingLabels, 'rbf', 4, 0.5, 1);
            end
        end
    end
    % test prediction
    if testPredict
        % normalisation dataset
        data = trainingDataCur;
        trainingDataCur = (data - repmat(scaling1,size(data,1),1)).*(repmat(scaling2,size(data,1),1));
        [~, accuracyRBF, probTrain] = svmpredict(trainingLabels, trainingDataCur, modelTexture, '-b 1');
        % compute variance : first row for correct predict, second row for
        % incorrect predict
        varProb = zeros(2,size(probTrain,2));
        for k = 1:size(probTrain,2)
            varProb(1,k) = var(probTrain(trainingLabels==k,k));
            data  = probTrain(trainingLabels==k,[1:k-1 k+1:size(probTrain,2)]);
            varProb(2,k) = var(data(:));
        end
    else
        varProb = [];
    end
    % save model
    if saveoption
        save(['./CLASSIFICATION/model_',typefeature,kernelType,areatype,num2str(usePCA),'c',num2str(totalNumClass)],'modelTexture','scaling1','scaling2','coefPCA', 'shiftdataPCA', 'dimchoose');
    end
else
    if strcmpi(areatype,'near')
        load(['./CLASSIFICATION/model_best_',kernelType,areatype,num2str(usePCA),'c',num2str(totalNumClass)]);
    else
        load(['./CLASSIFICATION/model_',kernelType,areatype,num2str(usePCA),'c',num2str(totalNumClass)]);
    end
end