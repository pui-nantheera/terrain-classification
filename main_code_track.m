% This is a main function of terrain classification and tracking
% --------------------------------------------------------------
clear all
addpath('./SUPPORTFILES/');
addpath('./REGISTER/');
addpath('./SEG/');
addpath(genpath('./FEATURES/'));
addpath('./CLASSIFICATION/');
addpath(genpath('./DTCWT/'));
addpath('./HOMOGRAPHY/');
addpath('./PATHCONSISTENCY/');

% for debugging
format short

% input video
% -------------------------------------------------------------------------
videoName = 'MVI_0146_a';
videoFile = ['C:\Locomotion\videos\walking 60 degree\',videoName,'\MATLAB\'];

% get groundtruth
% -------------------------------------------------------------------------
gtdir = ['C:\Locomotion\videos\walking 60 degree\groundtruth\',videoName,'\segmentmap2\'];

% frame selection and probability estimation parameters
% -------------------------------------------------------------------------
groupSharpSize = 1; % find sharpest frame between these successive frames
numGroupPrevious = 20;
numGroupForward = 0;
GOP    = 1;
updatemodel = 1;
updatewithsensor = 0;
% weight option 
walkeffect = 1;
pathwt = 1;
weighttype = 'projfreq';
    % 'projfreq','raisedcosine','linear','gaussian','uniform'
    if ~strcmpi(weighttype,'projfreq')
        pathwt = 0;
    end

% get file list from original non updated features
% -------------------------------------------------------------------------
typefeature = 'all';% 'BPUCWT15';%'all';%'riLPQ'; % 'all' or 'best' or 'plus' (using both seg and non seg for training near area)
kernelType = 'rbf';  % classification type ('linear', 'rbf'
outvideoName = ['C:\Locomotion\results\code_motion\',videoName,'\MATLABrefreshonly3_',typefeature,kernelType,'\'];
mkdir(outvideoName)
compareresult = 0;
comparevideoName = 'C:\Locomotion\results\code_motion\cmpTrack1betterseg\'; 
% record results
fileID = fopen([outvideoName,'results.txt'],'a');

% classification parameters
% -------------------------------------------------------------------------
numClassifiers = 2;
genModelTextureClassify = false; % true: generate classification model
% false: load from existing model)
wlevels = 4;    % levels of wavlet decomposition
usePCA = 1;     % for speed up
maxNumFeatures = 12; % if usePCA=1
% list of each class 1. hard surface 2. soft surface
classListFar{1} = {'bricks','cement','metal','tarmac','wood'};
classListFar{2} = {'grass', 'sand', 'soil'};
classListFar{3} = {'nonground'};
totalnumclass = length(classListFar);
classListNear{1} = {'bricks','cement','metal','tarmac','wood'};
classListNear{2} = {'grass', 'sand', 'soil', 'nonground'};
classListNear{3}  = {'nonground'};

% for display class results
numpix = readNumberPix;
% feature index
featureGroupNum = 6; % intensity wavelet lbphist (120 features in total)
featuresListFar = getFeatureListfromFULLtexture(featureGroupNum);
featuresListNear = getFeatureListfromFULLtexture(featureGroupNum, 'plus');
% region to predict
regUsed = 'all'; %'all' or 'biggest'
selmask = strel('disk', 2^(wlevels-1));
% enable features that robust to time
timeconcern = 0;

if strcmpi(typefeature,'riLPQ')
    numOrientations = 12;
    LPQfilters = createLPQfilters(9,numOrientations,2);
elseif strcmpi(typefeature,'BPUCWT15')
    % Paul's UDTCWT
    [Faf, Fsf] = NDAntonB2; %(Must use ND filters for both)
    [af, sf] = NDdualfilt1;
end
% segmentation parameters
% -------------------------------------------------------------------------
segscaling = 5;
hmindepthfactor = 0.2; % this controls the size of the inital "pre-merging
% segmentation number of regions
% use 0.2 for scaling of 5
% use 0.3 for scaling of 4
t1= 0.9; t2= 0.8; t3 = 1000; %t1 and t2 are usual merging thresholds (do
% however t3 is the minimum size of region and can be changed change
% hmindepthfactor=0.15,t2=0.8 more # regions, so merge more

%% read video
% -------------------------------------------------------------------------
display('.....Reading video object');
videoObj = dir([videoFile,'*.bmp']);
% video parameters
totalFrames = length(videoObj);
dummy = imread([videoFile,videoObj(1).name]);
[height, width, depth] = size(dummy);
framerate = 30;%videoObj.Framerate;
% GOP    = round(videoObj.Framerate/2);
ratio = 1/4;

%% weight by frequency
% -------------------------------------------------------------------------
% camera geometry
focalLength = 2.8; % cm
sensorRatio = 4368/3.58; % pixel/cm
Fpixel = focalLength*sensorRatio;
slantdegree = 60;
h_fromground = 1.60; %m

% walking speed
walkingSpeed = 4000/3600; % m/s coverted from km/h

% estimated pixel/frame
speedWalking = Fpixel*walkingSpeed*(cosd(slantdegree)^2)/h_fromground/framerate;
% for weight estimation
rangey = height/2:-1:-height/2;
frey = 1./(Fpixel - rangey.*tand(slantdegree)).^2;
frey = (frey-min(frey))/range(frey);
frex = 1./(Fpixel - rangey.*tand(slantdegree));
frex = (frex-min(frex))/range(frex);
gapPixel = ((Fpixel - rangey.*tand(slantdegree)).^2).*walkingSpeed.*(cosd(slantdegree)^2)./h_fromground./framerate./Fpixel; % per frame


%% generate model for texture/terrain classification
% -------------------------------------------------------------------------
% generate model from precomputed features if directory storing these
% features changed, this function need to be updated.
% currently features are stored in
% 'C:\Locomotion\results\code_motion\forTraining\features'
if numClassifiers > 1
    [modelTextureFar, scaling1far, scaling2far, coefPCAfar, shiftdataPCAfar, maxNumFeaturesFar, varProb] = genModelTexture(...
        true,classListFar,kernelType,'far',featuresListFar,usePCA,maxNumFeatures,1,typefeature,[],timeconcern);
    [modelTextureNear, scaling1near, scaling2near, coefPCAnear, shiftdataPCAnear, maxNumFeaturesNear] = genModelTexture(...
        true,classListNear,kernelType,'near',featuresListNear,usePCA,maxNumFeatures,1, typefeature);
else
    [modelTextureFar, scaling1far, scaling2far, coefPCAfar, shiftdataPCAfar, maxNumFeaturesFar, varProb] = genModelTexture(...
        true,classListFar,kernelType,{'far', 'near'},featuresListFar,usePCA,maxNumFeatures,1,typefeature,[],timeconcern);
    modelTextureNear = modelTextureFar;
    scaling1near = scaling1far;
    scaling2near = scaling2far;
    coefPCAnear = coefPCAfar;
    shiftdataPCAnear = shiftdataPCAfar;
    maxNumFeaturesNear = maxNumFeaturesFar;
end
% record for comparison
modelTextureFarInit = modelTextureFar;
scaling1farInit = scaling1far;
scaling2farInit = scaling2far;
coefPCAfarInit  = coefPCAfar;
shiftdataPCAfarInit  = shiftdataPCAfar;
maxNumFeaturesFarInit = maxNumFeaturesFar;
modelTextureNearInit = modelTextureNear;
scaling1nearInit = scaling1near;
scaling2nearInit = scaling2near;
coefPCAnearInit  = coefPCAnear;
shiftdataPCAnearInit  = shiftdataPCAnear;
maxNumFeaturesNearInit = maxNumFeaturesNear;
% model for path consitency: 1=consistent 2=non-consistent
featurePathType = 6;
[modelPath, scaling1Path, scaling2Path, coefPCAPath, shiftdataPCAPath, maxNumFeaturesPath, varProbPath] = getPathConsistencyModel(...
    kernelType,1,13,1, featurePathType);


% position of near and far areas -  same as cropImageForTraining.m
% -------------------------------------------------------------------------
[farRangei,farRangej,template6rg, htemplate, wtemplate] = getDefaultPosition(height, width);
maskFarAll = zeros(height, width);
maskFarAll(farRangei, farRangej) = 1;
nearRangei = round(2/3*height):height;
nearRangej = round(1/4*width):round(3/4*width);
maskNear   = zeros(height, width);
maskNear(nearRangei,nearRangej) = 1;
maskNear(nearRangei,:) = maskNear(nearRangei,:) + 1;
% marker for stabilised video
marker = zeros(height,width);
marker([1 height],[1 width]) = 1;

% loop first frame of each GOP
% -------------------------------------------------------------------------
startFrame  = 1;
numframeFar2Near = 120;
numframe4Near = 5;
% initial buffers
changeProb = [];
buffersize      = groupSharpSize*(numGroupPrevious+numGroupForward) + 1;
sharpValue      = zeros(1,buffersize);
currentFrameInd = numGroupPrevious+1;

% record walking step pattern 
mingapsharpframe = 5;
maxgapsharpframe = framerate; % at least segment every 1 sec
freqstep = framerate;
steppattern = [];
notsharp = 1;
prevSegFrame = 0;
addnumframe = framerate;
nextsharpframe = startFrame+addnumframe;
recordSharpForSeg = zeros(1, totalFrames);
segFrameList = [];
skipFrameList = [];
checkblurList = [];
numPixels = zeros(1,totalFrames);
accuracyPerFrame = zeros(1,totalFrames);
numPixIndividual = zeros(1,totalFrames);
accuracyIndividual = zeros(1,totalFrames);
labelNear = [];
featureNear = [];
labelFar = [];
featureFar = [];
framenumFar = [];
framenumNear = [];
modelupdateTime = zeros(totalFrames,1);
segmentTime = zeros(totalFrames,1);
warpingTime = zeros(totalFrames,1);
classifyTime = zeros(totalFrames,1);
otherTime = zeros(totalFrames,1);
if ~updatewithsensor
    recFeatures{1} = [];
end
if  startFrame == 1
    fprintf(fileID,'%9s %12s %12s %12s %12s %12s %12s %12s %12s %12s %12s %12s %12s %12s %12s %12s %12s %12s %12s %12s %12s %12s %12s %12s %12s %12s %12s %12s %12s %12s %12s %12s %12s\n',...
        'frameNO.','SegmentTime','WarpingTime','ClassifyTime', 'OtherTime',...
        'accInd', 'numPixInd','accPropose','numPixels',...
        'true_poi1','true_poi2','true_poi3','false_poi1','false_poi2','false_poi3',...
        'true_nei1','true_nei2','true_nei3','false_nei1','false_nei2','false_nei3',...
        'true_pos1','true_pos2','true_pos3','false_pos1','false_pos2','false_pos3',...
        'true_neg1','true_neg2','true_neg3','false_neg1','false_neg2','false_neg3');
end
refreshframe = 0;
% for debugging
checkframe = [5 10 20 31];
    
%% process frame-by-frame
for curFrameNum = startFrame:totalFrames
    
    if any(checkframe==curFrameNum)
        ['check']
    end
    
    % update model
    % ---------------------------------------------------------------------
    tic
    if updatemodel
        % far areas
        if ((curFrameNum > numframeFar2Near)&&(updatewithsensor))||(updatemodel&&(~updatewithsensor))
            if updatewithsensor
                curind = framenumFar<curFrameNum-numframeFar2Near;
            else
                curind = 1:length(labelFar);
            end
            curlabel = labelFar(curind);
            curfeature = featureFar(curind,:);
            if numClassifiers > 1
                [modelTextureFar, scaling1far, scaling2far, coefPCAfar, shiftdataPCAfar, maxNumFeaturesFar, varProb] = genModelTexture(...
                    true,classListFar,kernelType,'far',featuresListFar,usePCA,maxNumFeatures,1,typefeature, [curlabel curfeature], timeconcern);
            else
                [modelTextureFar, scaling1far, scaling2far, coefPCAfar, shiftdataPCAfar, maxNumFeaturesFar, varProb] = genModelTexture(...
                    true,classListFar,kernelType,{'far','near'},featuresListFar,usePCA,maxNumFeatures,1,typefeature, [curlabel curfeature], timeconcern);
            end
        end
        if numClassifiers > 1
            if ((curFrameNum > numframe4Near)&&(updatewithsensor))||(updatemodel&&(~updatewithsensor))
                if updatewithsensor
                    curind = framenumNear<curFrameNum-numframe4Near;
                else
                    curind = 1:length(labelNear);
                end
                curlabel = labelNear(curind);
                curfeature = featureNear(curind,:);
                [modelTextureNear, scaling1near, scaling2near, coefPCAnear, shiftdataPCAnear, maxNumFeaturesNear] = genModelTexture(...
                    true,classListNear,kernelType,'near',featuresListNear,usePCA,maxNumFeatures,0, typefeature, [curlabel curfeature]);
            end
        else
            modelTextureNear = modelTextureFar;
            scaling1near = scaling1far;
            scaling2near = scaling2far;
            coefPCAnear = coefPCAfar;
            shiftdataPCAnear = shiftdataPCAfar;
            maxNumFeaturesNear = maxNumFeaturesFar;
        end
    end
    t = toc;
    modelupdateTime(curFrameNum) = t;
  
    % get pre processing
    % ---------------------------------------------------------------------
    tic;
    % read frame from video
    if (strcmpi(typefeature,'riLPQ')||strcmpi(typefeature,'BPUCWT15'))
        rgb = (imread([videoFile,videoObj(curFrameNum).name]));
    else
        rgb = im2double(imread([videoFile,videoObj(curFrameNum).name]));
    end
    % convert to grayscale
    yuv = rgb2ycbcr(rgb);
    curframe = double(yuv(:,:,1));
    % mask border for pre-stabilised video
    maskborder = sum(rgb,3)==0;
    maskborder(101:end-100,101:end-100) = 0;
    maskborderFrame = (~imreconstruct((marker.*maskborder)>0, maskborder)).*maskFarAll;
    maskborder = maskborderFrame(farRangei,farRangej);
    
    % find sharpness
    % -----------------------------------------------------------------
    curSharpValue = findSharpValue(curframe);
    steppattern = [steppattern curSharpValue];
    recordSharpForSeg(curFrameNum) = curSharpValue;
    if length(steppattern)>5*framerate
        steppattern(1) = [];
    end

    % decide if current frame is too blur to get information out of it
    % ---------------------------------------------------------------------
    if (rem(curFrameNum,GOP)==1)||(GOP==1)
        skipblurframe = 0; % not skip by default
    else
        skipblurframe = 1;
    end
    % check only the frame after start walking assuming half second
    avgSharp = mean(steppattern(max(1,end-2*freqstep(1)):end));
    if (curFrameNum > 0.25*framerate)&&(~skipblurframe)
        % skip if blur than half between min and max in the 2 steps
        currange = max(1,length(steppattern)-2*freqstep(1)):length(steppattern);
        midSharp = 0.5*(max(steppattern(currange)) + min(steppattern(currange)));
        if ((curSharpValue<0.75*midSharp)&&(curSharpValue<0.0025))
            skipblurframe = 1;
        end
        
        % find fundamental freq, predict next sharp frame, and update parameters about walking **************
        [nextsharpframe,freqstep, notsharp, addnumframe] = findNextSharpFrame(curFrameNum, startFrame, framerate, addnumframe, steppattern, ...
            avgSharp, prevSegFrame, mingapsharpframe, maxgapsharpframe, nextsharpframe, freqstep, notsharp, walkeffect, GOP);
        
    end
    t = toc;
    otherTime(curFrameNum) = t;
    
    % Tracking area process
    % ---------------------------------------------------------------------
    tic;
    if curFrameNum > startFrame
        
        curSegMap = runWarpingAreas(curframe, prevframe, prevSegMap, 0.25, 1000, framerate); 
        
        if (rem(curFrameNum,GOP)==1)
            % remove areas occurred from wrong warp (possibly)
            connectedarea = imdilate(curSegMap>0,selmask);
            if any(connectedarea(1,:))>0
                connectedarea(1:10,:) = 1;
            end
            [labelarea, numarea] = bwlabel(connectedarea);
            if numarea>1
                biggestArea = findBiggestArea(connectedarea);
                curSegMap = curSegMap.*biggestArea;
            end
        end
        % update region number
        listRegions = unique(curSegMap);
        listRegions(listRegions<=0) = [];
        % force segmentation - for panning or fast camera motion
        if (length(listRegions)<6)||(sum(sum(curSegMap(farRangei,farRangej)>0))<0.6*length(farRangei)*length(farRangej))
            notsharp = 0;
            nextsharpframe = curFrameNum;
            skipblurframe = 0;
        end
    end
    t = toc;
    warpingTime(curFrameNum) = t;
    
    % Perform segmentation - first frame and every 3 sec that is sharp enough
    % ---------------------------------------------------------------------
    if ((curFrameNum==startFrame)||(curFrameNum==nextsharpframe)||(notsharp==0))&&(~skipblurframe)
        
        % make sure that the sharp frame is used. If current frame isn't
        % sharp enough, skip it and check the next one
        if rem(curFrameNum,1*framerate)==0
            notsharp = 0;
        end
        
        % segmentation process
        if (curSharpValue>=avgSharp)||(curFrameNum==nextsharpframe)||((curFrameNum>nextsharpframe)&&(curSharpValue>prevSharp))
            segFrameList = [segFrameList curFrameNum];
            prevSegFrame = curFrameNum;
            notsharp = 1;
            % reduce size
            display('.....Processing segmentation'); tic 
            % run segmentation ********************************************
            [segMap, segMapSub, ~, largearea] = getSegmentMapFar(curframe, segscaling, wlevels,t1,t2, t3,hmindepthfactor,...
                farRangei,farRangej,maskborder,template6rg);
            
            if curFrameNum > startFrame
                initcurSegMap = curSegMap;
            end
            % remove unused
            curSegMap = zeros(height,width);%segMap.*(curFrameNum>startFrame);
            curSegMap(farRangei,farRangej) = segMapSub.*maskborder;
            
            % merge segment results and tracking
            if curFrameNum > startFrame
                
                if ~isempty(listRegions)
                    refreshframe = 1;
                    % shift label index
                    largearea = [zeros(1,listRegions(end)) largearea];
                    curSegMap = (curSegMap + listRegions(end)).*(curSegMap>0);
                    newListRegions = unique(curSegMap(farRangei,farRangej));
                    newListRegions(newListRegions<=0) = [];
                    
                    % check available region labels
                    unuselabels = 1:listRegions(end);
                    unuselabels(listRegions) = [];
                    % replace curSegMap with available region labels from prev
                    for reg = 1:min(length(newListRegions),length(unuselabels))
                        curSegMap(curSegMap==(newListRegions(end-reg+1))) = unuselabels(reg);
                        largearea(unuselabels(reg)) = largearea(newListRegions(end-reg+1));
                    end
                    newListRegions = unique(curSegMap(farRangei,farRangej));
                    newListRegions(newListRegions<=0) = [];
                    
                    % find overlap regions
                    usedReg = zeros(1,max(listRegions));
                    for reg = newListRegions'
                        % current area from tracking
                        curtrackreg = curSegMap==reg;
                        % find overlap in current seg frame
                        indregion = initcurSegMap(curtrackreg(:));
                        indregion(indregion==0) = [];
                        indregion = mode(indregion);
                        % merge
                        if ~isnan(indregion)
                            classTrack(:,reg) = classTrack(:,indregion);
                            probTrack(reg,:,:) = probTrack(indregion,:,:);
                            if ~updatewithsensor
                                recFeatures{reg} = recFeatures{indregion};
                            end
                        else
                            addcol = listRegions(end)-size(classTrack,2);
                            classTrack = cat(2,classTrack,zeros(buffersize, addcol));
                            probTrack = cat(1,probTrack,zeros(addcol,totalnumclass,buffersize));
                            if ~updatewithsensor
                                recFeatures{listRegions(end)} = [];
                            end
                        end
                        
                    end
                    temp = curSegMap;
                    curSegMap = initcurSegMap;
                    curSegMap(farRangei,farRangej) = temp(farRangei,farRangej);
                    
                    % update index and buffers
                    listRegions = unique(curSegMap);
                    listRegions(listRegions<=0) = [];
                    removedReg = 1:max(listRegions);
                    removedReg(listRegions) = [];
                    classTrack(:,removedReg) = 0;
                    probTrack(removedReg,:,:) = 0;
                    if ~updatewithsensor
                        for rmreg = removedReg
                            recFeatures{rmreg} = [];
                        end
                    end
                else
                    % reset tracked results
                    classTrack(:,:) = 0;
                    probTrack(:,:) = 0;
                    if ~updatewithsensor
                        clear recFeatures
                        recFeatures{1} = [];
                    end
                end
                
                % if new segment, must do prediction
                skipblurframe = 0;
            end
            t = toc;
            segmentTime(curFrameNum) = t;
        end
        
        % initial buffers for class and probability
        if curFrameNum == startFrame
            % record region number
            listRegions = unique(curSegMap);
            listRegions(listRegions<=0) = [];
            % record predict results
            classTrack      = zeros(buffersize,max(listRegions));
            probTrack       = zeros(max(listRegions),totalnumclass,buffersize);
        end
    end
        
    % update predict buffer and path consistency
    % ---------------------------------------------------------------------
    tic;
    if ~skipblurframe
        
        % shift buffers for recursive calculation only if it isn't a skipframe
        % ---------------------------------------------------------------------
        if (curFrameNum>startFrame)
            GOPf = 1;
            % shift class track
            classTrack = cat(1,classTrack(GOPf+1:buffersize,:),zeros(GOPf, size(classTrack,2)));
            % shift probabality buffer
            probTrack = cat(3,probTrack(:,:,GOPf+1:buffersize),zeros(size(probTrack,1), totalnumclass, GOPf));
            % shift sharp value
            temp = circshift([sharpValue zeros(1,GOPf)],[1 -GOPf]);
            sharpValue = temp(1:buffersize);
            sharpValue(currentFrameInd) = curSharpValue;
        else
            sharpValue(currentFrameInd) = curSharpValue;
        end
        
        % compute path consistency probability
        % ---------------------------------------------------------------------
        if pathwt
            [classPath, probPath] = updatePathConsistencyGroup(curframe,featurePathType,modelPath,scaling1Path,scaling2Path,coefPCAPath,...
                shiftdataPCAPath,maxNumFeaturesPath);
        else
            probPath = 1;
            classPath = 1;
        end
        
        % Classification process for each area
        % ---------------------------------------------------------------------
        totalRegions = length(listRegions);
                
        % wavelet transform
        if ~(strcmpi(typefeature,'riLPQ')||strcmpi(typefeature,'BPUCWT15'))
            [lowcoef,highcoef] = dtwavexfm2(curframe,wlevels,'antonini','qshift_06');
        end
        if strcmpi(typefeature,'riLPQ')
            [~ ,quantiseMap] = ri_lpq(curframe,LPQfilters);
        end
        if strcmpi(typefeature,'BPUCWT15')
            w = NDxWav2DMEX(double(curframe), wlevels, Faf, af, 1);
            for level = 1:wlevels
                highcoef{level} = [];
                for c = 1:2
                    for d = 1:3
                        highcoef{level} = cat(3,highcoef{level},w{level}{1}{c}{d} + 1i*w{level}{2}{c}{d});
                    end
                end
            end
            clear w
            % create bitplane
            % for each subband
            for subband = 1:6
                quantiseMap{subband} = zeros(size(curframe));
                for level = 1:wlevels-1
                    curMap = highcoef{level+1}(:,:,subband);
                    quantiseMap{subband} = quantiseMap{subband} + (real(curMap)>0)*(2^((level-1)*2+1-1));
                    quantiseMap{subband} = quantiseMap{subband} + (imag(curMap)>0)*(2^((level-1)*2+2-1));
                end
            end
        end
        
        % predict each region
        classIndividual = zeros(height, width);
        if updatewithsensor
            recFeatures = [];
        end
        for reg = listRegions'
            
            mask = (curSegMap==reg);
            % check if it's in the near area
            isnear = floor(mode(maskNear(mask(:)>0)));
            
            if ((sum(mask(:))>0.15*length(farRangei)*length(farRangej)/10)&&(isnear<2))||...
                    ((sum(mask(:))>0.2*sum(maskNear(:)==2))&&(isnear==2))
                
                % extract features
                % ==============================================================
                % feature extraction
                if strcmpi(typefeature,'riLPQ')
                    LPQdesc=hist(quantiseMap(mask(:)>0),0:255);
                    features = LPQdesc/sum(LPQdesc);

                elseif strcmpi(typefeature,'BPUCWT15')
                    features = [];
                    % for each subband
                    for subband = 1:6
                        curQsubband = quantiseMap{subband};
                        % histogram
                        histQ1 = hist(curQsubband(mask(:)>0),0:(2^((wlevels-1)*2) - 1));
                        histQ1 = histQ1/sum(histQ1);
                        features = [features histQ1];
                    end
                else
                    features = findTextureFeatures(curframe, lowcoef, highcoef, 8, [1 4 5], mask, 0);
                end
                % ==============================================================
                if sum(isnan(features))>0
                    features(isnan(features)) = 0;
                else
                    % record only features from good area
                    if updatewithsensor
                        recFeatures = [recFeatures; reg  features];
                    else
                        if length(recFeatures)<reg
                            recFeatures{reg} = [isnear features];
                        else
                            recFeatures{reg} = [recFeatures{reg};isnear features];
                        end
                    end
                end
                if sum(features(:)) ~= 0
                    if isnear
                        % PCA transform
                        if usePCA
                            scoretesting = (features - shiftdataPCAnear)*coefPCAnear;
                            featurescur = scoretesting(:,1:maxNumFeaturesNear);
                        else
                            featurescur = features;
                        end
                        % normalisation dataset
                        testingData = (featurescur - scaling1near).*scaling2near;
                        [curClass, ~, curProb] = svmpredict(1, testingData, modelTextureNear, '-b 1');
                        if isnear==2
                            curProb(:,3) = 0;
                        end
                    else % far area
                        % PCA transform
                        if usePCA
                            scoretesting = (features - shiftdataPCAfar)*coefPCAfar;
                            featurescur = scoretesting(:,1:maxNumFeaturesFar);
                        else
                            featurescur = features;
                        end
                        % normalisation dataset
                        testingData = (featurescur - scaling1far).*scaling2far;
                        if sum(testingData)>=0
                            [curClass, ~, curProb] = svmpredict(1, testingData, modelTextureFar, '-b 1');
                            % clear buffer if the new area is detected as class
                            % 3 (unwalkable)
                            if refreshframe && (curClass==3) && (largearea(reg)==0)
                                classTrack(:,reg) = 0;
                                probTrack(reg,:,:) = 0;
                                if ~updatewithsensor
                                    recFeatures{reg} = [];
                                end
                            end
                        end
                    end
                    % -------------------------------------------------------------
                    % for individual test
                    if isnear
                        % PCA transform
                        if usePCA
                            scoretesting = (features - shiftdataPCAfarInit)*coefPCAnearInit;
                            featurescur = scoretesting(:,1:maxNumFeaturesNearInit);
                        else
                            featurescur = features;
                        end
                        % normalisation dataset
                        testingData = (featurescur - scaling1nearInit).*scaling2nearInit;
                        curClassInit = svmpredict(1, testingData, modelTextureNearInit, '-b 1');
                        if isnear==2
                            curProb(:,3) = 0;
                        end
                    else
                        % PCA transform
                        if usePCA
                            scoretesting = (features - shiftdataPCAfarInit)*coefPCAfarInit;
                            featurescur = scoretesting(:,1:maxNumFeaturesFarInit);
                        else
                            featurescur = features;
                        end
                        % normalisation dataset
                        testingData = (featurescur - scaling1farInit).*scaling2farInit;
                        if sum(testingData)>=0
                            curClassInit = svmpredict(1, testingData, modelTextureFarInit, '-b 1');
                        end
                    end
                    classIndividual(mask) = curClassInit;
                    % -------------------------------------------------------------
                    curProb(isnan(curProb)) = 0;
                    % current prob from all reference frames
                    if reg<=size(probTrack,1)
                        probGroup = permute(probTrack(reg,:,:),[3 2 1]);
                    else
                        probTrack(reg,:,:) = zeros(1,totalnumclass,buffersize);
                        probGroup = zeros(buffersize,totalnumclass);
                        recFeatures{reg} = [];
                    end
                    probGroup(currentFrameInd,:) = curProb;
                    notuse = sum(probGroup,2) == 0;
                    probGroup(notuse,:) = [];
                    
                    
                    if size(probGroup,1) > 1
                        % combine feature using path consistency weight
                        % -------------------------------------------------------------
                        wt = findDecayedWeight(probGroup,weighttype,mask,probPath,gapPixel,varProb,frey,frex,GOP);
                        
                        % weight from sharpness
                        if walkeffect
                            sharpGroup = sharpValue(~notuse)/max(sharpValue(~notuse));
                            wt = wt.*sharpGroup';
                            wt = wt./sum(wt);
                        end
                        % weight average probability
                        curProb = sum(probGroup.*repmat(wt, [1 totalnumclass]),1);
                    end
                    if isnear==2
                        curProb(:,3) = 0;
                    end
                    % record probability
                    probTrack(reg,:,currentFrameInd) = curProb;
                    [~, classTrack(currentFrameInd,reg)] = max(curProb);
                end
            else
                listRegions(listRegions==reg) = [];
            end
        end
        
        % adjust probability for the new area
        % -------------------------------------------------------------
        if (curFrameNum>startFrame)
            newarea = find((classTrack(end,:)>0)&(classTrack(end-1,:)==0));
            for reg = newarea
                neighbourReg = unique(curSegMap.*bwmorph(curSegMap==reg,'dilate'));
                neighbourReg(neighbourReg<=0) = [];
                curProb = mean([probTrack(reg,:,currentFrameInd); probTrack(neighbourReg,:,currentFrameInd)],1);
                [~,newclass] = max(curProb);
                if classTrack(end,reg)~=newclass
                    classTrack(end,reg) = newclass;
                    probTrack(reg,:,currentFrameInd) = curProb;
                end
            end
        end
    else
        skipFrameList = [skipFrameList curFrameNum];
    end

    processTime = toc;
    display(['.....Done classification for far areas at ',num2str(processTime),' sec']);
    classifyTime(curFrameNum) = processTime;
    
    % draw
    [displayFrame,~,resultMap] = drawClassifyResultCircle([videoFile,videoObj(curFrameNum).name], curFrameNum, height, width, curSegMap, probTrack(:,:,currentFrameInd), classTrack(currentFrameInd,:),...
                        1:height,1:width, ratio, maskborderFrame, regUsed, numpix, listRegions);
    namet = getNameFromClock;
    if compareresult
        tocomparefiles = dir([comparevideoName,'*.png']);
        k = 1;
        while (length(tocomparefiles)<curFrameNum)&&(k<30)
            pause(2);
            tocomparefiles = dir([comparevideoName,'*.png']);
            k = k+1;
        end
        tocompareimage = im2double(imread([comparevideoName,tocomparefiles(curFrameNum).name]));
        tocompareimage = tocompareimage(:,round(size(tocompareimage,2)/3:size(tocompareimage,2)/3*2),:);
        displayFrame = cat(2,displayFrame, repmat(imresize(curSegMap/max(curSegMap(:)),ratio),[1 1 3]));
        imwrite(cat(2,tocompareimage,displayFrame),[outvideoName,'f',namet,'.png'],'png');
    else
        displayFrame = cat(2,displayFrame, repmat(imresize(curSegMap/max(curSegMap(:)),ratio),[1 1 3]));
        imwrite(displayFrame, [outvideoName,'f',num2str(namet),'.png'],'png');
    end
    % read groundtruth
    gtImage = double(imread([gtdir,'f',num2str(curFrameNum),'.png']));
    if size(gtImage,3)>1
        gtImage = gtImage(:,:,2);
    end
    gtImage = round(gtImage/100);
    % compute accuracy
    for class = 1:totalnumclass
        true_positive(class)  = sum((gtImage(:)==class).*(resultMap(:)==class).*(gtImage(:)>0).*(resultMap(:)>0));
        false_positive(class) = sum((gtImage(:)~=class).*(resultMap(:)==class).*(gtImage(:)>0).*(resultMap(:)>0));
        true_negative(class)  = sum((gtImage(:)~=class).*(resultMap(:)~=class).*(gtImage(:)>0).*(resultMap(:)>0));
        false_negative(class) = sum((gtImage(:)==class).*(resultMap(:)~=class).*(gtImage(:)>0).*(resultMap(:)>0));
        true_positive1(class)  = sum((gtImage(:)==class).*(classIndividual(:)==class).*(gtImage(:)>0).*(classIndividual(:)>0));
        false_positive1(class) = sum((gtImage(:)~=class).*(classIndividual(:)==class).*(gtImage(:)>0).*(classIndividual(:)>0));
        true_negative1(class)  = sum((gtImage(:)~=class).*(classIndividual(:)~=class).*(gtImage(:)>0).*(classIndividual(:)>0));
        false_negative1(class) = sum((gtImage(:)==class).*(classIndividual(:)~=class).*(gtImage(:)>0).*(classIndividual(:)>0));
    end
    numPixels(curFrameNum) = sum((gtImage(:)>0).*(resultMap(:)>0));
    accuracyPerFrame(curFrameNum) = sum((gtImage(:)>0).*(resultMap(:)>0).*(resultMap(:)==gtImage(:)))./numPixels(curFrameNum);
    numPixIndividual(curFrameNum) = sum((gtImage(:)>0).*(classIndividual(:)>0));
    accuracyIndividual(curFrameNum) = sum((gtImage(:)>0).*(classIndividual(:)>0).*(classIndividual(:)==gtImage(:)))./numPixIndividual(curFrameNum);
    % record results
    fprintf(fileID,'%9d %.10f %.10f %.10f %.10f %.10f %12d %.10f %12d %12d %12d %12d %12d %12d %12d %12d %12d %12d %12d %12d %12d %12d %12d %12d %12d %12d %12d %12d %12d %12d %12d %12d %12d\n',...
        curFrameNum, segmentTime(curFrameNum),warpingTime(curFrameNum),classifyTime(curFrameNum),otherTime(curFrameNum), ...
        accuracyIndividual(curFrameNum),numPixIndividual(curFrameNum), accuracyPerFrame(curFrameNum),  numPixels(curFrameNum), ...
        true_positive1(1), true_positive1(2), true_positive1(3), false_positive1(1), false_positive1(2), false_positive1(3),...
        true_negative1(1), true_negative1(2), true_negative1(3), false_negative1(1), false_negative1(2), false_negative1(3), ...
        true_positive(1), true_positive(2), true_positive(3), false_positive(1), false_positive(2), false_positive(3),...
        true_negative(1), true_negative(2), true_negative(3), false_negative(1), false_negative(2), false_negative(3));
                  
    % record features
    if updatemodel
        if updatewithsensor
            if strcmpi(typefeature,'BPUCWT15')
                [framenumFar,labelFar,featureFar,framenumNear,labelNear,featureNear] = updateFeaturesSensor(curFrameNum,...
                    framenumFar,labelFar,featureFar,framenumNear,labelNear,featureNear,...
                    gtImage,curSegMap,recFeatures,curframe, [], quantiseMap,maskNear,wlevels);
            else
                [framenumFar,labelFar,featureFar,framenumNear,labelNear,featureNear] = updateFeaturesSensor(curFrameNum,...
                    framenumFar,labelFar,featureFar,framenumNear,labelNear,featureNear,...
                    gtImage,curSegMap,recFeatures,curframe, lowcoef, highcoef,maskNear);
            end
        else
            % record features from near areas
            [framenumFar,labelFar,featureFar,framenumNear,labelNear,featureNear] = updateFeaturesNearArea(curFrameNum,...
                framenumFar,labelFar,featureFar,framenumNear,labelNear,featureNear,...
                curSegMap,recFeatures,maskNear,classTrack,currentFrameInd);
            
        end
        if numClassifiers == 1
            featureFar = [featureFar; featureNear];
            labelFar   = [labelFar; labelNear];
            framenumFar = [framenumFar; framenumNear];
            if ~isempty(featureFar)
                [~, ind] = unique(featureFar,'rows');
                if length(ind)<length(framenumFar)
                    framenumFar = framenumFar(ind);
                    labelFar = labelFar(ind);
                    featureFar = featureFar(ind,:);
                end
            end
        end
    end
    % record previous frame for tracking
    prevframe = curframe;
    prevSharp = curSharpValue;
    prevSegMap = curSegMap; 
    refreshframe = 0;
end
    
fclose('all');
