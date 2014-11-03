% segmentation 
clear all
addpath('../SUPPORTFILES/');
addpath('../REGISTER/');
addpath('../SEG/');
addpath(genpath('../FEATURES/'));
addpath('../CLASSIFICATION/');
addpath('../DTCWT/');
addpath('../HOMOGRAPHY/');
addpath('../PATHCONSISTENCY/');

% input videos 
% -------------------------------------------------------------------------
videoname = 'MVI_0139_a';
videoFile = ['C:\Locomotion\videos\walking 60 degree\',videoname,'.avi'];

% which process to run
% -------------------------------------------------------------------------
processNum =1;     % 1 = segmentation
                    % 2 = warp segmentation
                    % 3 = fill undefined class

% segmentation parameters
% -------------------------------------------------------------------------
segscaling = 2;
wlevels = 4;
hmindepthfactor = 0.25; % this controls the size of the inital "pre-merging
% segmentation number of regions
% use 0.2 for scaling of 5
% use 0.3 for scaling of 4
t1= 0.9; t2= 0.75; t3 = 3000; %t1 and t2 are usual merging thresholds (do
% however t3 is the minimum size of region and can be changed change
% hmindepthfactor=0.15,t2=0.8 more # regions, so merge more

% read video
% -------------------------------------------------------------------------
display('.....Reading video object');
videoObj = VideoReader(videoFile);
% video parameters
totalFrames = videoObj.NumberOfFrames;
height = videoObj.Height; if height==1088 height=1080; end
width  = videoObj.Width;
framerate = videoObj.Framerate;


% segmentation step for each frame
% -------------------------------------------------------------------------
if processNum == 1
    for curFrameNum = 16:15:780%totalFrames
        curFrameNum
        % read frame
        rgb = im2double(read(videoObj,curFrameNum));
        rgb = rgb(1:height,:,:);
        % convert to grayscale
        yuv = rgb2ycbcr(rgb);
        curframe = yuv(:,:,1);
        
        [segMap, segMapSub, intmap] = getSegmentMapFar(curframe, segscaling, wlevels,t1,t2, t3,hmindepthfactor);
        imwrite(uint8(imresize(intmap>0,segscaling)*100), ['C:\Locomotion\videos\walking 60 degree\groundtruth\',videoname,'\segmentmap\f',num2str(curFrameNum),'.png'], 'png');
        imwrite(imresize(rgb,0.25) + repmat(imresize(intmap==0,0.5),[1 1 3]),['C:\Locomotion\videos\walking 60 degree\groundtruth\',videoname,'\segmentmap\r',num2str(curFrameNum),'.png'], 'png');
    end
end

%% TRACKING
if processNum == 2
    for curFrameNum = 1:15:totalFrames
        % read frame
        rgb = im2double(read(videoObj,curFrameNum));
        rgb = rgb(1:height,:,:);
        % convert to grayscale
        yuv = rgb2ycbcr(rgb);
        prevframe = yuv(:,:,1);
        % read segmap
        segmap = double(imread(['C:\Locomotion\videos\walking 60 degree\groundtruth\',videoname,'\segmentmap\f',num2str(curFrameNum),'.png']));
        if size(segmap,3)>1
            segmap = segmap(:,:,2);
        end
        segmap = segmap.*bwmorph(segmap>0,'erode');
        segmap = round(segmap/100);
        namet = getNameFromClock;
        imwrite((imresize(repmat(segmap/6,[1 1 3])+rgb,0.25)),...
            ['C:\Locomotion\videos\walking 60 degree\groundtruth\',videoname,'\temp\f',namet,'.png'], 'png');
        for subframe = (curFrameNum-1) + (2:15)
            subframe
            % read frame
            rgb = im2double(read(videoObj,subframe));
            rgb = rgb(1:height,:,:);
            % convert to grayscale
            yuv = rgb2ycbcr(rgb);
            curframe = yuv(:,:,1);
            % warp
            newseg = zeros(height,width);
            for classnum = 1:3
                curclass = segmap==classnum;
                [labelmap nummap] = bwlabel(curclass>0);
                for reg = 1:nummap
                    cursubreg = double(labelmap==reg);
                    smallcursubreg = imresize(cursubreg,0.5);
                    [A,T] = opticalflow(imresize(curframe,0.5),imresize(prevframe,0.5),smallcursubreg, 3);
                    temp = warp(smallcursubreg, A, T );
                    temp = imresize(temp,2);
                    newseg(temp>0.50) = classnum;
                end
            end
            imwrite(uint8(newseg*100), ['C:\Locomotion\videos\walking 60 degree\groundtruth\',videoname,'\segmentmap\f',num2str(subframe),'.png'], 'png');
            namet = getNameFromClock;
            imwrite((imresize(repmat(newseg/6,[1 1 3])+rgb,0.25)), ...
                ['C:\Locomotion\videos\walking 60 degree\groundtruth\',videoname,'\temp\f',namet,'.png'], 'png');
            segmap = newseg;
            prevframe = curframe;
        end
    end
end

%% CLASSIFICATION

if processNum == 3
    % segment parameters
    [farRangei,farRangej,template6rg, htemplate, wtemplate] = getDefaultPosition(height, width);

    for curFrameNum = 1:totalFrames
        curFrameNum
        % read frame
        rgb = im2double(read(videoObj,curFrameNum));
        rgb = rgb(1:height,:,:);
        % convert to grayscale
        yuv = rgb2ycbcr(rgb);
        curframe = yuv(:,:,1);
        % read segmentation
        iniseg = double(imread(['C:\Locomotion\videos\walking 60 degree\groundtruth\',videoname,'\segmentmap\f',num2str(curFrameNum),'.png']));
        if size(iniseg,3)>1
            iniseg = iniseg(:,:,2);
        end
        iniseg = round(iniseg/100);
        newSeg = zeros(height,width);
        if rem(curFrameNum,15)~=1
            maskToFill = imclose(iniseg==0, strel('disk',3));
            % segmentation
            [segMap, segMapSub] = getSegmentMapFar(curframe, 5, 4,0.9,0.8, 1000,0.2,...
                farRangei,farRangej,ones(size(curframe(farRangei,farRangej))),template6rg);
            % run classification
            areatorun = unique(segMap(maskToFill(:)>0));
            areatorun(areatorun==0) = [];
            addSeg = zeros(size(segMap));
            for reg = areatorun'
                curarea = bwmorph(segMap==reg,'erode');
                if sum(curarea(:))>1000
                    overlaparea = iniseg.*curarea;
                    overlapclass = mode(overlaparea(overlaparea(:)>0));
                    addSeg(curarea) = overlapclass;
                end
            end
            % refine
            newSeg = iniseg + bwmorph(iniseg==0,'erode').*addSeg;
        else
            newSeg = iniseg;
        end
        newSeg1 = newSeg;
        for classnum = 1:3
            curarea = newSeg1==classnum;
            curarea = bwmorph(curarea, 'close');
            curarea = bwmorph(curarea, 'open');
            curarea = bwareaopen(curarea, 100);
            curarea = imfill(curarea,'holes');
            newSeg(curarea) = classnum;
        end
        % write results
        imwrite(uint8(newSeg*100), ['C:\Locomotion\videos\walking 60 degree\groundtruth\',videoname,'\segmentmap2\f',num2str(curFrameNum),'.png'], 'png');
    end
end
