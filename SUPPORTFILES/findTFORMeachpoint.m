function [tform, transformTemp] = findTFORMeachpoint(pointm1,pointm2,width,distance1Sec)

% [tform, transformTemp] = findTFORMeachpoint(pointm1,pointm2,width,distance1Sec)
%       estimate projective transform from each matching point pair.

numFeatures = size(pointm1,2);
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