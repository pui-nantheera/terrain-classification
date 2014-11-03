clear all
addpath('C:\Locomotion\code_motion\CLASSIFICATION');
addpath('C:\Locomotion\code_motion\SUPPORTFILES');

rootDir = 'C:\Locomotion\temp\LPQ\project LAVA\';
kernelType = 'linear';%'rbf';%
resizeRatio = 0.5;
wlevels = 5;
l_0 = 2;
numfeatures = 0;
includeavg = 0;
usePCA = 0;
biort = 'antonini';%'legall';%
qshift = 'qshift_06';%'qshift_06';
option  = 18; % 0 = mean and variance
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
    % 17 = option 15 but l_0 = 3;
    % 18 = option 15 but l_0 = selected;
    % 19 = option 18 include mean of subbands;
    % 20 = option 19 + PCA;
    % 21 = interlevel product
    
blurType = 'gaussian';%'motion';% 'disk';

if strcmpi(blurType,'motion')
    blurRange = [0 1:0.5:5];%0:0.1875:1.5;% 0:0.25:2;
    angleRange = 75;%[5 23 45 75 86]; %
elseif strcmpi(blurType,'gaussian')
    blurRange = [0 1];%[0 0.5 0.75 1];
    angleRange = 0;
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
elseif (option ==17)
    totalFeatures = 6*(2^((wlevels-2)*2));
elseif (option >=18)&&(option ~= 21)
    if numfeatures==0
        totalFeatures = 6*(2^((wlevels-l_0+1)*2));
    else
        totalFeatures = 6*ceil(numfeatures/6);
    end
    if (option==19)||(option==20)
        totalFeatures = totalFeatures + totalFeatures/6;
        includeavg = 1;
    end
elseif (option == 21)
    totalFeatures = 6*(2^((wlevels-l_0+1)*2));
elseif option == 5
    totalFeatures = 150-3;%198;
else
    totalFeatures = 2^(wlevels*2);
end

