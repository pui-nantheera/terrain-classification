function [framenumFar,areanumFar,labelFar,featureFar] = getFeature4update(featureFar,listWrongClassifyFar, updatetype, areaoption)

% <note for git> this file works with main_code version 2013-06-16 15:04:26
% 'record features for each area'

if nargin<2
    updatetype = 'all';
end

% from groundtruth assuming we get this info from other sensors
listFar = listWrongClassifyFar(:, 1:3);
if strcmpi(areaoption,'near')
    listFar = listWrongClassifyFar(:, [1 4 5]);
end

% get the wrong area index and replace the wrong label to the right one
% far area
indfar = []; 
for k = 1:size(listWrongClassifyFar,1)
    if (listFar(k,3)>0)
        for n = 1:size(featureFar,1)
            % same frame & same area & diff label
            if (featureFar(n,1)==listFar(k,1)) ...
                    &&(featureFar(n,2)==listFar(k,2))...
                    &&(featureFar(n,3)~=listFar(k,3))
                indfar = [indfar n];
                featureFar(n,3) = listFar(k,3); % replace with the right class
            end
        end
    end
end

% features that will be used for update model
if strcmpi(updatetype,'all')
    indfar = 1:size(featureFar,1);
end

% separate variables
framenumFar = featureFar(indfar,1);
areanumFar  = featureFar(indfar,2);
labelFar    = featureFar(indfar,3);
featureFar  = featureFar(indfar,4:end);