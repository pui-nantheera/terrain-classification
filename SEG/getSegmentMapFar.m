function [segMap, segMapSub, mapwithborder, largeArea] = getSegmentMapFar(curframe, segscaling, wlevels,t1,t2, t3,hmindepthfactor,...
                                    farRangei,farRangej,maskborder, template6rg)


smallCurframe = imresize(curframe,1/segscaling);
[~,~,segMap,~, ~, mapwithborder]=cmssegmm(smallCurframe*255, smallCurframe*255, [], wlevels,t1,t2, t3,hmindepthfactor,1,1);
totalRegNearion = max(segMap(:));
segMap = round(imresize(segMap/totalRegNearion,segscaling)*totalRegNearion);
largeArea = zeros(1,1);
% adjust area if it's too large as in the training data is smaller
if nargin > 7
    segMapSub = segMap(farRangei,farRangej);
    listRegFartemp = unique(segMapSub(maskborder(:)>0));
    listRegFartemp(listRegFartemp==0) = [];
    totalRegFartemp = length(listRegFartemp);
    maxVal = max(listRegFartemp(:));
    largeAreaInd = [];
    count = 1;
    for k = 1:totalRegFartemp
        if sum(segMapSub(:)==listRegFartemp(k)) > 0.5*numel(segMapSub)
            % record splited area
            largeAreanum = unique(template6rg(segMapSub(:)==listRegFartemp(k))+maxVal);
            segMapSub(segMapSub==listRegFartemp(k)) = template6rg(segMapSub==listRegFartemp(k))+maxVal;
            newareaindx = unique(template6rg(segMapSub==listRegFartemp(k)));
            largeAreaInd = [largeAreaInd; largeAreanum];
            maxVal = maxVal + 6;
            count = count + 1;
        end
    end
    largeArea = zeros(1, max(listRegFartemp));
    largeArea(largeAreaInd) = 1;
else
    segMapSub = segMap;
end