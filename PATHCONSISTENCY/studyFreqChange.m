% Study effect of frequency on image from planar orientation and focal
% length.


% slant angle
alpha = 60; % degree
% camera pos - no effect on normalised plot
h_fromground = 160; %cm
% sensor ratio
sensorRatio = 4368/3.58; % pixel/cm

% on image plane
rangeu = -300:300; % pixels
% distance to plane
Zs = h_fromground*tand(alpha); % cm
Zs = Zs*sensorRatio; % pixels

% for various frequencies
count = 1;
clear f normf

T_cm = 1;
T_pixel = T_cm*sensorRatio;
fs = 1/T_pixel;
for focusLength = [1.2 1.6 2.8 3.5 5 8.5 10]; % cm
    F = focusLength.*sensorRatio;
%     f_by_fs = Zs./(focusLength.*sensorRatio - rangeu.*tand(alpha))./cosd(alpha);
%     f_by_fs = 1./(focusLength.*sensorRatio - rangeu.*tand(alpha))./cosd(alpha);
%     f_by_fs = ((focusLength.*sensorRatio).^2 + rangeu.^2)./((focusLength.*sensorRatio - rangeu.*tand(alpha)).^2)./cosd(alpha);
%     f_by_fs = (-(tand(alpha)^2 .*sind(alpha)^2 .*(rangeu.^2)) + (2*F*tand(alpha).*sind(alpha)^2 .*rangeu) + ...
%         (4*F^2 *Zs^2 *fs^2) -(F^2 .*sind(alpha)^2))./((tand(alpha)^2 .*sind(alpha).*(rangeu.^2))-(2*F*sind(alpha).*rangeu)+(F^2 *cosd(alpha)))...
%         ./(4*F*Zs*fs);
     f_by_fs = (-(tand(alpha)^2 .*sind(alpha)^2 .*(rangeu.^2)) + (2*F*tand(alpha).*sind(alpha)^2 .*rangeu))./ ...
         ((tand(alpha)^2 .*sind(alpha).*(rangeu.^2))-(2*F*sind(alpha).*rangeu)+(F^2 *cosd(alpha)))...
        ./(4*F*Zs*fs);
    f(count,:) = (f_by_fs-min(f_by_fs))/range(f_by_fs);
    legendName{count} = ['F=',num2str(focusLength*10),'mm'];
    count = count + 1;
    
end
figure; plot(rangeu, f');
xlabel('vertical position (pixel)');
ylabel('fx/fs');
legend(legendName,'Location','Best');
title(['Planar angle = ',num2str(alpha),'^o, fs = ',num2str(fs),' pixel^{-1}']);

%%

% slant angle
alpha = 60; % degree
% camera pos - no effect on normalised plot
h_fromground = 160; %cm
% sensor ratio
sensorRatio = 4368/3.58; % pixel/cm
focusLength = 2.8; %cm
F = focusLength.*sensorRatio;

% on image plane
rangeu = -300:300; % pixels
% distance to plane
Zs = h_fromground*tand(alpha); % cm
Zs = Zs*sensorRatio; % pixels

% for various frequencies
count = 1;
clear f normf
for alpha = [15 30 45 60 75 80]; % degree
%     f_by_fs = Zs./(focusLength.*sensorRatio - rangeu.*tand(alpha))./cosd(alpha);
%     f_by_fs = 1./(focusLength.*sensorRatio - rangeu.*tand(alpha))./cosd(alpha);
%     f_by_fs = ((focusLength.*sensorRatio).^2 + rangeu.^2)./((focusLength.*sensorRatio - rangeu.*tand(alpha)).^2)./cosd(alpha);
%     f_by_fs = (-(tand(alpha)^2 .*sind(alpha)^2 .*(rangeu.^2)) + (2*F*tand(alpha).*sind(alpha)^2 .*rangeu) + ...
%         (4*F^2 *Zs^2 *fs^2) -(F^2 .*sind(alpha)^2))./((tand(alpha)^2 .*sind(alpha).*(rangeu.^2))-(2*F*sind(alpha).*rangeu)+(F^2 *cosd(alpha)))...
%         ./(4*F*Zs*fs);
    f_by_fs = 1./(focusLength.*sensorRatio - rangeu.*tand(alpha)).^2;
    f(count,:) = (f_by_fs-min(f_by_fs))/range(f_by_fs);
    legendName{count} = ['planar angle=',num2str(alpha),'^o'];
    count = count + 1;
    
end
figure; plot(rangeu, f');
xlabel('vertical position (pixel)');
ylabel('fx/fs');
legend(legendName,'Location','Best');
title(['Focal length = ',num2str(focusLength*10),' mm, fs = ',num2str(fs),' pixel^{-1}']);

%%

% slant angle
alpha = 60; % degree
% camera pos - no effect on normalised plot
h_fromground = 160; %cm
% sensor ratio
sensorRatio = 4368/3.58; % pixel/cm

% on image plane
rangeu = -300:300; % pixels
% distance to plane
Zs = h_fromground*tand(alpha); % cm
Zs = Zs*sensorRatio; % pixels

% for various frequencies
count = 1;
clear f normf

T_cm = 1;
T_pixel = T_cm*sensorRatio;
fs = 1/T_pixel;
focusLength = 2.8; % cm
F = focusLength.*sensorRatio;
term1 = -(tand(alpha)^2 .*sind(alpha)^2 .*(rangeu.^2));
term2 = (2*F*tand(alpha).*sind(alpha)^2 .*rangeu);
term3 = (4*F^2 *Zs^2 *fs^2) -(F^2 .*sind(alpha)^2);
termd1 = (tand(alpha)^2 .*sind(alpha).*(rangeu.^2));
termd2 = -(2*F*sind(alpha).*rangeu);
termd3 = (F^2 *cosd(alpha));

f_by_fs = (-term1 + term2 + term3)./(termd1 - termd2 + termd3);

figure; plot(rangeu, [term1; term2; term1+term2]);
figure; plot(rangeu, [termd1; termd2; termd1+termd2; termd1+termd2+termd3; (term1+term2)./(termd1+termd2)]);
figure; plot(rangeu, [term1+term2; termd1+termd2; (term1+term2)./(termd1+termd2)]);
xlabel('vertical position (pixel)');
ylabel('fx/fs');
legend(legendName,'Location','Best');
title(['Planar angle = ',num2str(alpha),'^o']);