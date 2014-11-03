% This code is data preparation for training
clear all

addpath('../SUPPORTFILES/');
addpath(genpath('../FEATURES/'));
addpath('../DTCWT/');

% Raw data directory
% -------------------------------------------------------------------------
% This is temporary directory where you copy images and videos for
% training. File will be deleted at the end of the process.
folder = 'C:\Locomotion\results\code_motion\forTraining\';
terraintype = 'grass';
[files, filenames]  = getAllfileNames([folder,terraintype,'\']);

% output directory
outfolder = [folder,terraintype,'_featureExtracted\'];
mkdir(outfolder);
% record results
fileIDnear = fopen(['C:\Locomotion\results\code_motion\forTraining\features\',terraintype,'near.txt'],'a');
fileIDfar = fopen(['C:\Locomotion\results\code_motion\forTraining\features\',terraintype,'far.txt'],'a');
fileIDnearName = fopen(['C:\Locomotion\results\code_motion\forTraining\features\',terraintype,'nearName.txt'],'a');
fileIDfarName = fopen(['C:\Locomotion\results\code_motion\forTraining\features\',terraintype,'farName.txt'],'a');
% read number of features in the text files
numFar = readNumLineFromTxt(['C:\Locomotion\results\code_motion\forTraining\features\',terraintype,'far.txt']);
numNear = readNumLineFromTxt(['C:\Locomotion\results\code_motion\forTraining\features\',terraintype,'near.txt']);

% texture parameters
wlevels = 4;

% Get through each file
% -------------------------------------------------------------------------
for fnum = 1:length(files)
    fprintf('processing frame %4d of %4d\n',fnum,length(files));
    curImage = im2double(imread(files{fnum}));
    % resize the near area - speed up
    if strcmpi(filenames{fnum}(1:4),'near');
        curImage = imresize(curImage,0.5);
        curFileID = fileIDnear;
        curFileIDName = fileIDnearName;
        numNear = numNear + 1;
        curNum  = numNear;
    else
        curFileID = fileIDfar;
        curFileIDName = fileIDfarName;
        numFar = numFar + 1;
        curNum  = numFar;
    end
    % convert to grayscale
    if size(curImage,3)>1
        yuv = rgb2ycbcr(curImage);
        curImage = yuv(:,:,1);
    end
    % wavelet transform
    [lowcoef,highcoef] = dtwavexfm2(curImage,wlevels,'antonini','qshift_06');
    % texture features
    features = findTextureFeatures(curImage, lowcoef, highcoef, 8, 1:5);
    
    % save
    fprintf(curFileIDName,'%4d',curNum);
    fprintf(curFileIDName,'%25s',filenames{fnum}(1:end-4));
    fprintf(curFileIDName,'\n');
    fprintf(curFileID,'%4d ',curNum);
    fprintf(curFileID,'%.8f\t',features);
    fprintf(curFileID,'\n');
    
    % move done file to new folder
    movefile(files{fnum},[outfolder,filenames{fnum}]);
end

fclose('all');

%% READ matrix from txt

featureMatrix = dlmread(['C:\Locomotion\results\code_motion\forTraining\features\',terraintype,'far.txt']);
featureMatrix = featureMatrix(:,2:end);