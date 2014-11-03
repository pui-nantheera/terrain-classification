% study discontinuity
clear all
addpath('../SUPPORTFILES/');
addpath(genpath('../FEATURES/'));
addpath('../DTCWT/');

% directories store images for each class
dirName{1} = 'C:\Locomotion\results\code_motion\forTraining\pathcontinuity\continue\';
dirName{2} = 'C:\Locomotion\results\code_motion\forTraining\pathcontinuity\discontinue\';

% record results
fileID = fopen('C:\Locomotion\results\code_motion\forTraining\features\path_consistency.txt','a');

% texture parameters
wlevels = 4;

% common tools
havg = fspecial('average',[10 10]);

for cnum = 1:2
    
    % read image name
    [files, filenames]  = getAllfileNames(dirName{cnum});
    
    % extract features for each image
    for fnum = 1:length(files)
        fprintf(' %d',fnum);
        
        % read frame
        curframe = imread(files{fnum});
        % convert to grayscale
        yuv = rgb2ycbcr(curframe);
        % put new frame to buffer
        curImg = im2double(yuv(:,:,1));
        [height width] = size(curImg);
        % wavelet transform
        [lowcoef,highcoef] = dtwavexfm2(curImg,wlevels,'antonini','qshift_06');
        % consider middle of the frame
        features = [];
        for level = 1:min(3,wlevels)
            % creat gradient line at the middle of the image - assuming we're
            % walking forward
            curMap = abs(highcoef{level});
            gradientMap = mean(curMap(:,:,2:5),3);
            midline = round(width/2^(level+1));
            sizeband = min(floor(size(gradientMap,2)/2),20*(wlevels-level+1));
            gradientMap = gradientMap(:,midline+(-sizeband+1:sizeband));
            gradientMap = gradientMap./max(gradientMap(:));
            gradientMap = imfilter(gradientMap,fspecial('average',floor([sizeband/2 sizeband/2])));
            midline = round(size(gradientMap,2)/2);
            sizeband = min(floor(size(gradientMap,2)/2)-ceil(sizeband/4),15*(wlevels-level+1));
            gradientMap = gradientMap(sizeband:end-sizeband,midline+(-sizeband+1:sizeband));
            gradientLine = mean(gradientMap,2);
            % detect change
            p = polyfit(1:length(gradientLine), gradientLine', 2);
            smthGradient2 = polyval(p,1:length(gradientLine));
            error2 = abs(gradientLine'-smthGradient2);
            p = polyfit(1:length(gradientLine), gradientLine', 3);
            smthGradient3 = polyval(p,1:length(gradientLine));
            error3 = abs(gradientLine'-smthGradient3);
            p = polyfit(1:length(gradientLine), gradientLine', 4);
            smthGradient4 = polyval(p,1:length(gradientLine));
            error4 = abs(gradientLine'-smthGradient4);
            % histogram
            [normh2, bin2] = normHistogram(error2, 0:0.005:0.06);%max([error2 error3]));
            [normh3, bin3] = normHistogram(error3, 0:0.005:0.06);%max([error2 error3]));
            [normh4, bin4] = normHistogram(error4, 0:0.005:0.06);%max([error2 error3]));
            features = [features normh2 normh3 normh4];
        end
        % save
        fprintf(fileID,'%4d ',cnum);
        fprintf(fileID,'%.8f\t',features);
        fprintf(fileID,'\n');
    end
    fprintf('\n');
end
fclose('all');