function [displayFrame, probMapinSeg, resultMap] = drawClassifyResultCircle(videoname, curFrameNum, height, width, segMapGroup, probMap,...
                                classMap,farRangei,farRangej, ratio, maskFarAll, regUsed, numpix, listRegFar)

if nargin < 13
    regUsed = 0;
end
if nargin < 14
    % for display class results
    numpix = readNumberPix;
end

rgb = im2double(imread(videoname));
displayFrameOrig = rgb(1:height,:,:);

% far areas
% Extract seg area
farSegMap = segMapGroup(:,:,1);
if strcmpi(regUsed,'biggest')
    farSegMap = findBiggestArea(farSegMap);
end
if nargin < 14
    listRegFar = unique(farSegMap(maskFarAll(farRangei,farRangej)>0));
    rangeRegion = 1:length(listRegFar);
else
    rangeRegion = listRegFar;
    if size(rangeRegion,1)>1
        rangeRegion = rangeRegion';
    end
end
probMapinSeg = zeros(height,width, size(probMap,2));
resultMap = zeros(height, width);

% for display result
displayFrame = imresize(displayFrameOrig, ratio);

% show class
% -------------------------------------------------------------------------
% class 1 : green
numpixclass{1} = 1-numpix{2};
numpixclass{1}(:,:,[1 3]) = 0;
numpixclass{2} = 1-numpix{3};
numpixclass{2}(:,:,[2 3]) = 0;
numpixclass{3} = 1-numpix{4};
numpixclass{3}(:,:,[1 2]) = 0;

% for each region
for reg = rangeRegion
    if (reg <= length(classMap))&&(reg>0)
        curClass = classMap(reg);
        if curClass>0
            maskFar = farSegMap==reg;
            % record class result
            resultMap(maskFar) = curClass;
            % record probability
            probMapinSeg(farRangei,farRangej,:) = repmat(permute(probMap(reg,:),[1 3 2]),[length(farRangei) length(farRangej) 1]).*...
                repmat(maskFar,[1 1 3]) +  probMapinSeg(farRangei,farRangej,:).*repmat(~maskFar,[1 1 3]);
            
            %         maskFar = imerode(maskFar, selmask);
            maskFar = bwmorph(maskFar, 'erode');
            if sum(maskFar(:))>0
                % find centre of current region
                % -------------------------------------------------------------
                STATS = regionprops(maskFar, 'Centroid');
                if length(STATS)>1
                    STATS = regionprops(findBiggestArea(maskFar), 'Centroid');
                end
                
                % display number
                % -------------------------------------------------------------
                [hn, wn, dn] = size(numpix{curClass+1});
                % crop displayFrame to number size
                curnum = displayFrame(min(height*ratio,max(1,max(0,round(ratio*(farRangei(1)+STATS(1).Centroid(2)))-5)+(1:hn))),...
                    min(width*ratio,max(1,max(0,round(ratio*(farRangej(1)+STATS(1).Centroid(1)-15)))+(1:wn))),:);
                % replace that region with number
                displayFrame(min(height*ratio,max(1,max(0,round(ratio*(farRangei(1)+STATS(1).Centroid(2)))-5)+(1:hn))),...
                    min(width*ratio,max(1,max(0,round(ratio*(farRangej(1)+STATS(1).Centroid(1)-15)))+(1:wn))),:) = ...
                    curnum.*numpix{curClass+1}+numpixclass{curClass};
                
                % draw circle to show possibility
                % -------------------------------------------------------------
                curProb = probMap(reg,curClass);
                hn = 40*curProb^2+3; wn = hn;
                % crop displayFrame to number size
                curnum = displayFrame(min(height*ratio,max(1,max(0,round(ratio*(farRangei(1)+STATS(1).Centroid(2))))+(1:round(hn))-round(hn/2))),...
                    max(1,min(width*ratio,max(0,round(ratio*(farRangej(1)+STATS(1).Centroid(1))))+(1:round(wn))-round(wn/2))),:);
                [hc, ~, dc] = size(curnum);
                % circle
                t = 0:0.05*30/hn:2*pi;
                r = round(hn/2)-1;
                x = round(r*sin(t)+hn/2);
                y = round(r*cos(t)+hn/2);
                circlemask = zeros(round(hn),round(wn));
                circlemask((x-1)*round(hn)+y) = 1;
                circlemask = circlemask(end-hc+1:end,:);
                % replace that region with number
                curnum = curnum.*repmat(~circlemask,[1 1 3]);
                curnum(:,:,(curClass<3)*(3-curClass)+(curClass==3)*curClass) = ...
                    curnum(:,:,(curClass<3)*(3-curClass)+(curClass==3)*curClass)+circlemask;
                displayFrame(min(height*ratio,max(1,max(0,round(ratio*(farRangei(1)+STATS(1).Centroid(2))))+(1:round(hn))-round(hn/2))),...
                    max(1,min(width*ratio,max(0,round(ratio*(farRangej(1)+STATS(1).Centroid(1))))+(1:round(wn))-round(wn/2))),:) = curnum;
                
            end
        end
    end
end

% display 
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