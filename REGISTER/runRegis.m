% This is a main function of terrain classification and tracking
% --------------------------------------------------------------
clear all

addpath('../HOMOGRAPHY/');

% input video
% -------------------------------------------------------------------------
videoFile = 'C:\Locomotion\videos\moving videos\tarmacnarrow2pm_CANON480p30fps.avi';
        
% output video
% -------------------------------------------------------------------------
regisVideoFile = 'C:\Locomotion\videos\moving videos\tarmacnarrow2pm_CANON480p30fps_regis.avi';
conbVideoFile = 'C:\Locomotion\videos\moving videos\tarmacnarrow2pm_CANON480p30fps_comb.avi';

%% read video
videoObj = VideoReader(videoFile);
% for output videos
writerObjRegis = VideoWriter(regisVideoFile, 'MPEG-4');
writerObjRegis.Quality = 100;
writerObjRegis.FrameRate = 15;
writerObjComb  = VideoWriter(conbVideoFile, 'MPEG-4');
writerObjComb.Quality = 100;
writerObjComb.FrameRate = 15;
open(writerObjRegis);
open(writerObjComb);

% video parameters
totalFrames = videoObj.NumberOfFrames;
height = videoObj.Height;
width  = videoObj.Width;

startFrame = 850;
lastFrame = 850+100; % 10 sec

bufferHaftSize = 5;

rangeROIx = 50:width-50;
rangeROIy = 1:height/3;
roiMap = zeros(height,width);
roiMap(rangeROIy,rangeROIx) = 1;

% run sequence
refInd = 0;
Acum = [1 0 ; 0 1];
Tcum = [0 ; 0];
Acum0 = [1 0 ; 0 1];
Tcum0 = [0 ; 0];
roi = roiMap;
for numframe = startFrame:min(lastFrame,totalFrames)
    
    numframe
    curFrame = read(videoObj, numframe);
    refFrame = read(videoObj, numframe-1);
    refFrame = rgb2ycbcr(refFrame);
    refFrame = refFrame(:,:,1);
    % convert to grayscale
    yuv = rgb2ycbcr(curFrame);
    curFrameGray = yuv(:,:,1);
    % register to prev frame
    [A,T, curRegis] = opticalflow(double(refFrame),double(curFrameGray), roiMap, 3 );
    A0 = A;
    T0 = T;
%     A{numframe}(1,1) = 1; A{numframe}(2,2) = 1;
    
    % construct output video
    A(1,1) = 1; A(2,2) = 1;
    A(1,2) = A(1,2)/2;
    A(2,1) = A(2,1)/2;
    T(2) = T(2)/2;
    T(2) = T(2) - 1.*(T(2)>0);
    [Acum,Tcum] = accumulatewarp( Acum, Tcum, A,T );
    
    temp(numframe-startFrame+1) = Tcum(2);
    prevFrameGray(:,:,numframe-startFrame+1) = warp(double(yuv(:,:,1)), Acum, Tcum );
    yuv(:,:,2) = warp(double(yuv(:,:,2)), Acum, Tcum );
    yuv(:,:,3) = warp(double(yuv(:,:,3)), Acum, Tcum );
    % combine with colour channals
    yuv(:,:,1) = prevFrameGray(:,:,numframe-startFrame+1);
    curFrameRegis = ycbcr2rgb(uint8(yuv));
    
    %% construct output video
    
    
    yuv = rgb2ycbcr(curFrame);
    preTcum = Tcum0(2);
    
    A0(1,1) = 1; A0(2,2) = 1;
    A0(1,2) = A0(1,2)/2;
    A0(2,1) = A0(2,1)/2;
    T0(2) = T0(2)/2;
    T0(2) = T0(2) - 1.*(T0(2)>0);
    [Acum0,Tcum0] = accumulatewarp( Acum0, Tcum0,A0,T0 );
    Acum0t = Acum0;
    % for rigid
    absA = 0.5*(abs(Acum0t(1,2))+abs(Acum0t(2,1)));
    Acum0t(1,2) = sign(Acum0t(1,2))*absA;
    Acum0t(2,1) = sign(Acum0t(2,1))*absA;
    
    yuv(:,:,1) = warp(double(yuv(:,:,1)), Acum0t, Tcum0 );
    yuv(:,:,2) = warp(double(yuv(:,:,2)), Acum0t, Tcum0 );
    yuv(:,:,3) = warp(double(yuv(:,:,3)), Acum0t, Tcum0 );
    % combine with colour channals
    curFrameRegis0 = ycbcr2rgb(uint8(yuv));
    %%
    
    % record video
    writeVideo(writerObjRegis,curFrameRegis);
    writeVideo(writerObjComb,cat(2,curFrame, curFrameRegis, curFrameRegis0));
end

close(writerObjRegis);
close(writerObjComb);
fclose('all');