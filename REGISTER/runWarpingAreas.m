function curSegMap = runWarpingAreas(curframe, prevframe, prevSegMap, reduceRatio, limitSmallSize, framerate)

% dimension
[height, width] = size(prevSegMap);

listPrevSeg = unique(prevSegMap(:));
listPrevSeg(listPrevSeg==0) = [];
% tracking each region the result is put on curSegMap
curSegMap = zeros(height,width);
transition = zeros(2, max(listPrevSeg));
toRemove = zeros(1,length(listPrevSeg));
smallcursubreg = zeros(round(height*reduceRatio), round(width*reduceRatio));
smallcurframe = zeros(round(height*reduceRatio), round(width*reduceRatio));
smallprevframe = zeros(round(height*reduceRatio), round(width*reduceRatio));
smallcurframe = imresize(curframe,reduceRatio);
smallprevframe = imresize(prevframe,reduceRatio);
for count = 1:length(listPrevSeg);
    reg = listPrevSeg(count);
    cursubreg = double(prevSegMap==reg);
    if sum(cursubreg(:))>limitSmallSize %length(farRangei)*length(farRangej)/6/20
        % register previous frame to current frame
        smallcursubreg = imresize(cursubreg,reduceRatio);
        [A,T] = opticalflow(smallcurframe,smallprevframe,smallcursubreg, 3);
        if ~(any(isnan(A(:))) || any(isnan(A(:))))
            temp = warp(smallcursubreg, A, T );
            temp = imresize(temp,1/reduceRatio);
            if (reg > min(listPrevSeg(end),listPrevSeg(min(length(listPrevSeg),3))))
                avgTransition = median(transition(:,sum(transition(:,1:reg-1))~=0),2);
                if (sum(abs(avgTransition-T)) < sum(abs(avgTransition))*10)||(sum(abs(avgTransition-T))<0.01)
                    curSegMap = (temp>=0.5).*reg.*(curSegMap==0) + (temp>=0.5).*0.*(curSegMap>0).*(abs(T(2))<height/framerate)...
                        + (temp>=0.5).*curSegMap.*(abs(T(2))>=height/framerate) + (temp<0.5).*curSegMap;
                end
            else
                curSegMap = (temp>=0.5).*reg.*(curSegMap==0) + (temp>=0.5).*0.*(curSegMap>0).*(abs(T(2))<height/framerate)...
                    + (temp>=0.5).*curSegMap.*(abs(T(2))>=height/framerate) + (temp<0.5).*curSegMap;
            end
            transition(:,reg) = T;
        else
            toRemove(listPrevSeg==reg) = 1;
        end
    end
end
% remove non exist area in previous frame
listPrevSeg(toRemove>0) = [];
% remove areas occurred from wrong warp (possibly)
avgTransition = median(transition(:,listPrevSeg),2);
distant   = sum(abs(transition-repmat(avgTransition,[1 size(transition,2)])));
wrongwarp = distant>max(height/framerate,std(distant));
wrongwarp = find(wrongwarp>0);
for count = 1:length(wrongwarp)
    reg = wrongwarp(count);
    curSegMap(curSegMap==reg) = 0;
end