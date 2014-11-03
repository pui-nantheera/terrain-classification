function [framenumFar,labelFar,featureFar,framenumNear,labelNear,featureNear] = updateFeaturesNearArea(curFrameNum,...
    framenumFar,labelFar,featureFar,framenumNear,labelNear,featureNear,...
    curSegMap,recFeatures,maskNear,classTrack,currentFrameInd)

temp = maskNear==2;
arealistNear = unique(curSegMap.*temp);
arealistNear(arealistNear==0) = [];
for reg = arealistNear'
    if reg <= length(recFeatures)
        if ~isempty(recFeatures{reg})
            curFeatures = recFeatures{reg}(:,2:end);
            nearArea = recFeatures{reg}(:,1);
            numNear = sum(nearArea>0);
            numFar  = sum(nearArea==0);
            curclass = classTrack(currentFrameInd,reg);
            if (curclass>0)
                if numFar > 0
                    framenumFar = [framenumFar; repmat(curFrameNum,[numFar 1])];
                    labelFar = [labelFar; repmat(curclass,[numFar 1])];
                    featureFar = [featureFar; curFeatures(nearArea==0,:)];
                end
                % near area
                if numNear > 0
                    framenumNear = [framenumNear; repmat(curFrameNum,[numNear 1])];
                    labelNear = [labelNear; repmat(curclass,[numNear 1])];
                    featureNear = [featureNear; curFeatures(nearArea>0,:)];
                end
                recFeatures{reg} = [];
            end
        end
    end
end
% remove redundant
if ~isempty(featureFar)
    [~, ind] = unique(featureFar,'rows');
    if length(ind)<length(framenumFar)
        framenumFar = framenumFar(ind);
        labelFar = labelFar(ind);
        featureFar = featureFar(ind,:);
    end
end
if ~isempty(featureNear)
    [~, ind] = unique(featureNear,'rows');
    if length(ind)<length(framenumNear)
        framenumNear = framenumNear(ind);
        labelNear = labelNear(ind);
        featureNear = featureNear(ind,:);
    end
end