% This code is for testing Peter Kovesi's matching feature functions

clear all

% input video
% -------------------------------------------------------------------------
videoFile = 'C:\Locomotion\videos\moving videos\bricks1pm_CANON480p30fps.avi';
videoObj = VideoReader(videoFile);
% read two frames - duration 1 second
frame1 = read(videoObj, 140);
frame2 = read(videoObj, 170);

% dimension
[height width d] = size(frame1);
udata = [1 width];  vdata = [1 height];  % input coordinate system

% find translation between 2 frames
if size(frame1,3)>1
    gframe1 = rgb2gray(frame1);
    gframe2 = rgb2gray(frame2);
end
[optimizer, metric] = imregconfig('monomodal');

[~, tformRegis] = imregisterMo(gframe2(1:end/2,:),gframe1(1:end/2,:),'rigid',optimizer,metric);
frame2Registered = imtransform(gframe2, tformRegis, 'XData', udata, 'YData', vdata, 'Size', [height width]);

%% find corner features

thresh = 30;
im1 = im2double(gframe1);
im2 = im2double(frame2Registered);

range{1} = 1:width/2;
range{2} = width/2+1:width;
startyf1 = 0.65*height;
startyf2 = 0.7*height;

for startFigNum = 11; % for comparision
    % figure(startFigNum+1); hold on
    % subplot(1,2,1); imshow(im1)
    % subplot(1,2,2); imshow(im2)
    %
    % figure(startFigNum+2); imshow(0.5*(im1+im2))
    figure(startFigNum+3); imshow(0.5*(im1+im2))
    
    pointm1 = [];
    pointm2 = [];
    for k = 1:2
        % features on first frame
        [~, r1{k}, c1{k}] = harris(im1(startyf1:0.8*height,range{k})*255, 1, thresh, 3);
        r1{k} = r1{k} + startyf1;  % adjust position
        c1{k} = c1{k} + range{k}(1) - 1;
        
        % features on second frame
        [~, r2{k}, c2{k}] = harris(im2(startyf2:height,range{k})*255, 1, thresh, 3);
        r2{k} = r2{k} + startyf2;
        c2{k} = c2{k} + range{k}(1) - 1;
        
        %     % Display putative matches
        %     figure(startFigNum+1);
        %     subplot(1,2,1); hold on; plot(c1{k},r1{k},'r+');
        %     subplot(1,2,2); hold on; plot(c2{k},r2{k},'b+');
        
        % find matching by correlation
        window = 15;    % Window size for correlation matching
        [m1,m2] = matchbycorrelation(im1, [r1{k}';c1{k}'], im2, [r2{k}';c2{k}'], window, -k);
        %     % Display putative matches
        %     figure(startFigNum+2); hold on
        %     for n = 1:length(m1);
        %         line([m1(2,n) m2(2,n)], [m1(1,n) m2(1,n)])
        %     end
        pointm1 = [pointm1 m1];
        pointm2 = [pointm2 m2];
    end
    
    % Assemble homogeneous feature coordinates for fitting of the
    % fundamental matrix, note that [x,y] corresponds to [col, row]
    x1 = [pointm1(2,:); pointm1(1,:); ones(1,length(pointm1))];
    x2 = [pointm2(2,:); pointm2(1,:); ones(1,length(pointm2))];
    
    t = .001;  % Distance threshold for deciding outliers
    %     [F, inliers] = ransacfitfundmatrix(x1, x2, t);
    [H, inliers] = ransacfithomography(x1, x2, t);
    
    % Display both images overlayed with inlying matched feature points
    figure(startFigNum+3); hold on
    plot(pointm1(2,inliers),pointm1(1,inliers),'r+');
    plot(pointm2(2,inliers),pointm2(1,inliers),'g+');
    
    for n = inliers
        line([pointm1(2,n) pointm2(2,n)], [pointm1(1,n) pointm2(1,n)],'color',[0 0 1])
    end
        
end
