% This code is for study frequency change on the image due to orientation
% -----------------------------------------------------------------------
clear all
addpath('../DTCWT/');
addpath('../SHAPETEXTURE/');

% create rectified homogenous texture image
% -----------------------------------------
% period
Ts = 5; % cm
fs = 1/Ts; 
% sine signal image
height = 100; % cm
width  = 100; % cm
rangei = 1:height;
sinewave = 0.5*sin(2*pi*fs*rangei)+0.5;
rectifiedImg = repmat(sinewave',[1 width]);

% geometric parameters
% --------------------
% slant angle
alpha = 45; % degree
% camera pos - no effect on normalised plot
h_fromground = 160; %cm
% sensor ratio
sensorRatio = 4368/3.58; % pixel/cm
% focal length
focusLength = 2.8; % cm

figure; hold on;
for alpha = [15 30 45 60]
    % distance to plane
    Zs = h_fromground*tand(alpha); % cm
    
    % generate projected plane
    % ------------------------
    % find homography transforming rectified image to projected image
    [H, planeNormal, rectPoints, projPoints] = rectified2projected([height width]*sensorRatio, focusLength*sensorRatio, 1, [0 0 Zs]*sensorRatio, [-alpha 0 0], 0);
    udata = [min(rectPoints(:,1)) max(rectPoints(:,1))];
    vdata = [min(rectPoints(:,2)) max(rectPoints(:,2))];
    xdata = [min(projPoints(:,1)) max(projPoints(:,1))];
    ydata = [min(projPoints(:,2)) max(projPoints(:,2))];
    [projImg, xdata, ydata] = imtransform(rectifiedImg,H,'UData', udata,'VData',vdata, 'XData', xdata, 'Ydata', ydata,'XYScale',1);
    horSignal = projImg(:,round(xdata(end)));
    horSignal = horSignal(end:-1:1);
    projrangei = -round(ydata(2):-1:ydata(1));
%     figure; plot(projrangei,horSignal)
    
    % Extract local frequency
    % -----------------------
    [pks locs] = findpeaks(horSignal);
    locs(pks<0.9) = []; pks(pks<0.9) = [];
    [pks2 locs2] = findpeaks(-horSignal);
    locs2(pks2>0.1) = []; pks2(pks2>0.1) = [];
    localfreq = sort([1./(locs2(2:end)-locs2(1:end-1)); 1./(locs(2:end)-locs(1:end-1))]);
    posfreq = round(sort([0.5*(locs2(2:end)+locs2(1:end-1)); 0.5*(locs(2:end)+locs(1:end-1))]));
%     hold on; plot(projrangei(locs),pks,'*r');
%     plot(projrangei(locs2),-pks2,'*r');
    plot(projrangei(posfreq),(localfreq-min(localfreq))/range(localfreq), 'b');
    
    % Compute freq equation
    % ---------------------
    rangeu = projrangei(posfreq(1)):projrangei(posfreq(end)); % pixels
    F = focusLength.*sensorRatio;
    f_by_fs = (-(tand(alpha)^2 .*sind(alpha)^2 .*(rangeu.^2)) + (2*F*tand(alpha).*sind(alpha)^2 .*rangeu) + ...
        (4*F^2 *Zs^2 *fs^2) -(F^2 .*sind(alpha)^2))./((tand(alpha)^2 .*sind(alpha).*(rangeu.^2))-(2*F*sind(alpha).*rangeu)+(F^2 *cosd(alpha)))...
        ./(4*F*Zs*fs);
    thoeryf = (f_by_fs-min(f_by_fs))/range(f_by_fs);
    plot(rangeu, thoeryf,'r');
    
    % estimate using Greiner's method
    f_by_fs = (F.^2 + rangeu.^2)./((F - rangeu.*tand(alpha)).^2)./cosd(alpha);
    thoeryG = (f_by_fs-min(f_by_fs))/range(f_by_fs);
    plot(rangeu, thoeryG,'g:');
    
    % estimate using Hwang's method
    f_by_fs = 1./(F - rangeu.*tand(alpha)).^2;
    thoeryH = (f_by_fs-min(f_by_fs))/range(f_by_fs);
    plot(rangeu, thoeryH,'m:');
end