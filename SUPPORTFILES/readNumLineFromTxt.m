function numLine = readNumLineFromTxt(fname)

fileID = fopen(fname,'r');
numLine = fscanf(fileID,'%4d'); fclose(fileID);
if isempty(numLine)
    numLine = 0;
else
    featureMatrix = dlmread(fname);
    numLine = size(featureMatrix,1);
end