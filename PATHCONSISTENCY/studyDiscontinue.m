% study discontinuity
clear all
addpath('../DTCWT/');
addpath('../SUPPORTFILES/');

% control parameters
wlevels = 4;    % levels of wavlet decomposition

% common tools
havg = fspecial('average',[10 10]);

% read frame from video
videoFile = 'C:\Locomotion\videos\walking 60 degree\MVI_0146_deshake.avi';

videoObj = VideoReader(videoFile);
% video parameters
totalFrames = videoObj.NumberOfFrames;
height = videoObj.Height;
width  = videoObj.Width;
GOP    = round(videoObj.Framerate);

startFrame = 1196;
for fnum = [60 549 585 937 1196 1295 1899 3644]%startFrame:GOP:totalFrames
    % read frame
    curframe = read(videoObj,fnum);
    % convert to grayscale
    yuv = rgb2ycbcr(curframe);
    % put new frame to buffer
    curImg = im2double(yuv(:,:,1));
    % mask caused from stabilisation
    mask = sum(curframe,3)>0;
    
    % wavelet transform
    [lowcoef,highcoef] = dtwavexfm2(curImg,wlevels,'antonini','qshift_06');
    % consider middle of the frame
    cr{2} = ':';
    cr{3} = '-';
    figure(fnum); imshow(curframe(75:end-75,:,:));
    for level = 2:min(3,wlevels)
        % creat gradient line at the middle of the image - assuming we're
        % walking forward
        curMap = abs(highcoef{level});
        gradientMap = mean(curMap(:,:,2:5),3);
        midline = round(width/2^(level+1));
        sizeband = 20*(wlevels-level+1);
        gradientMap = gradientMap(:,midline+(-sizeband:sizeband));
        gradientMap = gradientMap./max(gradientMap(:));
        gradientMap = imfilter(gradientMap,fspecial('average',[sizeband/2 sizeband/2]));
        midline = round(size(gradientMap,2)/2);
        sizeband = 15*(wlevels-level+1);
        gradientMap = gradientMap(sizeband:end-sizeband,midline+(-sizeband:sizeband));
        gradientLine = mean(gradientMap,2);
        % detect change
        p = polyfit(1:length(gradientLine), gradientLine', 2);
        smthGradient2 = polyval(p,1:length(gradientLine));
        error2 = abs(gradientLine'-smthGradient2);
        p = polyfit(1:length(gradientLine), gradientLine', 3);
        smthGradient3 = polyval(p,1:length(gradientLine));
        error3 = abs(gradientLine'-smthGradient3);
        % histogram
        [normh2, bin2] = normHistogram(error2, 0:0.005:0.06);%max([error2 error3]));
        [normh3, bin3] = normHistogram(error3, 0:0.005:0.06);%max([error2 error3]));
        % plot
        clear temp
        temp(:,1) = gradientLine';
        temp(:,2) = smthGradient2;
        temp(:,3) = smthGradient3;
%         figure(fnum+1); plot(temp, cr{level}); legend(['level ',num2str(level)], ['level ',num2str(level), ' p2'],['level ',num2str(level), ' p3'], 'Location', 'Best'); title(['frame ',num2str(fnum)]); hold on
%         figure(fnum+1); plot([error2; error3]', cr{level}); legend(['level ',num2str(level), ' p2'],['level ',num2str(level), ' p3'], 'Location', 'Best'); title(['frame ',num2str(fnum)]); hold on
        figure(fnum+2); plot([bin2; bin3]',[normh2; normh3]', cr{level}); legend(['level ',num2str(level), ' p2'],['level ',num2str(level), ' p3'], 'Location', 'Best'); title(['frame ',num2str(fnum)]); hold on
    end
end