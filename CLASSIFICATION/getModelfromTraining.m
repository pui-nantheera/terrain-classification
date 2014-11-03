function [modelTexture, scaling1, scaling2, bestc, bestg, acc] = getModelfromTraining(trainingData,...
    labels, kernelType, bestc, bestg, getProb, warnoption,weight)

% [modelTexture, scaling1, scaling2] = getModelfromTraining(trainingData, labels, kernelType, bestc, bestg, getProb, warnoption)
%       generate classification model based on SVM
%       inputs:
%           trainingData is a matrix of features used for training, size (number of samples) x (number of features)
%           labels is a column matrix of class labels corresponding to trainingData, size (number of samples) x 1
%           kernelType is string array indicating which kernel will be used for modelling. Two options: 'rbf' or 'linear'.
%           bestc, bestg can be obtained from gridsearch
%           getProb estimates probability 
%           warnoption is an option if prediction of the training data is used to show accuracy of the model
%           weight is for adjust features of classes
%       outputs:
%           modelTexture is SVM-based model
%           scaling1 and scaling2 are normalisation parameters
%
%   6-02-2013 by N. Anantrasirichai, University of Bristol

if (nargin < 5)
    doGridSearch = 1;
    bestc = [];
    bestg = [];
else
    doGridSearch = 0;
end
if isempty(bestc) || isempty(bestg)
    doGridSearch = 1;
end
if nargin < 6
    getProb = 0;
end
if nargin < 7
    warnoption = 0;
end
if nargin < 8
    weight = 0;
end


% normalisation dataset
data = trainingData;
scaling1 = min(data,[],1);
scaling2 = 1./(max(data,[],1)-min(data,[],1));
trainingData = (data - repmat(scaling1,size(data,1),1)).*(repmat(scaling2,size(data,1),1));

if strcmp(kernelType,'rbf')
    if doGridSearch
        % gridSearch
        [bestc, bestg] = gridSearch(labels, trainingData);
    end
    % training RBF
    cmd = ['-t 2 -c ', num2str(bestc), ' -g ', num2str(bestg)];

else
    cmd = ['-t 0'];
end

if getProb==1
    cmd = [cmd,' -b 1'];
end

if (weight(1)>0)||(~isempty(weight))
    cmd = [cmd,weight];
end

modelTexture = svmtrain(labels, trainingData, cmd);

acc = 0;
if warnoption
    % testing
    [~, accuracy_linear] = svmpredict(labels, trainingData, modelTexture);
    
    if accuracy_linear(1) < 100
        warning(['Accuracy is < 100% :', num2str(accuracy_linear(1)),'%']);
    end
    acc = accuracy_linear(1);
end