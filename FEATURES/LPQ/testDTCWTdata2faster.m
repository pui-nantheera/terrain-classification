clear all
addpath('C:\Locomotion\code_motion\CLASSIFICATION');
addpath('C:\Locomotion\code_motion\SUPPORTFILES');

rootDir = 'C:\Locomotion\temp\LPQ\project LAVA\';
kernelType = 'linear';%'rbf';%
weight = [' -w1 2 -w2 2 -w3 3 -w4 100 -w5  1 -w6 4 -w7 1 -w8 2 -w9 1 -w10 1 -w11 1 -w12 2 -w13 1 -w14 5 -w15  1 -w16 1 -w17 1 -w18 2 -w19 1 -w20 1 -w21 2 -w22 2 -w23 3 -w24 2  -w25 1'];
weight = 0;
resizeRatio = 1;
wlevels = 6;
l_0 = 1;
numfeatures = 0;
includeavg = 0;
usePCA = 0;
biort = 'antonini';%'legall';%
qshift = 'qshift_06';%'qshift_06';
option  = 19; % 0 = mean and variance
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
% 16 = option 8 but level 2-wlevels without mean and variance
% 161 = option 8 but level 2-wlevels with mean and variance
% 17 = option 15 but l_0 = 3;
% 18 = option 15 but l_0 = selected;
% 19 = option 18 include mean of subbands;
% 20 = option 19 + PCA;
% 21 = interlevel product
% 22 = option 18 + denoise

blurType = 'motion';%'motion';% 'disk';

if strcmpi(blurType,'motion')
    blurRange = [0 1:10];% [0 1:0.5:5 6 7 8];
    angleRange = [5 23 45 75 86]; %
elseif strcmpi(blurType,'gaussian')
    blurRange = [0 0.5 0.75 1 1.5  2];
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
elseif (option ==16)
    totalFeatures = (2^((wlevels-1)*2));
elseif (option ==161)
    totalFeatures = (2^((wlevels-1)*2)) + 2*(6*(wlevels-1) + (wlevels-1));
elseif (option ==17)
    totalFeatures = 6*(2^((wlevels-2)*2));
elseif (option >=18)&&(option ~= 21)||(option ==22)
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
% -------------------------------------------------------------------------
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
        fprintf(fileID{k},'%4s  ', 'blur');
%         for bi = 1:50
%             fprintf(fileID{k},'%7s  ', num2str(bi));
%         end
        for numradius = 1:totalBlurRange
            radius = blurRange(numradius);
            fprintf(fileID{k},'%4s  ', num2str(radius));
        end
        fprintf(fileID{k},'\n');
    end
end
% find features for all images
% -------------------------------------------------------------------------
if option == 20
    savename =  [rootDir,'LAVA',num2str(resizeRatio),'_DTCWTopt',...
        num2str(option-1),'w',num2str(l_0),num2str(wlevels),'nf',num2str(numfeatures),'.mat'];
else
    savename =  [rootDir,'LAVA',num2str(resizeRatio),'_DTCWTopt',...
        num2str(option),'w',num2str(l_0),num2str(wlevels),'nf',num2str(numfeatures),'.mat'];
