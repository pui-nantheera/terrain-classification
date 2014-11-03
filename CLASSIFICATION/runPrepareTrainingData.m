% This code is data preparation for training
clear all

addpath('./SUPPORTFILES/');
addpath('../SUPPORTFILES/');

% Raw data directory
% -------------------------------------------------------------------------
% This is temporary directory where you copy images and videos for
% training. File will be deleted at the end of the process.
folder = 'C:\Locomotion\results\code_motion\forTraining\rawFiles\';
[files, filenames]  = getAllfileNames(folder);

% output directory
outfolder = 'C:\Locomotion\results\code_motion\forTraining\';
startframe = 5;
skipframe = 10;
subskipframe = 3;
selSharpest = 0;
cropImgForTraining = 1;
sidecrop = 1;
useSegmentation = 1;

% Get through each file
% -------------------------------------------------------------------------
for fnum = 1:length(files)
    
    curName = files{fnum};
    curFilename = filenames{fnum}(1:end-4);
        
    % assume the other are videos - generate image frame
    % --------------------------------------------------
    if ~isimage(curName)
        videoObj = VideoReader(curName);
        nFrames = videoObj.NumberOfFrames;
        
        % Read one frame every skipframe.
        for k = startframe:skipframe:nFrames
            fprintf(' %d',k);
            
            % --------------------------------------------------
            % find the sharpest frames in the group
            if selSharpest
                sharpValue = zeros(1,skipframe);
                for n = k:subskipframe:min(nFrames,(k+skipframe-1))
                    % read image
                    img = read(videoObj, n);
                    % find sharpness from gradient
                    sharpValue(n-k+1) = findSharpValue(img);
                end
                [~,ind] = max(sharpValue);
                curImage = read(videoObj, k+ind-1);
            else
                curImage = read(videoObj, k);
            end
            % bug from Windows
            if videoObj.Height==1088
                curImage = curImage(1:1080,:,:);
            end
            % --------------------------------------------------
            
            if rem(k,skipframe*4)<=skipframe*4
                fprintf('\n');
            end
            
            if cropImgForTraining
                % crop image
                cropImageForTraining(curImage,outfolder,[curFilename,num2str(k+2)], 'near',useSegmentation);
            else
                if sidecrop
                    imwrite(curImage(:,round(w/2)+ (-150:150),:), [outfolder,curFilename,'_',num2str(n),'.png'],'png');
                else
                    imwrite(curImage, [outfolder,curFilename,'_',num2str(n),'.png'],'png');
                end
            end
        end
        fprintf('\n');
    else
        curImage = imread(curName);
        % crop image
        cropImageForTraining(curImage,outfolder);
    end
end