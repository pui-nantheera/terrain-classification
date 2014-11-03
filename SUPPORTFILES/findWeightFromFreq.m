function wt = findWeightFromFreq(probGroup,mask,probPath,gapPixel,varProb,frey,frex, GOP)

if nargin < 8
    GOP = 1;
end

height = size(mask,1);
frameWindow = size(probGroup,1);
totalnumclass = size(probGroup,2);
% find prob of path consistency
curProb = probPath(:,:,1).*mask;
curProb(curProb==0) = [];
prob_Path = max(0.1,mode(curProb(:)));
% get position
STATS = regionprops(mask, 'Centroid');
cury = round(STATS(1).Centroid(2));
% weight by changing frequency
currangefreq = round(cury:gapPixel(cury)*GOP:(cury+gapPixel(cury)*GOP*frameWindow));
currangefreq = max(1,min(height,currangefreq));
% frequency of these ref
freqrefy = frey(currangefreq);
deltafreqy = freqrefy(1) - freqrefy(1:end);
deltafreqy = deltafreqy(end:-1:1)/4;
freqrefx = frex(currangefreq);
deltafreqx = freqrefx(1) - freqrefx(1:end);
deltafreqx = deltafreqx(end:-1:1)/2;
% find variance for each frame
allVar = zeros(frameWindow,totalnumclass);
allVar(end,:) = max(0.005,varProb(end,:)) + deltafreqy(end)*deltafreqx(end)/(prob_Path);
count = 0;
for k = frameWindow-1:-1:1
    allVar(k,:) = allVar(k+1,:) + deltafreqy(k)*deltafreqx(k)/(prob_Path);
    count = count + 1;
end
allVar = mean(allVar(:,1:2),2);
% find weight
w = 1./allVar;
wt = w./sum(w);