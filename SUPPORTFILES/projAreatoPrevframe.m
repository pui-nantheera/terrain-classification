function prevArea = projAreatoPrevframe(curArea, Hform, distance)

% curArea is 2D binary matrix masking the current area
% Hform is rectified homography
% distance is shifting distance (pixel in vertical direction) between two
%       frames

% dimension
[height, width] = size(curArea);

% initial output
prevArea = zeros(height, width);

% clean Area
curArea = bwareaopen(curArea,50);
curArea = bwmorph(curArea, 'remove');
[indi, indj] = find(curArea>0);

if ~isempty(indi)
    % project to rectified plane
    [recj, reci] = tformfwd(Hform, indj, indi);
    % shift position 1 sec
    reci = reci-distance;
    % project back to image plane
    [indj, indi] = tforminv(Hform, recj, reci);
    indj = round(indj); indi = round(indi);
    % plot on previous frame
    removeInd = (indj<1)|(indi<1)|(indj>width)|(indi>height);
    indj(removeInd) = [];
    indi(removeInd) = [];
    % draw boundary
    prevArea(indi+(indj-1)*height) = 1;
    % masking
    seD2 = strel('disk',2);
    [~,totalRegs] = bwlabel(curArea>0);
    [~,curRegs]   = bwlabel(prevArea>0);
    curRegs = curRegs+1;
    while curRegs>totalRegs
        prevArea = imdilate(prevArea,seD2);
        [~,curRegs]   = bwlabel(prevArea>0);
    end
    prevArea = bwmorph(prevArea,'thin',3);
    prevArea = imfill(prevArea,'holes');
end