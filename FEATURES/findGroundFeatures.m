function [pointm1, pointm2, H] = findGroundFeatures(im1, im2, rangey, rangex, thresh, plotresults)

if (isempty(thresh))
    thresh = -1;
end
pointm1 = [];
pointm2 = [];
for k = 1:2
    % features on first frame and second frame
    if (thresh<0) 
        % using DT-CWT
        [~, r1{k}, c1{k}] = findKeypoints(im1(rangey{1},rangex{k})*255, 5);
        [~, r2{k}, c2{k}] = findKeypoints(im2(rangey{2},rangex{k})*255, 5);
    else
        [~, r1{k}, c1{k}] = harris(im1(rangey{1},rangex{k})*255, 1, thresh, 3);
        [~, r2{k}, c2{k}] = harris(im2(rangey{2},rangex{k})*255, 1, thresh, 3);
    end
    % adjust position
    r1{k} = r1{k} + rangey{1}(1);  
    c1{k} = c1{k} + rangex{k}(1) - 1;    
    r2{k} = r2{k} + rangey{2}(1);
    c2{k} = c2{k} + rangex{k}(1) - 1;
    
    % find matching by correlation
    window = 15;    % Window size for correlation matching
    [m1,m2] = matchbycorrelation(im1, [r1{k}';c1{k}'], im2, [r2{k}';c2{k}'], window, -k);
    pointm1 = [pointm1 m1];
    pointm2 = [pointm2 m2];
end

% Assemble homogeneous feature coordinates for fitting of the
% fundamental matrix, note that [x,y] corresponds to [col, row]
x1 = [pointm1(2,:); pointm1(1,:); ones(1,length(pointm1))];
x2 = [pointm2(2,:); pointm2(1,:); ones(1,length(pointm2))];

t = .001;  % Distance threshold for deciding outliers
[H, inliers] = ransacfithomography(x1, x2, t);

% reduce matching point to reliable ones
pointm1 = pointm1(:,inliers);
pointm2 = pointm2(:,inliers);

% plot matched points
if plotresults
    figure(111); imshow(0.5*(im1+im2)); hold on
    plot(pointm1(2,:),pointm1(1,:),'r+');
    plot(pointm2(2,:),pointm2(1,:),'g+');
    for n = 1:size(pointm1,2)
        line([pointm1(2,n) pointm2(2,n)], [pointm1(1,n) pointm2(1,n)],'color',[0 0 1])
    end
end