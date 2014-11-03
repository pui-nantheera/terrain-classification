function selectedFeatures = genFeatureRange(numbins,wlevels,numErrType)

count = 0;
groupFeatures = zeros(numbins,wlevels,numErrType);
% 1-3:e1,l1-l4 4-7:e1,ls
% 8-10:e1,l1-l4 11-14:e1,ls
% 15-17:e1,l1-l4 18-21:e1,ls
for errt = 1:numErrType
    for level = 1:wlevels
        groupFeatures(:,level,errt) = (level-1)*numbins*numErrType+(errt-1)*numbins+(1:numbins)';
        count = count + 1; selectedFeatures{count} = groupFeatures(:,level,errt);
    end
    % group of each level with 1 error types
    count = count + 1; selectedFeatures{count} = [selectedFeatures{count-3} selectedFeatures{count-2}]; % level 1 & 2
    count = count + 1; selectedFeatures{count} = [selectedFeatures{count-3-1} selectedFeatures{count-1-1}]; % level 1 & 3
    count = count + 1; selectedFeatures{count} = [selectedFeatures{count-2-2} selectedFeatures{count-1-2}]; % level 2 & 3
    count = count + 1; selectedFeatures{count} = [selectedFeatures{count-3-3} selectedFeatures{count-2-3} selectedFeatures{count-1-3}]; % all levels
end

% group of each level with 2 error types
% 22-24:e1e2,l1-l4 25-28:e1e2,2ls
for level = 1:wlevels
    count = count + 1; selectedFeatures{count} = [groupFeatures(:,level,1) groupFeatures(:,level,2)];
end
count = count + 1; selectedFeatures{count} = [selectedFeatures{count-3} selectedFeatures{count-2}]; % level 1 & 2
count = count + 1; selectedFeatures{count} = [selectedFeatures{count-3-1} selectedFeatures{count-1-1}]; % level 1 & 3
count = count + 1; selectedFeatures{count} = [selectedFeatures{count-2-2} selectedFeatures{count-1-2}]; % level 2 & 3
count = count + 1; selectedFeatures{count} = [selectedFeatures{count-3-3} selectedFeatures{count-2-3} selectedFeatures{count-1-3}]; % all levels

% group of each level with 2 error types
% 29-31:e2e3,l1-l4 32-35:e2e3,2ls
for level = 1:wlevels
    count = count + 1; selectedFeatures{count} = [groupFeatures(:,level,2) groupFeatures(:,level,3)];
end
count = count + 1; selectedFeatures{count} = [selectedFeatures{count-3} selectedFeatures{count-2}]; % level 1 & 2
count = count + 1; selectedFeatures{count} = [selectedFeatures{count-3-1} selectedFeatures{count-1-1}]; % level 1 & 3
count = count + 1; selectedFeatures{count} = [selectedFeatures{count-2-2} selectedFeatures{count-1-2}]; % level 2 & 3
count = count + 1; selectedFeatures{count} = [selectedFeatures{count-3-3} selectedFeatures{count-2-3} selectedFeatures{count-1-3}]; % all levels

% group of each level all error types
% 36-38:e1e2e3,l1-l4 39-42:e1e2e3,2ls
for level = 1:wlevels
    count = count + 1; selectedFeatures{count} = [groupFeatures(:,level,1) groupFeatures(:,level,2) groupFeatures(:,level,3)];
end
count = count + 1; selectedFeatures{count} = [selectedFeatures{count-3} selectedFeatures{count-2}]; % level 1 & 2
count = count + 1; selectedFeatures{count} = [selectedFeatures{count-3-1} selectedFeatures{count-1-1}]; % level 1 & 3
count = count + 1; selectedFeatures{count} = [selectedFeatures{count-2-2} selectedFeatures{count-1-2}]; % level 2 & 3
count = count + 1; selectedFeatures{count} = [selectedFeatures{count-3-3} selectedFeatures{count-2-3} selectedFeatures{count-1-3}]; % all levels
