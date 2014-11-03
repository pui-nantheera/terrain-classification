clear all
addpath('C:\Locomotion\code_motion\CLASSIFICATION');

rootDir = 'C:\Locomotion\temp\LPQ\Outex_TC_00000\';
kernelType = 'linear';
option  = 0; % 0 = LPQ
% 1 = rotation invariant Local Phase Quantization (LPQ)
% filter for orientation
numOrientations = 36;
LPQfilters = createLPQfilters(9,numOrientations,2);

blurType = 'motion';%'motion';% 'disk';

if strcmpi(blurType,'motion')
    blurRange = [0 1:0.5:5];%0:0.1875:1.5;% 0:0.25:2;
    angleRange = 75;%[5 23 45 75 86]; % 
elseif strcmpi(blurType,'gaussian')
    blurRange = [0.25 0.5 0.75 1];
    angleRange = 0;
end

if isempty(blurType)
    blurRange = 1;
end
totalBlurRange = length(blurRange);

% open record files
for k = 1:length(angleRange)
    angle = angleRange(k);
    recordAcc{k} = zeros(100,1);
    numTest{k}   = zeros(100,1);
    % record results
    name{k} = [rootDir,kernelType,'Outex_TC_00000LPQopt',num2str(option),blurType,'_',num2str(numOrientations),'orient',num2str(angle),'.txt'];
    fileID{k} = fopen(name{k},'a');
    if  isempty(blurType)
        fprintf(fileID{k},'%3s  %7s  %7s\n', 'pb#', 'train', 'test');
    else
        namelist = 'pb#     train';
        for bi = blurRange
            namelist = [namelist ' ' sprintf('%7s',num2str(bi))];
        end
        fprintf(fileID{k},'%s\n', namelist);
    end
end
% for record results
savelist = '';
for k = 1:length(blurRange)
    savelist = [savelist '%.4f  '];
end
for probcase = 0:99
    probcase
    caseDir = [rootDir, sprintf('%03d',probcase),'\'];
    % read training
    [names, types] = textread([caseDir,'train.txt'], '%s %d');
    totalTrain = length(names)-1;
    % extract feature
    trainingFeatures = zeros(totalTrain,256);
    for k = 1:totalTrain
        % read image
        img = imread([rootDir,'images\',names{k+1}]);
        if option == 1
            trainingFeatures(k,:) = ri_lpq(img,LPQfilters);
        else
            trainingFeatures(k,:) = lpq(img,3);
        end
    end
    trainingLabels = types(2:end);
    % svm training
    if strcmpi(kernelType,'linear')
        [modelTexture, scaling1, scaling2, ~, ~, accTrain] = getModelfromTraining(trainingFeatures, trainingLabels, 'linear', [], [], 0, 1);
    else
        [modelTexture, scaling1, scaling2, ~, ~, accTrain] = getModelfromTraining(trainingFeatures, trainingLabels, 'rbf', [], [], 0, 1);
    end
    
    for n = 1:length(angleRange)
        angle = angleRange(n);
        % read testing
        [names, types] = textread([caseDir,'test.txt'], '%s %d');
        totalTest = length(names)-1;
        for numradius = 1:totalBlurRange
            radius = blurRange(numradius);
            % extract feature
            testingFeatures = zeros(totalTest,256);
            for k = 1:totalTrain
                % read image
                img = imread([rootDir,'images\',names{k+1}]);
                % blur image
                if (~isempty(blurType))&&(radius>0)
                    if strcmpi(blurType,'motion')
                        h = fspecial(blurType, radius, angle);
                    elseif strcmpi(blurType,'gaussian')
                        h = fspecial(blurType, [7 7], radius);
                    end
                    
                    img = imfilter(img,h,'replicate');
                end
                if option == 1
                    testingFeatures(k,:) = ri_lpq(img,LPQfilters);
                else
                    testingFeatures(k,:) = lpq(img,3);
                end
            end
            testingLabels = types(2:end);
            % normalisation dataset
            data = testingFeatures;
            testingData = (data - repmat(scaling1,size(data,1),1)).*(repmat(scaling2,size(data,1),1));
            % predict process
            [predictClass, accuracy] = svmpredict(testingLabels, testingData, modelTexture);
            % record results
            recordAcc{n}(probcase+1,numradius) = accuracy(1);
            numTest{n}(probcase+1,numradius) = totalTest;
        end
        fprintf(fileID{n},'%03d  %.4f  ', probcase, accTrain);
        fprintf(fileID{n},savelist, recordAcc{n}(probcase+1,:));
        fprintf(fileID{n},'\n');
    end
    
end
for n = 1:length(angleRange)
    angle = angleRange(n);
    avgAcc1 = mean(recordAcc{n});
    avgAcc2 = sum(recordAcc{n}.*numTest{n})./sum(numTest{n});
    fprintf(fileID{n},'%15s  %.4f  %.4f', 'average testing', avgAcc1, avgAcc2);
end
fclose('all');