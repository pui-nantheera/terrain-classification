function [modelTexture, scaling1, scaling2] = findModelTexture(...
                                    genModelTextureClassify,classifyWithRawData,classifyByRange,...
                                    wlevels,kernelType, boundarywidth)
                                
% get right name
if classifyWithRawData
    extName = '_rawData';
else
    extName = ''; % using average of each terrain type
end
if classifyByRange
    extName2 = '_range';
else
    extName2 = '';
end
if genModelTextureClassify
    % train data list
    maindir = 'C:\Locomotion\videos\stillvideos\plotresults\';
    groundname{1} = 'brick11am_5D1080p30fps_140cm60d';
    groundname{2} = 'grass1pm_5D1080p30fps_140cm60d';
    groundname{3} = 'tarmac11am_5D1080p30fps_140cm60d';
    groundname{4} = 'sand1pm_Nikon1080p23fps_140cm60d';
    if ~classifyByRange
        % regardless to distance from camera
        % -----------------------------------------------------------------
        trainingData = [];
        labels = [];
        for gname = 1:length(groundname)
            if ~classifyWithRawData
                eval(['load ',maindir,'Orig_',groundname{gname},'_r1_w512_l',num2str(wlevels),'_8bits.mat avgFeatures']);
                trainingData = [trainingData; avgFeatures];
                labels = [labels; gname.*ones(size(avgFeatures,1),1)];
            else
                eval(['load ',maindir,'Orig_',groundname{gname},'_r1_w512_l',num2str(wlevels),'_8bits.mat featuresAll nonexist']);
                rawFeature = [];
                for k = 1:size(featuresAll,3)
                    curData = featuresAll(:,:,k);
                    curNonexist = ~nonexist(:,1,k);
                    rawFeature = [rawFeature; featuresAll(curNonexist,:,k)];
                end
                trainingData = [trainingData; rawFeature];
                labels = [labels; gname.*ones(size(rawFeature,1),1)];
            end
        end
        % model from training dataset
        [modelTexture, scaling1, scaling2] = getModelfromTraining(trainingData, labels, kernelType);

    else
        % images are divided into 3 ranges: near, middle and far
        % -----------------------------------------------------------------
        gapdis = 2.5; %metre
        actualdistance = 0:gapdis:(10+gapdis);
        
        % model from training dataset for each range
        for k = 1:length(boundarywidth)
            trainingData = [];
            labels = [];
            currange = max(1,(k*2)-2):min(length(actualdistance),(k*2)+1);
            for gname = 1:length(groundname)
                
                eval(['load ',maindir,'Orig_',groundname{gname},'_r1_w512_l',num2str(wlevels),'_8bits.mat avgFeatures']);
                xdata = (22+(0:11:22/2*size(avgFeatures,1)-1))/100;
                for range = currange
                    drange = (xdata>(actualdistance(range)-gapdis+gapdis/4)).*(xdata<(actualdistance(range)+gapdis-gapdis/4));
                    trainingData = [trainingData; avgFeatures(drange'>0,:)];
                    labels = [labels; ones(sum(drange),1)*gname];
                end
            end
            [modelTexture{k}, scaling1{k}, scaling2{k}] = getModelfromTraining(trainingData, labels, kernelType);
        end
        
    end
    % save model
    save(['./CLASSIFICATION/model_',kernelType,extName,extName2],'modelTexture','scaling1','scaling2');
else
    load(['./CLASSIFICATION/model_',kernelType,extName,extName2]);
end