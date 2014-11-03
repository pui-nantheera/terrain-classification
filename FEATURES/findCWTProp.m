function [cwtParameters,glcmStat,runLengthStat] = findCWTProp(Xl, Xh, getLowProp, bitsperpixel, mask, withphase)

if (nargin < 5)||(isempty(mask))
    mask = ones(size(Xh{1},1)*2,size(Xh{1},2)*2);
end

totalLevel = length(Xh);

% check if resize mark is required
fineBand   = Xh{1}(:,:,1);
coarseBand = Xh{totalLevel}(:,:,1);
if all(size(fineBand)==size(coarseBand))
    mustresize = 0;
    mask = ones(size(fineBand));
else
    mustresize = 1;
end

% gray properties of the low-pass subband
if getLowProp
    glcmStat = findGLCMProp(Xl);
    runLengthStat = findRunLengthProp(Xl, bitsperpixel);
    glcmStat(isnan(glcmStat)) = 0;
    runLengthStat(isnan(runLengthStat)) = 0;
else
    glcmStat = [];
    runLengthStat = [];
end
% properties of the high-pass subband
meanAbs   = [];  varAbs    = [];
meanPhase = [];  varPhase  = [];
meanAbsAll   = [];  varAbsAll    = [];
meanPhaseAll = [];  varPhaseAll  = [];
maskresized = mask; 
for level = 1:totalLevel
    if mustresize
        maskresized = imresize(maskresized,1/2);
    end
    curMask = repmat(maskresized, [1 1 6])>0.5;
    curData = Xh{level};
    meanAbsAll = [meanAbsAll mean(abs(curData(curMask(:))))];
    varAbsAll  = [varAbsAll var(abs(curData(curMask(:))))];
    if withphase
        meanPhaseAll = [meanPhaseAll mean(angle(curData(curMask(:))))];
        varPhaseAll  = [varPhaseAll var(angle(curData(curMask(:))))];
    end
    for subband = 1:6
        curData = Xh{level}(:,:,subband);
        curMask = maskresized>0.5;
        meanAbs = [meanAbs mean(abs(curData(curMask(:))))];
        varAbs  = [varAbs var(abs(curData(curMask(:))))];
        if withphase
            meanPhase = [meanPhase mean(angle(curData(curMask(:))))];
            varPhase  = [varPhase var(angle(curData(curMask(:))))];
        end
    end
end
cwtParameters = [meanAbsAll varAbsAll meanPhaseAll varPhaseAll meanAbs varAbs meanPhase varPhase];