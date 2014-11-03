clear all


sigma0 = [0.0162];%;    0.0106;    0.0269];
sigmap = [0.0355];%    0.0383];

framenum = 1:10;
prob = 0.1:0.1:1;
alphaTest = 1./prob ;

wt = zeros(length(alphaTest), length(framenum));
wtnon = zeros(length(alphaTest), length(framenum));
legendAll = num2str(prob');
for alpha = alphaTest
    linearsigma = repmat(sigma0, [1 length(framenum)]) + framenum.*alpha.*sigmap(1);
    if alpha~=1
        nonlinearsigma = repmat(sigma0+alpha*sigmap, [1 length(framenum)]) + sigmap(1).*alpha.*(1-alpha.^(framenum-1))./(1-alpha);
    else
        nonlinearsigma = repmat(sigma0+alpha*sigmap, [1 length(framenum)]) + (framenum-1).*alpha.*sigmap(1);
    end
    
    % find weight
    
    for k = 1:length(framenum)
        wt(alphaTest==alpha,k) = prod(linearsigma(:,[1:k-1 k+1:end]),2);
        wtnon(alphaTest==alpha,k) = prod(nonlinearsigma(:,[1:k-1 k+1:end]),2);
    end
    wt(alphaTest==alpha,:) = wt(alphaTest==alpha,:)./repmat(sum(wt(alphaTest==alpha,:),2),[1 length(framenum)]);
    wtnon(alphaTest==alpha,:) = wtnon(alphaTest==alpha,:)./repmat(sum(wtnon(alphaTest==alpha,:),2),[1 length(framenum)]);
    legendName{alphaTest==alpha} = legendAll(alphaTest==alpha,:);
end

% figure; plot(wt'); title('Linear'); legend(legendName)
figure(11); hold on; plot(wtnon'); title('Non linear'); legend(legendName)

%%

framenum = 1:10;
prob = 0.1:0.1:1;
alphaTest = 1./prob;

wt = zeros(length(alphaTest), length(framenum));
wtnon = zeros(length(alphaTest), length(framenum));
legendAll = num2str(prob');
clear nonlinearsigma
for alpha = alphaTest
    nonlinearsigma = zeros(1,length(framenum));
    nonlinearsigma(1) = sigma0 +(alpha.^(1))*sigmap;
    for count = framenum(2:end)
        nonlinearsigma(count) = nonlinearsigma(count-1) + (alpha.^(count-1))*sigmap;
    end
    
    % find weight
    
    for k = 1:length(framenum)
        wtnon(alphaTest==alpha,k) = prod(nonlinearsigma(:,[1:k-1 k+1:end]),2);
    end
    wtnon(alphaTest==alpha,:) = wtnon(alphaTest==alpha,:)./repmat(sum(wtnon(alphaTest==alpha,:),2),[1 length(framenum)]);
    legendName{alphaTest==alpha} = legendAll(alphaTest==alpha,:);
end

% figure; plot(wt'); title('Linear'); legend(legendName)
figure(8); hold on; plot(wtnon'); title('Non linear'); legend(legendName)

%% CONSISTENT PATH

prob = 0.15;
sigmapRanget = 0.09;
sigmapRange =  0.1 - sigmapRanget;%sigmapRanget;
framenum = 1:5;
alpha = 1./prob;

wt = zeros(length(sigmapRange), length(framenum));
wtnon = zeros(length(sigmapRange), length(framenum));
legendAll = num2str(sigmapRanget');
for sigmap = sigmapRange
    if alpha~=1
        nonlinearsigma = repmat(sigma0, [1 length(framenum)]) + sigmap./alpha.*(1-alpha.^framenum)./(1-alpha);
    else
        nonlinearsigma = repmat(sigma0, [1 length(framenum)]) + framenum.*alpha.*sigmap;
    end
    
    % find weight
%     for k = 1:length(framenum)
%         wtnon(sigmapRange==sigmap,k) = prod(nonlinearsigma(:,[1:k-1 k+1:end]),2);
%     end
    wtnon(sigmapRange==sigmap,:) = 1./nonlinearsigma;
    wtnon(sigmapRange==sigmap,:) = wtnon(sigmapRange==sigmap,:)./repmat(sum(wtnon(sigmapRange==sigmap,:),2),[1 length(framenum)]);
    legendName{sigmapRange==sigmap} = legendAll(sigmapRange==sigmap,:);
end

% figure; plot(wt'); title('Linear'); legend(legendName)
figure; plot(wtnon'); title('Non linear - prob=0.15'); legend(legendName)