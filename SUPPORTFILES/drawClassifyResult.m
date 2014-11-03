function [displayFrame, probMapinSeg] = drawClassifyResult(videoObj, curFrameNum, height, width, segMapGroup, probMap,...
                                classMap,farRangei,farRangej, ratio, maskFarAll, selmask, regUsed, numpix)

if nargin < 14
    regUsed = 0;
end
if nargin < 15
    % for display class results
    numpix = readNumberPix;
end

totalnumclass = size(probMap,2);

rgb = im2double(read(videoObj,curFrameNum));
displayFrame = rgb(1:height,:,:);
maskFarUsed = zeros(height,width);
probFarUsed = zeros(height,width);
probMapinSeg = zeros(height,width, size(probMap,2));
% far areas
% Extract seg area
farSegMap = segMapGroup(:,:,1);
if strcmpi(regUsed,'biggest')
    farSegMap = findBiggestArea(farSegMap);
end
listRegFar = unique(farSegMap(maskFarAll(farRangei,farRangej)>0));
totalRegFar = length(listRegFar);
for reg = 1:totalRegFar
    if classMap(reg)>0
        maskFar = farSegMap==listRegFar(reg);
        curClass = classMap(reg);
        maskFarUsed(farRangei,farRangej) = curClass*maskFar + (~maskFar).*maskFarUsed(farRangei,farRangej);
        curProb = probMap(reg,curClass);
        probFarUsed(farRangei,farRangej) = curProb*maskFar + (~maskFar).*probFarUsed(farRangei,farRangej);
        % for display
        channel = (3-curClass).*(curClass<3) + 3*(curClass==3);
        displayFrame(farRangei,farRangej,channel) = min(0.9,max(0.6,curProb))*maskFar + ...
            (~maskFar).*displayFrame(farRangei,farRangej, channel);
        % record probability
        probMapinSeg(farRangei,farRangej,:) = repmat(permute(probMap(reg,:),[1 3 2]),[length(farRangei) length(farRangej) 1]).*...
            repmat(maskFar,[1 1 3]) +  probMapinSeg(farRangei,farRangej,:).*repmat(~maskFar,[1 1 3]);
    end
end
% estimate missing area
missingArea = bwmorph(maskFarAll-(maskFarUsed>0),'open');
[missingLabel, missingnum] = bwlabel(missingArea);
for k = 1:missingnum
    curmissing = missingLabel==k;
    growarea = (bwmorph(curmissing,'dilate',3)-curmissing)>0;
    possibleclass = maskFarUsed(growarea);
    possibleclass(possibleclass==0) = [];
    estclass = round(mode(possibleclass(:)));
    if ~isnan(estclass)
        channel = (3-estclass).*(estclass<3) + 3*(estclass==3);
        if length(unique(possibleclass))==1
            estprob = probFarUsed(growarea);
            probFarUsed(possibleclass==0) = [];
            estprob = mean(estprob(:));
        else
            conpixel = zeros(1,totalnumclass);
            estprob = zeros(1,totalnumclass);
            for kc = 1:totalnumclass
                conpixel(kc) = sum(possibleclass==kc);
                estprob(kc) = sum(probFarUsed(growarea).*(maskFarUsed(growarea)==kc))/sum((maskFarUsed(growarea)==kc));
            end
            estprob(isnan(estprob)) = 0;
            p1 = estprob(estclass);
            estprob(estclass) = 0;
            p2 = max(estprob);
            estprob = p2/(1+p2/p1); % assume 45 degree to the combine prob
        end
        displayFrame(:,:,channel) = min(0.9,max(0.5,estprob))*curmissing + (~curmissing).*displayFrame(:,:,channel);
        probMapinSeg(:,:,estclass) = min(0.9,max(0.5,estprob))*curmissing + (~curmissing).*probMapinSeg(:,:,estclass);
    end
end

% for display result
displayFrame = imresize(displayFrame, ratio);
% show probability
for reg = 1:totalRegFar
    if classMap(reg)>0
        maskFar = farSegMap==listRegFar(reg);
        maskFar = imerode(maskFar, selmask);
        if sum(maskFar(:))>0
            STATS = regionprops(maskFar, 'Centroid');
            if length(STATS)>1
                STATS = regionprops(findBiggestArea(maskFar), 'Centroid');
            end
            [hn, wn, dn] = size(numpix{classMap(reg)+1});
            curnum = displayFrame(max(0,round(ratio*(farRangei(1)+STATS(1).Centroid(2)))-5)+(1:hn),...
                max(0,round(ratio*(farRangej(1)+STATS(1).Centroid(1)-15)))+(1:wn),:);
            displayFrame(max(0,round(ratio*(farRangei(1)+STATS(1).Centroid(2)))-5)+(1:hn),...
                max(0,round(ratio*(farRangej(1)+STATS(1).Centroid(1)-15)))+(1:wn),:) = curnum.*numpix{classMap(reg)+1};
        end
    end
end
[hn, wn, dn] = size(numpix{12});
curnum = displayFrame(10+(1:hn),10+(1:wn),:);
displayFrame(10+(1:hn),10+(1:wn),:) = curnum + (1-numpix{12});
% frame number
curnumstr = num2str(curFrameNum);
xpos = 10+wn+5;
for k = 1:length(curnumstr)
    curnumpix = numpix{str2double(curnumstr(k))+1};
    [hn, wn, dn] = size(curnumpix);
    curnum = displayFrame(10+(1:hn),xpos+(1:wn),:);
    displayFrame(10+(1:hn),xpos+(1:wn),:) = curnum + (1-curnumpix);
    xpos = xpos + wn + 2;
end