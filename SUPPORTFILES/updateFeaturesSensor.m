function [framenumFar,labelFar,featureFar,framenumNear,labelNear,featureNear] = updateFeaturesSensor(curFrameNum,...
                                    framenumFar,labelFar,featureFar,framenumNear,labelNear,featureNear,...
                                    gtImage,curSegMap,recFeatures,curframe, lowcoef, highcoef,maskNear,wlevels)

arealistFar = unique(curSegMap(1:end/2,:));
arealistFar(arealistFar==0) = [];
arealistNear = unique(curSegMap(end/2+1:end,:));
arealistNear(arealistNear==0) = [];
areaallList = recFeatures(:,1)';
for reg = areaallList
    curarea = curSegMap==reg;
    curclass = mode(gtImage(curarea(:)));
    if curclass>0
        if any(arealistFar==reg)
            framenumFar = [framenumFar; curFrameNum];
            labelFar = [labelFar; curclass];
            featureFar = [featureFar; recFeatures(areaallList==reg,2:end)];
        end
        if any(arealistNear==reg)
            framenumNear = [framenumNear; curFrameNum];
            labelNear = [labelNear; curclass];
            featureNear = [featureNear; recFeatures(areaallList==reg,2:end)];
        end
    end
end
if isempty(arealistNear)
    segNear = maskNear.*curSegMap;
    if sum(segNear(:))==0
        segNear = maskNear;
        width = size(segNear,2);
        segNear(:, [1:0.3*width 0.7*width:width]) = 0;
    end
    if isempty(lowcoef)
        % strcmpi(typefeature,'BPUCWT15')
        features = [];
        % for each subband
        for subband = 1:6
            curQsubband = highcoef{subband};
            % histogram
            histQ1 = hist(curQsubband(segNear(:)>0),0:(2^((wlevels-1)*2) - 1));
            histQ1 = histQ1/sum(histQ1);
            features = [features histQ1];
        end
    else
        features = findTextureFeatures(curframe, lowcoef, highcoef, 8, [1 4 5], segNear>0, 0);
    end
    curclass = mode(gtImage(segNear(:)>0));
    if curclass>0
        framenumNear = [framenumNear; curFrameNum];
        labelNear = [labelNear; curclass];
        featureNear = [featureNear; features];
    end
end

