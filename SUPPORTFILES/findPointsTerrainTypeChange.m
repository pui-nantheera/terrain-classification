function [indi, indj] = findPointsTerrainTypeChange(edgeMap, pointsPerLine, maxGap, display)

% [posEdge_i, posEdge_j] = findPointsTerrainTypeChange(edgeMap, maxGap)
%   find the points on the edge of 'edgeMap' with number of each boundary 'pointsPerLine' and 
%   maximum distance between point 'maxGap'

if nargin < 2
    pointsPerLine = 3;
end
if nargin < 3
    maxGap = 30;
end
if nargin < 4
    display = 0;
end

possibilityMap = bwmorph(edgeMap,'thin');
intersecPoints = double(possibilityMap);
intersecPoints(2:end-1,:) = intersecPoints(2:end-1,:) + intersecPoints(1:end-2,:) + intersecPoints(3:end,:);
intersecPoints(:,2:end-1) = intersecPoints(:,2:end-1) + intersecPoints(:,1:end-2) + intersecPoints(:,3:end);
possibilityMap = (possibilityMap - (intersecPoints>3))>0;
% find rep point
[labelPoints, numPoints] = bwlabel(possibilityMap);

indi = []; indj = [];
for k = 1:numPoints
    curBoundary = labelPoints==k;
    [indit,indjt] = find(curBoundary);
    step = max(maxGap,ceil(length(indit)/pointsPerLine));
    range = round(step/2):step:length(indit);
    indi = [indi; indit(range)];
    indj = [indj; indjt(range)];
end

% plot possibility of changing#
if display
    figure; imshow(edgeMap); hold on
    plot(indj, indi, 'xg');
end