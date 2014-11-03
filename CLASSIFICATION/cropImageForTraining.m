function cropImageForTraining(curImage, outfolder, startName, distance, useSegmentation)

if nargin < 3
    startName = '0';
end
if nargin < 4
    distance = 'all';
end
if nargin < 5
    useSegmentation = 0;
end
if useSegmentation==1
    addpath('./SEG/');
    addpath('../SEG/');
    % Perform segmentation
    % ---------------------------------------------------------------------
    % reduce size 
    display('.....Processing segmentation'); tic
    % convert to grayscale
    yuv = rgb2ycbcr(curImage);
    curframe = yuv(:,:,1);
    smallCurframe = double(imresize(curframe,0.25));
    hmindepthfactor = 0.15;
    t1= 0.9; t2= 0.8; t3 = 1000;
    [overlay,intolay,segMap,intmap, gsurf]=cmssegmm(smallCurframe, smallCurframe, [], 4,t1,t2, t3,hmindepthfactor,1,1);
    totalRegNearion = max(segMap(:));
    segMap = round(imresize(segMap/totalRegNearion,4)*totalRegNearion);
    processTime = toc;
    display(['.....Done segmentation at ',num2str(processTime),' sec']);
end

% dimension
[height, width, depth] = size(curImage);

% range for cropping
nearRangei = round(2/3*height):height;
nearRangej = round(1/4*width):round(3/4*width);
farRangei{1} = 1:round(1/6*height);
farRangei{2} = round(1/6*height):round(2/6*height);
farRangej{1} = round(1/5*width):round(2/5*width);
farRangej{2} = round(2/5*width):round(3/5*width);
farRangej{3} = round(3/5*width):round(4/5*width);

% near area
% -------------------------------------------------
if strcmpi(distance,'all') || strcmpi(distance,'near')
    nearArea = curImage(nearRangei,nearRangej,:);
    % segmentation
    if useSegmentation==1
        selmask = strel('disk', 2^(4-1)+2);
        nearSegMap = segMap(nearRangei,nearRangej);
        listRegNear = unique(nearSegMap(:));
        totalRegNear = length(listRegNear);
        for reg = 1:totalRegNear
            mask = nearSegMap==listRegNear(reg);
            if sum(mask(:))>0.2*numel(mask)
                mask = uint8(imerode(mask, selmask));
                % get unique name
                namet = getNameFromClock;
                uniqueName = [outfolder,'near',startName,namet,'.png'];
                imwrite(nearArea.*repmat(mask,[1 1 3]),uniqueName,'png');
            end
        end
    else
        % get unique name
        namet = getNameFromClock;
        uniqueName = [outfolder,'near',startName,namet,'.png'];
        imwrite(nearArea,uniqueName,'png');
    end
end

% far area
% -------------------------------------------------
if strcmpi(distance,'all') || strcmpi(distance,'far')
    for ki = 1:length(farRangei)
        for kj = 1:length(farRangej)
            farArea = curImage(farRangei{ki},farRangej{kj},:);
            % get unique name
            namet = getNameFromClock;
            uniqueName = [outfolder,'far',startName,namet,'.png'];
            imwrite(farArea,uniqueName,'png');
        end
    end
end