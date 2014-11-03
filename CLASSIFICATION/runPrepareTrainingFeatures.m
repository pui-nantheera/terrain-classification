% This code is data preparation for training
clear all

addpath('../SUPPORTFILES/');
addpath(genpath('../FEATURES/'));
addpath('../DTCWT/');

% type of feature extraction
typefeature = 'riLPQ';%'BPUCWT15'; % option 15 from testDTCWT
        %'riLPQ';%'best'; % 'all';
usesegment = 'segment';
nearDownSampling = 4;

% ri_LPQ
numOrientations = 12;
LPQfilters = createLPQfilters(9,numOrientations,2);

% Raw data directory
% -------------------------------------------------------------------------
% This is temporary directory where you copy images and videos for
% training. File will be deleted at the end of the process.
folder = 'C:\Locomotion\results\code_motion\forTraining\';
for alltypes = {'bricks','bush','cement','grass','gravel','metal','nonground', 'sand','soil','tarmac','wood'};
    
    terraintype = alltypes{1};
    [files, filenames]  = getAllfileNames([folder,terraintype,'_featureExtracted\']);
    
    if ~isempty(files)
        
        % output directory
        outfolder = [folder,terraintype,'_featureExtracted\',usesegment,'\'];
        mkdir(outfolder);
        % record results
        fileIDnear = fopen(['C:\Locomotion\results\code_motion\forTraining\features\',typefeature,'256_',terraintype,'near.txt'],'a');
        fileIDfar = fopen(['C:\Locomotion\results\code_motion\forTraining\features\',typefeature,'256_',terraintype,'far.txt'],'a');
        fileIDnearName = fopen(['C:\Locomotion\results\code_motion\forTraining\features\',typefeature,'256_',terraintype,'nearName.txt'],'a');
        fileIDfarName = fopen(['C:\Locomotion\results\code_motion\forTraining\features\',typefeature,'256_',terraintype,'farName.txt'],'a');
        % read number of features in the text files
        numFar = readNumLineFromTxt(['C:\Locomotion\results\code_motion\forTraining\features\',typefeature,'256_',terraintype,'far.txt']);
        numNear = readNumLineFromTxt(['C:\Locomotion\results\code_motion\forTraining\features\',typefeature,'256_',terraintype,'near.txt']);
        
        % texture parameters
        wlevels = 4;
        
        % Get through each file
        % -------------------------------------------------------------------------
        for fnum = 1:length(files)
            
            fprintf('processing frame %4d of %4d\n',fnum,length(files));
            if strcmpi(typefeature,'riLPQ')||strcmpi(typefeature,'BPUCWT14')||strcmpi(typefeature,'BPUCWT15')
                curImage = (imread(files{fnum}));
            else
                curImage = im2double(imread(files{fnum}));
            end
            % resize the near area - speed up
            if strcmpi(filenames{fnum}(1:4),'near');
%                 curImage = imresize(curImage,1/nearDownSampling);
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
            % mask if need
            if ~isempty(usesegment)
                mask = sum(double(curImage),3)>0.01;
            end
            % convert to grayscale
            if size(curImage,3)>1
                yuv = rgb2ycbcr(curImage);
                curImage = double(yuv(:,:,1));
            end
            if all(size(curImage)./(2^wlevels) > 6)
                curImage = double(curImage);
                if strcmpi(typefeature,'riLPQ')
                    features = ri_lpq(curImage,LPQfilters,[],[], mask);
                elseif strcmpi(typefeature,'BPUCWT14')
                    features = histCWT(curImage,wlevels,14,[],[], mask); % UDT-CWT each subband level2 - wlevels
                elseif strcmpi(typefeature,'BPUCWT15')
                    features = histCWT(curImage,wlevels,15,[],[], mask); % UDT-CWT each subband level2 - wlevels
                else
                    % wavelet transform
                    [lowcoef,highcoef] = dtwavexfm2(curImage,wlevels,'antonini','qshift_06');
                    % texture features
                    if strcmpi(typefeature,'best')
                        features = findTextureFeatures(curImage, lowcoef, highcoef, 8, [1 4 5], mask, 0);
                    else
                        features = findTextureFeatures(curImage, lowcoef, highcoef, 8, 1:5);
                    end
                end
                % save
                fprintf(curFileIDName,'%4d',curNum);
                fprintf(curFileIDName,'%35s',filenames{fnum}(1:end-4));
                fprintf(curFileIDName,'\n');
                fprintf(curFileID,'%4d ',curNum);
                fprintf(curFileID,'%.8f\t',features);
                fprintf(curFileID,'\n');
            end
%             % move done file to new folder
%             movefile(files{fnum},[outfolder,filenames{fnum}]);
        end
        
        fclose('all');
    end
end
%% READ matrix from txt

featureMatrix = dlmread(['C:\Locomotion\results\code_motion\forTraining\features\',typefeature,'_',terraintype,'near.txt']);
featureMatrix = featureMatrix(:,2:end);