end
if exist(savename,'file')==0
    allFeatures = cell(25,40);
    for cnum = 1:25
        for k = 1:40
            imgname = ['T',sprintf('%02s',num2str(cnum)),'_',sprintf('%02s',num2str(k))];
            img = imresize(imread([rootDir,'images\',imgname,'.jpg']),resizeRatio);
            if (wlevels==5)||(wlevels==6)||(wlevels==7)
                load([rootDir,'images\resize',num2str(resizeRatio),'\',imgname,'w',num2str(wlevels),'.mat']);
                if (option == 18)
                    allFeatures{cnum,k} =  binaryUDTCWT(w,wlevels,l_0,numfeatures);
                elseif (option == 22)
                    allFeatures{cnum,k} =  binaryUDTCWTdenoise(w,wlevels,l_0,numfeatures);
                elseif (option==161)
                    allFeatures{cnum,k} = histCWT(w,wlevels,option);
                elseif (option >= 19)&&(option ~= 21)
                    allFeatures{cnum,k} =  binaryUDTCWT(w,wlevels,l_0,numfeatures,includeavg);
                else
                    allFeatures{cnum,k} = histCWT(w,wlevels,option,biort,qshift);
                end
            else
                if (option == 18)
                    allFeatures{cnum,k} =  binaryUDTCWT(img,wlevels,l_0,numfeatures);
                elseif (option == 22)
                    allFeatures{cnum,k} =  binaryUDTCWTdenoise(img,wlevels,l_0,numfeatures);
                elseif (option==161)
                    allFeatures{cnum,k} = histCWT(img,wlevels,option);
                elseif (option >= 19)&&(option ~= 21)
                    allFeatures{cnum,k} =  binaryUDTCWT(img,wlevels,l_0,numfeatures,includeavg);
                else
                    allFeatures{cnum,k} = histCWT(img,wlevels,option,biort,qshift);
                end
            end
        end
    end
    save(savename,'allFeatures');
else
    load(savename);
end
% run classification
% -------------------------------------------------------------------------
wrongclass = zeros(25,totalBlurRange);
% run each problem
% -----------------------------------------------------------------
for probcase = 1:50
    % read training
    % -------------------------------------------------------------
    trainInd = dlmread([rootDir,'problem',num2str(probcase),'train.txt']);
    totalClass = size(trainInd,1);
    totalTrain = size(trainInd,2);
    % extract feature
    trainingFeatures = zeros(totalTrain*totalClass,totalFeatures);
    count = 1; trainingLabels = [];
    for cnum = 1:totalClass
        for k = 1:totalTrain
            trainingFeatures(count,:) = allFeatures{cnum,trainInd(cnum,k)};
            count = count + 1;
            trainingLabels = [trainingLabels; cnum];
        end
    end
    if usePCA
        shiftdataPCA = mean(trainingFeatures);
        [coefPCA,score,latent] = princomp(trainingFeatures - repmat(shiftdataPCA,[length(trainingLabels) 1]));
        if numfeatures==0
            dimchoose = (cumsum(latent)./sum(latent))<0.999;
            maxNumFeatures = sum(dimchoose)
        end
        trainingFeatures = score(:,1:maxNumFeatures);
    end
    % svm training
    [modelTexture, scaling1, scaling2, ~, ~, accTrain] = getModelfromTraining(trainingFeatures, trainingLabels, kernelType, [], [], 0, 1, weight);
    
    for n = 1:length(angleRange)
        fprintf(fileID{n},'%03s  ', num2str(probcase));
        angle = angleRange(n);
        for numradius = 1:totalBlurRange
            radius = blurRange(numradius);
            
            % find features for blur images
            % -------------------------------------------------------------------------
            if radius==0
                % for sharp image
                allFeaturesblur = allFeatures;
            else
                if option == 20
                    savename =  [rootDir,'LAVA',num2str(resizeRatio),'_DTCWTopt',...
                        num2str(option-1),'w',num2str(l_0),num2str(wlevels),'nf',num2str(numfeatures),...
                        'angle',num2str(angle),'radius',num2str(radius),'.mat'];
                else
                    savename =  [rootDir,'LAVA',num2str(resizeRatio),'_DTCWTopt',...
                        num2str(option),'w',num2str(l_0),num2str(wlevels),'nf',num2str(numfeatures),...
                        'angle',num2str(angle),'radius',num2str(radius),'.mat'];
                end
                if exist(savename,'file')==0
                    allFeaturesblur = cell(25,40);
                    for cnum = 1:25
                        for k = 1:40
                            imgname = ['T',sprintf('%02s',num2str(cnum)),'_',sprintf('%02s',num2str(k))];
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
                            if option == 18
                                allFeaturesblur{cnum,k} =  binaryUDTCWT(img,wlevels,l_0,numfeatures);
                            elseif (option == 22)
                                allFeaturesblur{cnum,k} =  binaryUDTCWTdenoise(img,wlevels,l_0,numfeatures);
                            elseif (option==161)
                                allFeaturesblur{cnum,k} = histCWT(img,wlevels,option);
                            elseif (option >= 19)&&(option ~= 21)
                                allFeaturesblur{cnum,k} =  binaryUDTCWT(img,wlevels,l_0,numfeatures,includeavg);
                            else
                                allFeaturesblur{cnum,k} = histCWT(img,wlevels,option,biort,qshift);
                            end
                            
                        end
                    end
                    save(savename,'allFeaturesblur');
                else
                    load(savename);
                end
            end
            
            
            % read testing
            % -------------------------------------------------------------
            testInd = dlmread([rootDir,'problem',num2str(probcase),'test.txt']);
            totalClass = size(testInd,1);
            totalTest = size(testInd,2);
            testingFeatures = zeros(totalTest*totalClass,totalFeatures);
            count = 1; testingLabels = [];
            for cnum = 1:totalClass
                for k = 1:totalTest
                    testingFeatures(count,:) = allFeaturesblur{cnum,testInd(cnum,k)};
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
                resultclass{class} = predictClass((testingLabels==class)&(wrongpredict==1))';
                wrongclass(class,numradius) = wrongclass(class,numradius) + sum(wrongpredict(testingLabels==class));
            end
            % record results
            fprintf(fileID{n},'%.4f  ', accuracy(1));
        end % for probcase 1:50
        fprintf(fileID{n},'\n');
        wrongclass
    end
end
fclose('all');