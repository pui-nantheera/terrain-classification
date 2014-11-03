function tformAvg = estimateHfromKeypoints(im1, im2, keypoint1, keypoint2, distance1Sec, useTime, plotresults)

% im1 and im2 are grayscale images
% keypoint1 is the list of key points of the previous image (t-n) 
% keypoint2 is the list of key points of the current image (t)
%           both are in the column vectors [indi, indj]
% keypoint1 and keypoint2 can also be binary maps showing where key point are

if nargin < 6
    useTime = 0;
end
if nargin < 7
    plotresults = 0;
end

% dimension
[height width] = size(im1);

% invert keypoint maps to index
if all(size(im1)==size(keypoint1))
    [indi, indj] = find(keypoint1>0);
    keypoint1 = [indi indj];
end
if all(size(im2)==size(keypoint2))
    [indi, indj] = find(keypoint2>0);
    keypoint2 = [indi indj];
end

% range for first image and the second image
rangey1 = [0.65*height 0.8*height];
rangey2 = [0.7*height height];

window = 15;    % Window size for correlation matching
pointm1 = [];
pointm2 = [];
% loop left and right
for k = 1:2
    
    curind1 = (keypoint1(:,1) < rangey1(2)) & (keypoint1(:,1) > rangey1(1));
    curind2 = (keypoint2(:,1) < rangey2(2)) & (keypoint2(:,1) > rangey2(1));
    % left
    if k==1
        curind1 = curind1 & (keypoint1(:,2) < width/2);
        curind2 = curind2 & (keypoint2(:,2) < width/2);
    else
        curind1 = curind1 & (keypoint1(:,2) > width/2);
        curind2 = curind2 & (keypoint2(:,2) > width/2);
    end
    % features on first frame and second frame
    r1{k} = keypoint1(curind1,1);
    c1{k} = keypoint1(curind1,2);
    r2{k} = keypoint2(curind2,1);
    c2{k} = keypoint2(curind2,2);
        
    % find matching by correlation (last input: -1 for left, -2 for right
    [m1,m2] = matchbycorrelation(im1, [r1{k}';c1{k}'], im2, [r2{k}';c2{k}'], window, -k);
    pointm1 = [pointm1 m1];
    pointm2 = [pointm2 m2];
end

% Assemble homogeneous feature coordinates for fitting of the
% fundamental matrix, note that [x,y] corresponds to [col, row]
x1 = [pointm1(2,:); pointm1(1,:); ones(1,length(pointm1))];
x2 = [pointm2(2,:); pointm2(1,:); ones(1,length(pointm2))];

t = .001;  % Distance threshold for deciding outliers
% loop until enough inliers are found
newpoint2 = []; inliers = [];
count = 1;
while (sum(newpoint2<width/2)<5) || (sum(newpoint2>width/2)<5)
    [H, inlierst] = ransacfithomography(x1, x2, t);
    % reduce matching point to reliable ones
    newpoint2 = [newpoint2 pointm2(2,inlierst)];
    inliers = [inliers inlierst];
    count = count+1;
    if count > 10
        ['cannot find appropriate H!!!']
        break;
    end
end
% reduce matching point to reliable ones
pointm1 = pointm1(:,unique(inliers));
pointm2 = pointm2(:,unique(inliers));

%% H Estimation

[tform, transformTemp] = findTFORMeachpoint(pointm1,pointm2,width,distance1Sec);

% estimate final H
% -------------------------------------------------------------------------
% find bad pairs
if useTime
    
    % fix text point
    y_cur = 0.6*height;
    % estimate time duration 
    rangej = width/2 + (-1:1);
    rangei = [y_cur height];
    estTime = zeros(1, size(pointm1,2));
    for k = 1:size(pointm1,2)
        [~,y_proj] = tformfwd(tform{k},[rangej(1); rangej(end); rangej(end); rangej(1);],...
            [rangei(1); rangei(1); rangei(end); rangei(end)]);
        estDistance = mean(y_proj(3:4))-mean(y_proj(1:2));
        estTime(k) = estDistance/distance1Sec;
    end
    % estimate time from all tform
    meanTime = mean(estTime);
    stdTime = std(estTime);
    badIndx = ~((estTime > (meanTime-stdTime)) & (estTime < (meanTime+stdTime)) & (estTime > 0));
    badIndx = find(badIndx>0);
else
    % from H itself
    % rank min to max
    [val, ind] = sort(transformTemp,3);
    ignoreInd = val(:,:,1)==val(:,:,2);
    ind(:,:,1) = ind(:,:,1).*~ignoreInd;
    ignoreInd = val(:,:,end)==val(:,:,end-1);
    ind(:,:,end) = ind(:,:,end).*~ignoreInd;
    maybeBad = [ind(:,:,1) ind(:,:,end)];
    maybeBad(maybeBad==0) = [];
    % find bad indx
    badIndx = unique(maybeBad);
    nBad = histc(maybeBad, badIndx);
    badIndx = badIndx(nBad>3);
end
% get average transform matrix
transformTemp(:,:,badIndx) = 0;
avgT = sum(transformTemp,3)/(length(tform)-length(badIndx));
tformAvg = tform{1};
tformAvg.tdata.T = avgT;
tformAvg.tdata.Tinv = inv(tformAvg.tdata.T);

%% plot matched points
if plotresults
    figure(111); imshow(0.5*(im1/max(im1(:))+im2/max(im2(:)))); hold on
    plot(pointm1(2,:),pointm1(1,:),'r+');
    plot(pointm2(2,:),pointm2(1,:),'g+');
    for n = 1:size(pointm1,2)
        line([pointm1(2,n) pointm2(2,n)], [pointm1(1,n) pointm2(1,n)],'color',[0 0 1])
    end
    for n = badIndx
        line([pointm1(2,n) pointm2(2,n)], [pointm1(1,n) pointm2(1,n)],'color',[1 0 0])
    end
    if plotresults>1
        Bi = imtransform(im1,tformAvg,'bicubic','udata',[1 width],'vdata',[1 height],'fill',0,'XData', [1 width], 'Ydata',[1 height]);
        figure; imshow(Bi/max(Bi(:)))
    end
end