% open record files
for k = 1:length(angleRange)
    angle = angleRange(k);
    recordAcc{k} = zeros(100,1);
    numTest{k}   = zeros(100,1);
    % record results
    if (option >=18)
        name{k} = [rootDir,kernelType,'LAVA',num2str(resizeRatio),'_DTCWTopt',...
            num2str(option),blurType,'_',num2str(angle),'w',num2str(l_0),num2str(wlevels),'nf',num2str(numfeatures),'.txt'];
    else
        name{k} = [rootDir,kernelType,'LAVA',num2str(resizeRatio),'_DTCWTopt',num2str(option),blurType,'_',num2str(angle),'w',num2str(wlevels),'.txt'];
    end
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
wrongclass = zeros(25,totalBlurRange);
for probcase = 1:50
    % read training
    trainInd = dlmread([rootDir,'problem',num2str(probcase),'train.txt']);
    totalClass = size(trainInd,1);
    totalTrain = size(trainInd,2);
    % extract feature
    trainingFeatures = zeros(totalTrain*totalClass,totalFeatures);
    count = 1; trainingLabels = [];
    for cnum = 1:totalClass
        for k = 1:totalTrain
            % read image
            imgname = ['T',sprintf('%02s',num2str(cnum)),'_',sprintf('%02s',num2str(trainInd(cnum,k)))];
            img = imresize(imread([rootDir,'images\',imgname,'.jpg']),resizeRatio);

            if option == 3
                trainingFeatures(count,1:2*(6*wlevels + wlevels)) = histCWT(img,wlevels,0,biort,qshift);
                trainingFeatures(count,2*(6*wlevels + wlevels)+1:end) = histCWT(img,wlevels,2,biort,qshift);
            elseif option == 6
                trainingFeatures(count,1:2*(6*wlevels + wlevels)) = histCWT(img,wlevels,0,biort,qshift);
                trainingFeatures(count,2*(6*wlevels + wlevels)+1:end) = histCWT(img,wlevels,1,biort,qshift);
            elseif option == 15
                trainingFeatures(count,:) =  binaryUDTCWT(img,wlevels);
            elseif option == 17
                trainingFeatures(count,:) =  binaryUDTCWT(img,wlevels,3);
            elseif option == 18
                trainingFeatures(count,:) =  binaryUDTCWT(img,wlevels,l_0,numfeatures);
            elseif (option >= 19)&&(option ~= 21)
                trainingFeatures(count,:) =  binaryUDTCWT(img,wlevels,l_0,numfeatures,includeavg);
            elseif option == 21
                trainingFeatures(count,:) =  binaryUDTCWTinterlevel(img,wlevels,l_0);
            else
                trainingFeatures(count,:) = histCWT(img,wlevels,option,biort,qshift);
            end
            count = count + 1;
            trainingLabels = [trainingLabels; cnum];
        end
    end
    if usePCA
        shiftdataPCA = mean(trainingFeatures);
        [coefPCA,score,latent] = princomp(trainingFeatures - repmat(shiftdataPCA,[length(trainingLabels) 1]));
        if numfeatures==0
            dimchoose = (cumsum(latent)./sum(latent))<0.999;
            maxNumFeatures = sum(dimchoose);
        end
        trainingFeatures = score(:,1:maxNumFeatures);
    end
    % svm training
    if strcmpi(kernelType,'linear')
        [modelTexture, scaling1, scaling2, ~, ~, accTrain] = getModelfromTraining(trainingFeatures, trainingLabels, 'linear', [], [], 0, 1);
    else
        [modelTexture, scaling1, scaling2, ~, ~, accTrain] = getModelfromTraining(trainingFeatures, trainingLabels, 'rbf', [], [], 0, 1);
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
            testingFeatures = zeros(totalTest*totalClass,totalFeatures);
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
                    if option == 3
                        testingFeatures(count,1:2*(6*wlevels + wlevels)) = histCWT(img,wlevels,0);
                        testingFeatures(count,2*(6*wlevels + wlevels)+1:end) = histCWT(img,wlevels,2);
                    elseif option == 6
                        testingFeatures(count,1:2*(6*wlevels + wlevels)) = histCWT(img,wlevels,0);
                        testingFeatures(count,2*(6*wlevels + wlevels)+1:end) = histCWT(img,wlevels,1);
                    elseif option == 15
                        testingFeatures(count,:) =  binaryUDTCWT(img,wlevels);
                    elseif option == 17
                        testingFeatures(count,:) =  binaryUDTCWT(img,wlevels,3);
                    elseif option == 18
                        testingFeatures(count,:) =  binaryUDTCWT(img,wlevels,l_0);
                    elseif (option >= 19)&&(option ~= 21)
                        testingFeatures(count,:) =  binaryUDTCWT(img,wlevels,l_0,numfeatures,includeavg);
                    elseif option == 21
                        testingFeatures(count,:) =  binaryUDTCWTinterlevel(img,wlevels,l_0);
                    else
                        testingFeatures(count,:) = histCWT(img,wlevels,option);
                    end
                    count = count + 1;
                    testingLabels = [testingLabels; cnum];
                end
            end
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
            % record results of each class
            wrongpredict = predictClass~=testingLabels;
            for class = 1:25
                resultclass{class} = predictClass((testingLabels==class)&&(wrongpredict==1))';
                wrongclass(class,numradius) = wrongclass(class,numradius) + sum(wrongpredict(testingLabels==class));
            end
            % record results
            recordAcc{n}(probcase+1,numradius) = accuracy(1);
            numTest{n}(probcase+1,numradius) = totalTest;
        end
        fprintf(fileID{n},'%03d  %.4f  ', probcase, accTrain);
        fprintf(fileID{n},savelist, recordAcc{n}(probcase+1,:));
        fprintf(fileID{n},'\n');
    end
    wrongclass
end

for n = 1:length(angleRange)
    angle = angleRange(n);
    avgAcc1 = mean(recordAcc{n});
    avgAcc2 = sum(recordAcc{n}.*numTest{n})./sum(numTest{n});
    fprintf(fileID{n},'%15s  %.4f  %.4f', 'average testing', avgAcc1, avgAcc2);
end
fclose('all');