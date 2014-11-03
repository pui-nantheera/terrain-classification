clear all
addpath('../SUPPORTFILES/');

% load recorded probability
load probPCA

% some paramenters
showCompareClass1vs2 = 0;
showCompareComp1vs2 = 0;
showCurveFit = 0;
showCompareHist = 0;
showCompareProb = 1;
allResults = [];
rankProb = 1;
rankErr = 1;
expand01 = 0;
expand01final = 1;
numComponentUsed = 6;

% get label and prob from the best feature group
% -------------------------------------------------------------------------
bestind = 26;
curProb = probRBF{bestind};
labels  = curProb(:,1);
prob1   = curProb(labels==1,2);
prob2   = curProb(labels==2,3);
features = curProb(labels==1,4:end);

% sort probability - no need actually
if rankProb
    [prob1, ind] = sort(prob1);
    features = features(ind,:);
end

% show component 1 of class 1 and 2
% -------------------------------------------------------------------------
if showCompareClass1vs2
    figure; subplot(1,2,1); plot(features(:,1), prob1, 'rx');
    xlabel('feature errRankues'); ylabel('probability');
    title('path consistency');
    subplot(1,2,2); plot(curProb(labels==2,4), prob2,'bx');
    xlabel('feature errRankues'); ylabel('probability');
    title('path inconsistency')
end
% show component 1 and 2 of class 1 (path consistency)
% -------------------------------------------------------------------------
if showCompareComp1vs2
    figure; subplot(1,2,1); plot(features(:,1), prob1,'rx');
    xlabel('component 1'); ylabel('probability');
    title('path consistency');
    subplot(1,2,2); plot(features(:,2), prob1,'bx');
    xlabel('component 2'); ylabel('probability');
    title('path consistency')
end

% consider each features - estimate probability from curvefit
% -------------------------------------------------------------------------
totalFeatures = size(features,2);
err = zeros(1,totalFeatures);
pAll = zeros(totalFeatures, 4);
for fnum = 1:totalFeatures
    p = polyfit(features(:,fnum), prob1, 3);
    smthp = polyval(p,features(:,fnum));
    % scaling expand to 0-1
    if expand01
        minv = min(smthp);
        maxv = max(smthp);
        smthp = (smthp-minv)./(maxv-minv);
        p = polyfit(features(:,fnum), smthp, 3);
    end
    err(fnum) = sum(abs(prob1-smthp));
    pAll(fnum,:) = p;
end
if rankErr
    % rank from smallest error
    [errRank, ind] = sort(err);
else
    errRank = err;
    ind = 1:totalFeatures;
end

% show component and curvefit
if showCurveFit
    figure;
    numRow = floor(numComponentUsed/2);
    numCol = ceil(numComponentUsed/numRow);
    for k = 1:numComponentUsed
        subplot(numRow,numCol,k);
        plot(features(:,ind(k)), prob1,'bx'); hold on
        smthp = polyval(pAll(ind(k),:),features(:,ind(k)));
        plot(features(:,ind(k)),smthp,'r.'); hold off
        ylim([0 1]); xlabel(['Component ',num2str(ind(k))]); ylabel('probability');
    end
end

% find weight for combining selected components
% -------------------------------------------------------------------------
normErrRank = errRank(1:numComponentUsed)/sum(errRank(1:numComponentUsed));
weight = zeros(1,numComponentUsed);
for k = 1:numComponentUsed
    weight(k) = prod(normErrRank([1:(k-1) (k+1):numComponentUsed]));
end
if isempty(weight)
    weight = 1;
else
    weight = weight/sum(weight(:));
end
estimateProb = zeros(numComponentUsed, length(smthp));
for k = 1:numComponentUsed
    smthp = polyval(pAll(ind(k),:),features(:,ind(k)));
    estimateProb(k,:) = weight(k)*smthp';
end
estimateProb = sum(estimateProb,1);
% expand prob to 0 - 1
if expand01final
    minv = min(estimateProb);
    maxv = max(estimateProb);
    estimateProb = (estimateProb-minv)./(maxv-minv);
end
estimateErr(numComponentUsed) = mean(abs(estimateProb'-prob1));
% show estimated pdf
[normh1, bin1] = normHistogram(prob1, 0:0.01:1);
[normh2, bin2] = normHistogram(estimateProb, 0:0.01:1);
histErr(numComponentUsed) = mean(abs(normh1-normh2));
if showCompareHist
    figure; plot(bin1, normh1); hold on
    plot(bin2, normh2,'r'); legend('svm prob','estimated prob', 'location','NorthWest');
    indused = num2str(ind(1));
    for k = 2:numComponentUsed
        indused = [indused,',',num2str(ind(k))];
    end
    title(['Total used components ',num2str(numComponentUsed), ' (',indused,')']);
end
errVarProb(numComponentUsed) = abs(var(estimateProb)-var(prob1));

if showCompareProb
    [propSort, indSort] = sort(prob1);
    figure; plot(estimateProb(indSort),'rx');hold on
    plot(propSort,'LineWidth',2); ylabel('probability'); xlabel('sorted index');
    legend('estimated prob','actual prob','location','best');
    title(['rankErr=',num2str(rankErr),', expand01=',num2str(expand01),', expand01final=',num2str(expand01final),', numComponentUsed=',num2str(numComponentUsed)]);
end