clear all
addpath('C:\Locomotion\code_motion\CLASSIFICATION');

rootDir = 'C:\Locomotion\temp\LPQ\Outex_TC_00000\';
kernelType = 'linear';
wlevels = 4;
biort = 'antonini';%'legall';%
qshift = 'qshift_06';%'qshift_06';
option  = 16; % 0 = mean and variance
% 1 = histogram of quantisation
% 2 = histogram of quantisation of overcomplete DTCWT
% 3 = option 0 + option 2
% 4 = overcomplete DTCWT = mean and variance + histogram
% 5 = part histogram of magnitudes
% 6 = option 0 + option 1
% 6.5 = option 0 + option 1.5 (bicubic interpolation) - better than option 6
% 7 = overcomplete DTCWT with decorrelation (not finished yet)
% 8 = Paul's UDTCWT
% 9 = option 8 + histogram of each subband
% 10 = option 8 only histogram of each subband (best ~=12)
% 11 = option 10 + PCA (worse)
% 12 = option 10 without mean and variance     (best ~=10)
% 13 = option 10 but separate real and imaginary parts - much fewer features (better than ri_lpq 12 orientations)
% 14 = option 10 but level 2-wlevels
% 15 = option 14 without mean and variance
% 16 = option 8 but level 2-wlevels

blurType = 'motion';%'motion';% 'disk';

if strcmpi(blurType,'motion')
    blurRange = [0 1:0.5:5];%0:0.1875:1.5;% 0:0.25:2;
    angleRange = [5 23 45 75 86]; % 
elseif strcmpi(blurType,'gaussian')
    blurRange = [0.25 0.5 0.75 1];
    angleRange = 0;
end

% PCA parameters
if option == 11
    usePCA = 1;
    maxNumFeatures = 0;
else
    usePCA = 0;
end

if isempty(blurType)
    blurRange = 1;
end
totalBlurRange = length(blurRange);

if option == 0
    totalFeatures = 2*(6*wlevels + wlevels);
elseif (option == 3)||(option == 4)||(option == 6)||(option == 6.5)||(option == 7)||(option == 8)
    totalFeatures = 2^(wlevels*2) + 2*(6*wlevels + wlevels);
elseif (option ==9)
    totalFeatures = 7*(2^(wlevels*2)) + 2*(6*wlevels + wlevels);
elseif (option ==10)||(option ==11)
    totalFeatures = 6*(2^(wlevels*2)) + 2*(6*wlevels + wlevels);
elseif (option ==12)
    totalFeatures = 6*(2^(wlevels*2));
elseif (option ==13)
    totalFeatures = 2*6*(2^(wlevels)) + 2*(6*wlevels + wlevels);
elseif (option ==14)
    totalFeatures = 6*(2^((wlevels-1)*2)) + 2*(6*wlevels + wlevels);
elseif (option ==15)
    totalFeatures = 6*(2^((wlevels-1)*2));
elseif (option ==16)
    totalFeatures = 2^((wlevels-1)*2) + 2*(6*wlevels + wlevels);
elseif option == 5
    totalFeatures = 150-3;%198;
else
    totalFeatures = 2^(wlevels*2);
end

% open record files
for k = 1:length(angleRange)
    angle = angleRange(k);
    recordAcc{k} = zeros(100,totalBlurRange);
    numTest{k}   = zeros(100,totalBlurRange);
    % record results
    name{k} = [rootDir,kernelType,'Outex_TC_00000DTCWTopt',num2str(option),blurType,'orient',num2str(angle),'w',num2str(wlevels),'.txt'];
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

for probcase = 0:85
    probcase
    caseDir = [rootDir, sprintf('%03d',probcase),'\'];
    % read training
    [names, types] = textread([caseDir,'train.txt'], '%s %d');
    totalTrain = length(names)-1;
    % extract feature
    trainingFeatures = zeros(totalTrain,totalFeatures);
    for k = 1:totalTrain
        % read image
        img = imread([rootDir,'images\',names{k+1}]);
        if option == 3
            trainingFeatures(k,1:2*(6*wlevels + wlevels)) = histCWT(img,wlevels,0,biort,qshift);
            trainingFeatures(k,2*(6*wlevels + wlevels)+1:end) = histCWT(img,wlevels,2,biort,qshift);
        elseif option == 6
            trainingFeatures(k,1:2*(6*wlevels + wlevels)) = histCWT(img,wlevels,0,biort,qshift);
            trainingFeatures(k,2*(6*wlevels + wlevels)+1:end) = histCWT(img,wlevels,1,biort,qshift);
        else
            trainingFeatures(k,:) = histCWT(img,wlevels,option,biort,qshift);
        end
    end
    trainingLabels = types(2:end);
    if usePCA
        shiftdataPCA = mean(trainingFeatures);
        [coefPCA,score,latent] = princomp(trainingFeatures - repmat(shiftdataPCA,[length(trainingLabels) 1]));
        if maxNumFeatures==0
            dimchoose = (cumsum(latent)./sum(latent))<0.99;
            maxNumFeatures = sum(dimchoose);
        end
        trainingFeatures = score(:,1:maxNumFeatures);
    end
    % svm training
    if strcmpi(kernelType,'linear')
        [modelTexture, scaling1, scaling2, ~, ~, accTrain] = getModelfromTraining(trainingFeatures, trainingLabels, 'linear', [], [], 0, 1);
    else
        [modelTexture, scaling1, scaling2, ~, ~, accTrain] = getModelfromTraining(trainingFeatures, trainingLabels, 'rbf', 7, 7, 0, 1);
    end
    
    for n = 1:length(angleRange)
        angle = angleRange(n);
        % read testing
        [names, types] = textread([caseDir,'test.txt'], '%s %d');
        totalTest = length(names)-1;
        for numradius = 1:totalBlurRange
            radius = blurRange(numradius);
            % extract feature
            testingFeatures = zeros(totalTest,totalFeatures);
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
                if option == 3
                    testingFeatures(k,1:2*(6*wlevels + wlevels)) = histCWT(img,wlevels,0);
                    testingFeatures(k,2*(6*wlevels + wlevels)+1:end) = histCWT(img,wlevels,2);
                elseif option == 6
                    testingFeatures(k,1:2*(6*wlevels + wlevels)) = histCWT(img,wlevels,0);
                    testingFeatures(k,2*(6*wlevels + wlevels)+1:end) = histCWT(img,wlevels,1);
                else
                    testingFeatures(k,:) = histCWT(img,wlevels,option);
                end
            end
            testingLabels = types(2:end);
            % PCA transform
            if usePCA
                scoretesting = (testingFeatures - repmat(shiftdataPCA,[length(testingLabels) 1]))*coefPCA;
                testingFeatures = scoretesting(:,1:maxNumFeatures);
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
    avgAcc1 = mean(recordAcc{n});
    avgAcc2 = sum(recordAcc{n}.*numTest{n})./sum(numTest{n});
    fprintf(fileID{n},'%15s  %.4f  %.4f', 'average testing', avgAcc1);
    fclose('all');
end