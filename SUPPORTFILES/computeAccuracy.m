clear all
namename = 'MVI_0146_b';%'GOPR0081_a';%
name1 = 'MATLABrefreshonly3semiupdate5nearlabel';
%name1 = 'MATLABrefreshonly3';
filenameOrig = ['C:\Locomotion\results\code_motion\',namename,'\',name1,'\results.txt'];
filename = [filenameOrig(1:end-4),'1.txt'];

fid=fopen(filenameOrig) ; % the original file
fidd=fopen(filename, 'w') ; % the new file
while ~feof(fid) ; % reads the original till last line
    tline=fgets(fid) ; %
    if isletter(tline(2))==1 ;
    else
        fwrite(fidd,tline) ;
    end
end
fclose all ;

results = dlmread(filename);%, '\t', 1, 0);
name2 = 'MATLABrefreshonly3semiupdate5oneclassifier';
filenameOrig = ['C:\Locomotion\results\code_motion\',namename,'\',name2,'\results.txt'];
filename = [filenameOrig(1:end-4),'1.txt'];

fid=fopen(filenameOrig) ; % the original file
fidd=fopen(filename, 'w') ; % the new file
while ~feof(fid) ; % reads the original till last line
    tline=fgets(fid) ; %
    if isletter(tline(2))==1 ;
    else
        fwrite(fidd,tline) ;
    end
end
fclose all ;

results1 = dlmread(filename);%, '\t', 1, 0);
% results1a = zeros(size(results1,1)*3,size(results1,2));
% for n = 1:3
%     results1a(n:3:end,:) = results1;
% end
% results1 = results1a;

if size(results1,2)>9
   % 10-15 'true_poi1','true_poi2','true_poi3','false_poi1','false_poi2','false_poi3',...
   % 16-21 'true_nei1','true_nei2','true_nei3','false_nei1','false_nei2','false_nei3',...
   % 22-27 'true_pos1','true_pos2','true_pos3','false_pos1','false_pos2','false_pos3',...
   % 28-33 'true_neg1','true_neg2','true_neg3','false_neg1','false_neg2','false_neg3'
   for class = 1:3
        true_positive1(:,class)   = results1(:,9+class);
        false_positive1(:,class)  = results1(:,12+class);
        true_negative1(:,class)   = results1(:,15+class);
        false_negative1(:,class)  = results1(:,18+class);
        true_positive(:,class)    = results1(:,21+class);
        false_positive(:,class)   = results1(:,24+class);
        true_negative(:,class)    = results1(:,27+class);
        false_negative(:,class)   = results1(:,30+class);
    end
end

%  frameNO.  SegmentTime  WarpingTime ClassifyTime    OtherTime       accInd    numPixInd   accPropose    numPixels
totalFrame = min(size(results,1),size(results1,1));
totalTime = sum(sum(results(1:totalFrame, 2:5)))/totalFrame;

time2007  = sum(sum(results(1:totalFrame, [4 5])))/totalFrame;
time2010  = sum(sum(results(1:totalFrame, [3 4 5])))/totalFrame;

more2007 = (totalTime-time2007)/totalTime*100;
more2010 = (totalTime-time2010)/totalTime*100;

timePerframe = (sum(results(1:totalFrame, 2:5),2) - sum(results(1:totalFrame, [4 5]),2))./sum(results(1:totalFrame, [4 5]),2);

accuracyFrm = mean(results(1:totalFrame,8));
acc2007Frm = mean(results(1:totalFrame,6));

accuracyAll = sum(results(1:totalFrame,8).*results(1:totalFrame,9))/sum(results(1:totalFrame,9))
acc2007All = sum(results(1:totalFrame,6).*results(1:totalFrame,7))/sum(results(1:totalFrame,7))
accuracy1All = sum(results1(1:totalFrame,8).*results1(1:totalFrame,9))/sum(results1(1:totalFrame,9))

proposedresult = results(1:totalFrame,8);
angeresult = results(1:totalFrame,6);
noupdateresult = results1(1:totalFrame,8);

% plot accuracy
figure; plot([angeresult noupdateresult proposedresult]*100); title('Accuracy per frame');
legend(['Angelova [2]: ', num2str(acc2007All)],[name2,': ', num2str(accuracy1All)],[name1,': ', num2str(accuracyAll)],'Location','Best');
xlabel('frame number');
ylabel('accuracy (%)');

%% ROC

clear fpr tpr
figure; hold on
for class = 1:3
    % false positive rate
    fpr(:,class) = false_positive(:,class)./(false_positive(:,class)+true_negative(:,class));
    % true positive rate
    tpr(:,class) = true_positive(:,class)./(true_positive(:,class)+false_negative(:,class));
    % cure fit
    fprtemp = fpr(:,class);
    tprtemp = tpr(:,class);
    idxnan = (isnan(fprtemp)+isnan(tprtemp))>0;
    fprtemp = fprtemp(~idxnan);
    tprtemp = tprtemp(~idxnan);
    [fprsort,Isort] = sort(fprtemp,'ascend');
    fprtemp = fprtemp(Isort);
    tprtemp = tprtemp(Isort);
    p = polyfit(fprtemp,tprtemp,2);
    xx = 0:0.01:1;
    yy = polyval(p,xx);
    plot(fprtemp, tprtemp, '.'); 
    plot(xx, yy);
end