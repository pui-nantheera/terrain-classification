function [classPath, probPath] = updatePathConsistencyGroup(curframe,featurePathType,modelPath,...
            scaling1Path,scaling2Path,coefPCAPath,shiftdataPCAPath,maxNumFeaturesPath)

% dimenstion
[height, width] = size(curframe);
classPath = zeros(height,width);
probPath = zeros(height,width,2);
% three columns are considers
for k = 0:4
    midpoint = round(((k/5)+1/10)*width);
    pathImg = curframe(1:end/2,midpoint + (-150:150),:);
    [classPathcur probPathcur] = findPathConsistencyClass(pathImg,featurePathType,modelPath, scaling1Path, scaling2Path,...
        coefPCAPath, shiftdataPCAPath, maxNumFeaturesPath);
    classPath(:,midpoint+(-round(1/10*width)+1:round(1/10*width))) = classPathcur;
    probPath(:,midpoint+(-round(1/10*width)+1:round(1/10*width)),1) = probPathcur(1);
    probPath(:,midpoint+(-round(1/10*width)+1:round(1/10*width)),2) = probPathcur(2);
end

