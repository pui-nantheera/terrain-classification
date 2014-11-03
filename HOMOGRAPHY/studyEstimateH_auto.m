% This code is for estimating duration with the current speed to reach to selected location
% using instance Homography estimation using features on the ground
% These features are detected automatically using harris method
% -------------------------------------------------------------------------

clear all

addpath('../FEATURES/');

% input video
% -------------------------------------------------------------------------
videoFile = 'C:\Locomotion\videos\moving videos\bricks1pm_CANON480p30fps.avi';
videoObj = VideoReader(videoFile);
% read two frames - duration 1 second
frame1 = read(videoObj, 140);
frame2 = read(videoObj, 170);

% dimension
[height width d] = size(frame1);
udata = [1 width];  vdata = [1 height];  % input coordinate system

% find translation between 2 frames
if size(frame1,3)>1
    gframe1 = rgb2gray(frame1);
    gframe2 = rgb2gray(frame2);
end
[optimizer, metric] = imregconfig('monomodal');

tformRegis = imregisterMo(gframe2(1:end/2,:),gframe1(1:end/2,:),'rigid',optimizer,metric);
frame2Registered = imtransform(gframe2, tformRegis, 'XData', udata, 'YData', vdata, 'Size', [height width]);

%% Feature detection and matching

thresh = []; % using DT-CWT keypoints; 30;
im1 = im2double(gframe1);
im2 = im2double(frame2Registered);

% range for first image and the second image
rangey{1} = 0.65*height:0.8*height;
rangey{2} = 0.7*height:height;
% range for left {1} and right {2}
rangex{1} = 1:width/2;
rangex{2} = width/2+1:width;

% run feature detection and matching using homography constraints
[pointm1, pointm2, H] = findGroundFeatures(im1, im2, rangey, rangex, thresh, 1);

%% Get tform for all points

% fix projective distance
numFeatures = size(pointm1,2);
distance1Sec = 100;
estTime = zeros(1,numFeatures);
transformTemp = zeros(3,3,numFeatures);
clear tform
for k = 1:numFeatures
    
    x_pos = pointm1(2,k);
    y_pos = pointm1(1,k);
    if x_pos < width/2
        x_pos(2) = width - x_pos(1);
    else
        x_pos(2) = x_pos(1);
        x_pos(1) = width - x_pos(2);
    end
    y_pos(2) = y_pos(1);
    
    x_pos(3) = pointm2(2,k);
    y_pos(3) = pointm2(1,k);
    if x_pos(3) < width/2
        x_pos(4) = x_pos(3);
        x_pos(3) = width - x_pos(4);
    else
        x_pos(4) = width - x_pos(3);
    end
    y_pos(4) = y_pos(3);
    
    % assuming in 1 second with current speed the ground distance is
    % y_pos(3)-y_pos(1) - this can be used as scaling
    % ex. at speed V, the ground distance S will equal to V.
    % so scaling = V/(y_pos(3)-y_pos(1))
    projy1 = mean(y_pos(1:2));
    projy2 = projy1 + distance1Sec;
    projx1 = min(x_pos([1 4]));
    projx2 = max(x_pos(2:3));
    curXproj = [projx1 projy1; projx2 projy1; projx2 projy2; projx1 projy2];
    
    % estimate H
    % -------------------------------------------------------------------------
    curXorig  = [x_pos' y_pos']; % camera plane
    tform{k} = maketform('projective',curXorig,curXproj);
    transformTemp(:,:,k) = tform{k}.tdata.T;
end

%% estimate final H

% rank min to max
[val, ind] = sort(transformTemp,3);
ignoreInd = val(:,:,1)==val(:,:,2);
ind(:,:,1) = ind(:,:,1).*~ignoreInd;
ignoreInd = val(:,:,end)==val(:,:,end-1);
ind(:,:,end) = ind(:,:,end).*~ignoreInd;
maybeBad = [ind(:,:,1) ind(:,:,end)];
maybeBad(maybeBad==0) = [];
% find bad indx
badIndx = unique(maybeBad);
nBad = histc(maybeBad, badIndx);
badIndx = badIndx(nBad>3);
% get average transform matrix
transformTemp(:,:,badIndx) = 0;
avgT = sum(transformTemp,3)/(length(tform)-length(badIndx));

tformAvg = tform{1};
tformAvg.tdata.T = avgT;
tformAvg.tdata.Tinv = inv(tformAvg.tdata.T);

% show projective image
Bi = imtransform(frame1,tformAvg,'bicubic','udata',udata,'vdata',vdata,'fill',0,'XData', udata, 'Ydata',vdata);
figure; imshow(Bi)

%% Estimate time to selected point

[x_cur, y_cur] = selectPoint(frame1,1,'please select position to time estimation');
rangej = width/2 + (-1:1);
rangei = [y_cur height];
for k = 1:numFeatures
    [x_proj,y_proj] = tformfwd(tform{k},[rangej(1); rangej(end); rangej(end); rangej(1);],...
        [rangei(1); rangei(1); rangei(end); rangei(end)]);
    estDistance = mean(y_proj(3:4))-mean(y_proj(1:2));
    estTime(k) = estDistance/distance1Sec;
end

% estimate time from all tform
meanTime = mean(estTime);
stdTime = std(estTime);
getIndx = (estTime > (meanTime-stdTime)) & (estTime < (meanTime+stdTime)) & (estTime > 0);
finalTimeAllH = mean(estTime(getIndx))

% estimate time from estimated H
[x_proj,y_proj] = tformfwd(tformAvg,[rangej(1); rangej(end); rangej(end); rangej(1);],...
        [rangei(1); rangei(1); rangei(end); rangei(end)]);
estDistance = mean(y_proj(3:4))-mean(y_proj(1:2));
finalTimeAvgH = estDistance/distance1Sec