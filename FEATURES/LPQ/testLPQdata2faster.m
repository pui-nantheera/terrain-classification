clear all
addpath('C:\Locomotion\code_motion\CLASSIFICATION');
addpath('C:\Locomotion\code_motion\SUPPORTFILES');

rootDir = 'C:\Locomotion\temp\LPQ\project LAVA\';
kernelType = 'linear';%'rbf';%
resizeRatio = 1;
usePCA = 0;
option  = 1; % 0 = LPQ
% 1 = rotation invariant Local Phase Quantization (LPQ)
numOrientations = 36;
LPQfilters = createLPQfilters(9,numOrientations,2);
blurType = 'motion';%'motion';% 'disk';
startprob = 1;
lastprob = 50;
totalFeatures = 256;
if strcmpi(blurType,'motion')
    blurRange = [0 1:10];% [0 1:0.5:5 6 7 8];
    angleRange = [5 23 45 75 86]; %
elseif strcmpi(blurType,'gaussian')
    blurRange = 0.75;%0:0.5:2;%[0 0.5 0.75 1];
    angleRange = 0;
end

if isempty(blurType)
    blurRange = 1;
end
totalBlurRange = length(blurRange);

% open record files
% -------------------------------------------------------------------------
for k = 1:length(angleRange)
    angle = angleRange(k);
    recordAcc{k} = zeros(100,1);
    numTest{k}   = zeros(100,1);
    % record results
    name{k} = [rootDir,kernelType,'LAVA',num2str(resizeRatio),'_LPQopt',num2str(option),blurType,'_',num2str(numOrientations),'orient','_',num2str(angle),'.txt'];
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
savename =  [rootDir,'LAVA',num2str(resizeRatio),'_LPQopt',num2str(option),'_',num2str(numOrientations),'orient','.mat'];
if exist(savename,'file')==0
    allFeatures = cell(25,40);
    for cnum = 1:25
        for k = 1:40
            imgname = ['T',sprintf('%02s',num2str(cnum)),'_',sprintf('%02s',num2str(k))];
            img = imread([rootDir,'images\',imgname,'.jpg']);
            if resizeRatio~=1
                img = imresize(img,resizeRatio);
            end
            if option == 1
                allFeatures{cnum,k} = ri_lpq(img,LPQfilters);
            else
                allFeatures{cnum,k} = lpq(img,3);
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
for probcase = startprob:lastprob
    for n = 1:length(angleRange)
        angle = angleRange(n);
        for numradius = 1:totalBlurRange
            radius = blurRange(numradius);
            
            % find features for blur images
            % -------------------------------------------------------------------------
            if radius==0
                % for sharp image
                allFeaturesblur = allFeatures;
            else
                savename =  [rootDir,'LAVA',num2str(resizeRatio),'_LPQopt',num2str(option),'_',num2str(numOrientations),'orient_',...
                    'angle',num2str(angle),'radius',num2str(radius),'.mat'];
                if exist(savename,'file')==0
                    allFeaturesblur = cell(25,40);
                    for cnum = 1:25
                        for k = 1:40
                            imgname = ['T',sprintf('%02s',num2str(cnum)),'_',sprintf('%02s',num2str(k))];
                            img = imread([rootDir,'images\',imgname,'.jpg']);
                            if resizeRatio~=1
                                img = imresize(img,resizeRatio);
                            end
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
                                allFeaturesblur{cnum,k} = ri_lpq(img,LPQfilters);
                            else
                                allFeaturesblur{cnum,k} = lpq(img,3);
                            end
                        end
                    end
                    save(savename,'allFeaturesblur');
                else
                    load(savename);
                end
            end
            
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