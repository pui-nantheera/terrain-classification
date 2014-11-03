clear all
addpath('C:\Locomotion\code_motion\CLASSIFICATION');
addpath('C:\Locomotion\code_motion\SUPPORTFILES');
addpath('C:\Locomotion\code_motion\FEATURES\disCLBP');
addpath('C:\Locomotion\code_motion\FEATURES');

rootDir = 'C:\Locomotion\temp\LPQ\project LAVA\';
kernelType = 'linear';%'rbf';%
resizeRatio = 0.5;
usePCA = 0;

blurType = 'motion';%'motion';% 'disk';

if strcmpi(blurType,'motion')
    blurRange = [0 1:0.5:5];%0:0.1875:1.5;% 0:0.25:2;
    angleRange = [5 23 45 75 86]; %
elseif strcmpi(blurType,'gaussian')
    blurRange = [0 0.5 0.75 1];%[0 0.5 0.75 1];
    angleRange = 0;
end

if isempty(blurType)
    blurRange = 1;
end
totalBlurRange = length(blurRange);
totalFeatures = 59;
% open record files
% -------------------------------------------------------------------------
for k = 1:length(angleRange)
    angle = angleRange(k);
    recordAcc{k} = zeros(100,1);
    numTest{k}   = zeros(100,1);
    % record results
    name{k} = [rootDir,kernelType,'LAVA',num2str(resizeRatio),'_LBP',blurType,'_',num2str(angle),'.txt'];
    fileID{k} = fopen(name{k},'a');
    if  isempty(blurType)
        fprintf(fileID{k},'%3s  %7s  %7s\n', 'pb#', 'train', 'test');
    else
        fprintf(fileID{k},'%4s  ', 'blur');
        for bi = 1:50
            fprintf(fileID{k},'%7s  ', num2str(bi));
        end
        fprintf(fileID{k},'\n');
    end
end
% find features for all images
% -------------------------------------------------------------------------
savename =  [rootDir,'LAVA',num2str(resizeRatio),'_LBP.mat'];
if exist(savename,'file')==0
    allFeatures = cell(25,40);
    for cnum = 1:25
        for k = 1:40
            imgname = ['T',sprintf('%02s',num2str(cnum)),'_',sprintf('%02s',num2str(k))];
            img = imresize(imread([rootDir,'images\',imgname,'.jpg']),resizeRatio);
            allFeatures{cnum,k} =  findLBPhist(img);
        end
    end
    save(savename,'allFeatures');
else
    load(savename);
end
% run classification
% -------------------------------------------------------------------------
wrongclass = zeros(25,totalBlurRange);
for n = 1:length(angleRange)
    angle = angleRange(n);
    for numradius = 1:totalBlurRange
        radius = blurRange(numradius);
        fprintf(fileID{n},'%4s  ', num2str(radius));
        % find features for blur images
        % -------------------------------------------------------------------------
        savename =  [rootDir,'LAVA',num2str(resizeRatio),'_LBP',...
            'angle',num2str(angle),'radius',num2str(radius),'.mat'];
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
                    allFeaturesblur{cnum,k} = findLBPhist(img);
                end
            end
            save(savename,'allFeaturesblur');
        else
            load(savename);
        end
        
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