function biggestArea = findBiggestArea(segMap)
% find maximum area in segMap

if max(segMap(:))<=1
     [segMap, segMapNum] = bwlabel(segMap);
else
    segMapNum = max(segMap(:));
end

areaSize = zeros(1,segMapNum);
for k = 1:segMapNum
    curArea = segMap==k;
    areaSize(k) = sum(curArea(:));
end
[~,ind] = max(areaSize);
biggestArea = segMap==ind;