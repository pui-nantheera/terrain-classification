function [namelist, filenames] = getAllfileNames(folder)

% list with directories
namelist = {};
% list only file names
filenames = {};

files = dir(folder);
files = files(3:end); % get rid of root dir
isDir = [files.isdir];
dirNames = {files(isDir).name};
fileNames = {files(~isDir).name}; 

% create name list from files in the main folder
countf = length(namelist);
for f = 1:length(fileNames)
    namelist{countf+f} = [folder,fileNames{f}];
    filenames{countf+f} = fileNames{f};
end

% look through each sub folder
while length(dirNames)>0
    predirName = dirNames; 
    dirNames = {};
    count = 1;
    for f = 1:length(predirName)
        curDir = [folder,predirName{f},'\'];
        files = dir(curDir);
        files = files(3:end);
        isDir = [files.isdir];
        
        % add file names to the list
        fileNames = {files(~isDir).name};
        countf = length(namelist);
        for ff = 1:length(fileNames)
            namelist{countf+ff} = [curDir,fileNames{ff}];
            filenames{countf+ff} = fileNames{ff};
        end
        
        % if more subdirectories inside subdir
        subdirNames = {files(isDir).name};
        for sf = 1:length(subdirNames)
            dirNames{count} = [predirName{f},'\',subdirNames{sf}];
            count = count+1;
        end
    end
end