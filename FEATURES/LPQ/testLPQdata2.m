clear all
addpath('C:\Locomotion\code_motion\CLASSIFICATION');
addpath('C:\Locomotion\code_motion\SUPPORTFILES');

rootDir = 'C:\Locomotion\temp\LPQ\project LAVA\';
kernelType = 'linear';
resizeRatio = 0.5;
option  = 1; % 0 = LPQ
% 1 = rotation invariant Local Phase Quantization (LPQ)
% filter for orientation
numOrientations = 36;
LPQfilters = createLPQfilters(9,numOrientations,2);

blurType = 'motion';%'gaussian';% 'disk';
if strcmpi(blurType,'motion')
    blurRange = [1:0.5:5];%0:0.1875:1.5;% 0:0.25:2;
    angleRange = [5 23 45 75 86]; %
elseif strcmpi(blurType,'gaussian')
    blurRange = [0 0.5 0.75 1];
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
    name{k} = [rootDir,kernelType,'LAVA',num2str(resizeRatio),'_LPQopt',num2str(option),blurType,'_',num2str(numOrientations),'orient',num2str(angle),'.txt'];
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
for probcase = 1:50
    % read training
    trainInd = dlmread([rootDir,'problem',num2str(probcase),'train.txt']);
    totalClass = size(trainInd,1);
    totalTrain = size(trainInd,2);
    % extract feature
    trainingFeatures = zeros(totalTrain*totalClass,256);
    count = 1; trainingLabels = [];
    for cnum = 1:totalClass
        for k = 1:totalTrain
            % read image
            imgname = ['T',sprintf('%02s',num2str(cnum)),'_',sprintf('%02s',num2str(trainInd(cnum,k)))];
            img = imresize(imread([rootDir,'images\',imgname,'.jpg']),resizeRatio);
            if option == 1
                trainingFeatures(count,:) = ri_lpq(img,LPQfilters);
            else
                trainingFeatures(count,:) = lpq(img,3);
            end
            count = count + 1;
            trainingLabels = [trainingLabels; cnum];
        end
    end
    % svm training
    if strcmpi(kernelType,'linear')
        [modelTexture, scaling1, scaling2, ~, ~, accTrain] = getModelfromTraining(trainingFeatures, trainingLabels, 'linear', [], [], 0, 1);
    else
        [modelTexture, scaling1, scaling2, ~, ~, accTrain] = getModelfromTraining(trainingFeatures, trainingLabels, 'rbf', 7, 7, 0, 1);
    end
    
    % read testing
    testInd = dlmread([rootDir,'problem',num2str(probcase),'test.txt']);
    totalClass = size(testInd,1);
    totalTest = size(testInd,2);
    for n = 1:length(angleRange)
        angle = angleRange(n);
        for numradius = 1:totalBlurRange
            radius = blurRange(numradius);
            % extract feature
            testingFeatures = zeros(totalTest*totalClass,256);
            count = 1; testingLabels = [];
            for cnum = 1:totalClass
                for k = 1:totalTest
                    % read image
                    imgname = ['T',sprintf('%02s',num2str(cnum)),'_',sprintf('%02s',num2str(testInd(cnum,k)))];
                    img = imresize(imread([rootDir,'images\',imgname,'.jpg']),resizeRatio);
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
                        testingFeatures(count,:) = ri_lpq(img,LPQfilters);
                    else
                        testingFeatures(count,:) = lpq(img,3);
                    end
                    count = count + 1;
                    testingLabels = [testingLabels; cnum];
                end
            end
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