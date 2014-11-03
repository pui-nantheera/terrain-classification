% run feature plot update
clear all
numFeatureShow = 6;

load('C:\Locomotion\results\code_motion\feature refine\caseII3.mat','featureRecord');
testType = {'grass','bricks','sand','soil','tarmac'};
axisf(1,:) = [0 0.4 0 32];
axisf(2,:) = [0 1 0 9];
axisf(3,:) = [0 0.8 0 8];
axisf(4,:) = [0 0.6 0 17];
axisf(5,:) = [0 1 0 8];
axisf(6,:) = [0 1 0 8];
for k = 1:size(featureRecord,2)
    for testnum = 1:size(featureRecord,1)
        figure(testnum); 
        totalFeature = min(size(featureRecord{testnum,k},2)-1,numFeatureShow);
        featuresData = featureRecord{testnum,k}(:,2:totalFeature+1);
        % normalisation dataset
        data = featuresData;
        scaling1 = min(data,[],1);
        scaling2 = 1./(max(data,[],1)-min(data,[],1));
        featuresData = (data - repmat(scaling1,size(data,1),1)).*(repmat(scaling2,size(data,1),1));
        % label
        labels = featureRecord{testnum,k}(:,1);
        
        % plot histogram
        % -----------------------------------------------------------------
        varData(k,:,testnum) = var(featuresData);
        [fc1,nc1] = hist(featuresData(labels==-1,:),0:0.01:1);
        [fc2,nc2] = hist(featuresData(labels==1,:),0:0.01:1);
        for fnum = 1:totalFeature
            % normalise histogram
            fc1(:,fnum) = fc1(:,fnum)/trapz(nc1,fc1(:,fnum));
            fc2(:,fnum) = fc2(:,fnum)/trapz(nc2,fc2(:,fnum));
            if k==1
                f1c1(:,fnum) = fc1(:,fnum);
                f1c2(:,fnum) = fc2(:,fnum);
            end
            subplot(ceil(numFeatureShow/3), ceil(numFeatureShow/2), fnum); 
            plot([nc1 nc1],[fc1(:,fnum) f1c1(:,fnum)],':'); hold on
            plot([nc2 nc2],[fc2(:,fnum) f1c2(:,fnum)]); hold off
            title(['component ',num2str(fnum)]);
            axis(axisf(fnum,:));
            if fnum==1
                legend(['class 1, iter=',num2str(k)],'class 1, iter=0',['class 2, iter=',num2str(k)],'class 2, iter=0');
            end
        end
        suptitle([testType{testnum}, ' iter=', num2str(k)]);
    end
    pause(0.1);
end