% This code is for estimating duration with the current speed to reach to selected location
% using instance Homography estimation using features on the ground
% -------------------------------------------------------------------------

clear all

% input video
% -------------------------------------------------------------------------
videoFile = 'C:\Locomotion\videos\moving videos\bricks1pm_CANON480p30fps.avi';
videoObj = VideoReader(videoFile);
% read two frames - duration 1 second
frame1 = read(videoObj, 140);
frame2 = read(videoObj, 170);

% dimension
[h w d] = size(frame1);
udata = [1 w];  vdata = [1 h];  % input coordinate system

% find translation between 2 frames
if size(frame1,3)>1
    gframe1 = rgb2gray(frame1);
    gframe2 = rgb2gray(frame2);
end
[optimizer, metric] = imregconfig('monomodal');

[~, tformRegis] = imregisterMo(gframe2(1:end/2,:),gframe1(1:end/2,:),'rigid',optimizer,metric);
frame2Registered = imtransform(gframe2, tformRegis, 'XData', udata, 'YData', vdata, 'Size', [h w]);

%% Estimate time to selected point

[x_cur, y_cur] = selectPoint(frame1,1,'please select position to time estimation');
rangej = w/2 + (-1:1);
rangei = [y_cur h];

% fix projective distance
numFeatures = 4;
distance1Sec = 100;
estTime = zeros(1,numFeatures);
for k = 1:numFeatures
    [x_pos, y_pos] = selectPoint(frame1,1,'please select feature point');
    if x_pos < w/2
        x_pos(2) = w - x_pos(1);
    else
        x_pos(2) = x_pos(1);
        x_pos(1) = w - x_pos(2);
    end
    y_pos(2) = y_pos(1);
    
    [x_pos(3), y_pos(3)] = selectPoint(frame2Registered,1,'please select feature point corresponding to previous one');
    if x_pos(3) < w/2
        x_pos(4) = x_pos(3);
        x_pos(3) = w - x_pos(4);
    else
        x_pos(4) = w - x_pos(3);
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
    tform = maketform('projective',curXorig,curXproj);
    [x_proj,y_proj] = tformfwd(tform,[rangej(1); rangej(end); rangej(end); rangej(1);],...
        [rangei(1); rangei(1); rangei(end); rangei(end)]);
    estDistance = mean(y_proj(3:4))-mean(y_proj(1:2));
    estTime(k) = estDistance/distance1Sec;
end

% estimated time
finalTime = mean(estTime)
