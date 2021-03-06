function outmap2 = mergestatcombmm(map,tvol,gvol,t1,t2, t3)
%This version is now based on recursive spectral segmentation
% texdegree = texen./max(texen(:));
binsperdim=64;

origmap = map;
regions=nonzeros(unique(map(:)));
numreg = length(regions);

%adjacemat = zeros(numreg);                     Non sparse version
adjacemat = spalloc(numreg,numreg,3*numreg);   %Sparse version
dists1 = adjacemat;
dists2=dists1;
se1 = strel('line',6,0);
se2 = strel('line',6,90);
se3 = strel('square',3);
se4 = strel('square',5);

%generate eroded region map, which is only used to train the classes for
%region difference calculation
erodemap = zeros(size(map)+2);
map4erode = erodemap;
map4erode(2:end-1,2:end-1) = map;  %need to pad coz otherwise regions on periphery will erode towards edge!

for k=1:numreg;
    template=(map4erode==k);
    prevtemplate=template;
    numerodes=0;
    while((nnz(template)>(6*binsperdim))&(numerodes<7)); 
        prevtemplate=template;
        template=imerode(template,se4);
        numerodes=numerodes+1;
    end;
    erodemap(prevtemplate)=k;
end;
clear map4erode;
erodemap = erodemap(2:end-1,2:end-1);


keepinds = find(erodemap);

featvolt = reshape(tvol,size(tvol,1)*size(tvol,2),size(tvol,3));
featvolg = reshape(gvol,size(gvol,1)*size(gvol,2),size(gvol,3));
clear tvol gvol;



%Quantize texture feature set   (involves scaling into uniform range)
%make the bins equal width, over the range of the image

% tsize = size(featvolt);
% featvolt = featvolt(keepinds,:);

maxvec = max(featvolt,[],1);
global globalmax;
maxvec = max(globalmax(:).'./2,maxvec);

binwidths = maxvec./binsperdim;
%featvolt = floor(featvolt./repmat(binwidths,size(featvolt,1),1))+1;
for k=1:size(featvolt,1);
    featvolt(k,:) = floor(featvolt(k,:)./binwidths)+1;
end;
featvolt(featvolt>binsperdim)=binsperdim;  %just to force maxima into the bins

%Quantize intensity feature set   (involves scaling into uniform range)
%make the bins equal width, over the range of the image

tempvol = zeros(size(featvolg));
featvolg = featvolg(keepinds,:);

maxvec = 255.*ones(1,size(featvolg,2));

binwidths = maxvec./binsperdim;
featvolg = floor(featvolg./repmat(binwidths,size(featvolg,1),1))+1;
featvolg(featvolg>binsperdim)=binsperdim;  %just to force maxima into the bins

tempvol(keepinds,:) = featvolg;
featvolg = tempvol;
clear tempvol;


%Find Adjacency
for k=1:numreg;
    overlap = imdilate((map==regions(k)),se1); %for watershed pixels
    overlap = overlap|imdilate((map==regions(k)),se2);
    map(map==k)=0;
    adjvec = map(overlap);
    adjvecun=unique(adjvec(adjvec>0));
    for i=1:size(adjvecun);
        adjacemat(adjvecun(i),k)=nnz(adjvec==adjvecun(i));
    end;
end;
map=origmap;
clear origmap;
adjacemat = adjacemat + adjacemat';

[xpos,ypos] = find(triu(adjacemat));
for k=1:length(xpos);
    % for debug -----------------------------------------------------------
    if ((xpos(k)==32)||(ypos(k)==32))
        ['debug'];
    end
    % ---------------------------------------------------------------------
    template1=(erodemap==xpos(k));
    template2=(erodemap==ypos(k));
    reg1t = featvolt(template1(:),:);
    reg2t = featvolt(template2(:),:);
    reg1g = featvolg(template1(:),:);
    reg2g = featvolg(template2(:),:);
    
    reg1t(reg1t==0) = 1;    reg2t(reg2t==0) = 1;
    reg1g(reg1g==0) = 1;    reg2g(reg2g==0) = 1;
    if ((sum(sum(reg1t==0))+sum(sum(reg2t==0))+sum(sum(reg1g==0))+sum(sum(reg2g==0)))>0)
        dists1(xpos(k),ypos(k)) = 1000000000000;
    else
        
        % <PUI> using matlab version - added weight to texdiff according to
        % mean magnitude of each subband
        [texdiff,greydiff]=distcalcmhMAT(reg1t,reg2t,reg1g,reg2g,binsperdim);
        
        dists1(xpos(k),ypos(k)) = max([greydiff,texdiff]);
    end;

end;
clear featvolg featvolg erodemap;

dists1 = dists1+dists1.';
dists = dists1;%+dists2;
origdists = dists;

aff = dists;
%non sparse version
%aff(aff==0) = 1;
%aff = 1-aff;
%aff(logical(eye(size(aff))))=1; %try self-affinity =1

% sparse version
[ai, aj] = find(aff);
for yaff = 1: size(ai,1)
        aff(ai(yaff),aj(yaff)) = 1 - aff(ai(yaff),aj(yaff));
end

saff = size(aff);
for yaff = 1: saff(1)
        aff(yaff,yaff) = 1;
end

inInds = 1:saff(1);
global globalInds;
globalInds = 1:saff(1);

% <PUI> try without concerning how much two areas connect - seem to produce
% more number of regions (fewer merged regions)
% specsplit5(aff,adjacemat,t1,t2, inInds);
specsplit5(aff.*adjacemat,adjacemat,t1,t2, inInds);

W = aff;


%**************************************************************************
%***************NEW BIT ***************************************************
% Added for sonar: take out small regions
% Loop for the length of number of regions
merged = 1;

% NOT TESTED
% loop until no more small regions are merged
while merged == 1;
    uniqueInds = unique(globalInds);
    merged = 0;
    noofregions = size(uniqueInds,2);
    if noofregions == 1;
        break;
    end;
    for k=1:length(uniqueInds);
        fInds = find(globalInds==uniqueInds(k));
        sizeofk = 0;
        addstufftogether = zeros(size(adjacemat,1),1);
        addadjacencystogether = zeros(size(adjacemat,1),1);
        for n=1:length(fInds)
            sizeofk = sizeofk + sum(sum((map==fInds(n))));
            addstufftogether = addstufftogether + W(:,fInds(n));
            addadjacencystogether = addadjacencystogether + (adjacemat(:,fInds(n))~=0);
        end
        addadjacencystogether(addadjacencystogether==0) = realmax;
        addstufftogether = addstufftogether./addadjacencystogether;
        if sizeofk < t3
            repeatmax = 1;
            while repeatmax
                [dummy,indMax] = max(addstufftogether);
                regiontomergeindex = globalInds(indMax);
                if regiontomergeindex == uniqueInds(k)
                    addstufftogether(indMax) = 0;
                    if sum(addstufftogether) == 0
                        repeatmax = 0;
                    end;
                else
                    merged = 1;
                    repeatmax = 0;
                    globalInds(globalInds==uniqueInds(k)) = regiontomergeindex;
                end;
            end;
        end
        if merged == 1;
            break;
        end;
    end;
end;

%**************************************************************************
%***************NEW BIT ***************************************************

outmap2 = zeros(size(map));
uniqueInds = unique(globalInds);
for k=1:length(uniqueInds);
    fInds = find(globalInds==uniqueInds(k));
    for n=1:length(fInds);
        outmap2(map==fInds(n))= k;
    end
end;

for k=0:max(outmap2(:));
    outmap2(imclose(outmap2==k,se3))=k;
end;
    
% label unique region
outmap2 = bwlabel(outmap2>0);

return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [texturediff,intensediff] = distcalcmhMAT(r1t,r2t,r1g,r2g,binsperdim); %marginal histograms with either EMD or L1 measures


%texture first
r1 = r1t; r2 = r2t;
N=size(r1,1);
M=size(r2,1);
numdims = size(r1,2);

histObj1 = zeros(binsperdim,numdims);
histObj2 = histObj1;

for n=1:N;
    for k=1:numdims;
        histObj1(r1(n,k),k) = histObj1(r1(n,k),k) +1;
    end;
end;
for n=1:M;
    for k=1:numdims;
        histObj2(r2(n,k),k) = histObj2(r2(n,k),k) +1;
    end;
end;
histObj1 = histObj1./N;
histObj2 = histObj2./M;
%1-D EMD dist now

histObj1 = cumsum(histObj1,1);
histObj2 = cumsum(histObj2,1);
% histObj1(:,1:end-1) = cumsum(histObj1(:,1:end-1),1);
% histObj2(:,1:end-1) = cumsum(histObj2(:,1:end-1),1);
histObj1 = abs(histObj1-histObj2);
dvec = sum(histObj1,1)./(binsperdim-1);

% <PUI> find weight from binary distance ----------------------------------
meanMag1 = mean(r1,1);
meanMag2 = mean(r2,1);
% binary pattern
binaryPattern1 = meanMag1(2:end) > meanMag1(1:end-1);
binaryPattern2 = meanMag2(2:end) > meanMag2(1:end-1);
% weight
weight = sum(binaryPattern1~=binaryPattern2);
weight = weight/length(meanMag1)*6;
% -------------------------------------------------------------------------

% final texture distance value
texturediff = min(max(dvec).*weight,1);

%now greyscale
r1 = r1g; r2 = r2g;
N=size(r1,1);
M=size(r2,1);
numdims = size(r1,2);

histObj1 = zeros(binsperdim,numdims);
histObj2 = histObj1;

for n=1:N;
    for k=1:numdims;
        
            histObj1(r1(n,k),k) = histObj1(r1(n,k),k) +1;
        
    end;
end;
for n=1:M;
    for k=1:numdims;
        
            histObj2(r2(n,k),k) = histObj2(r2(n,k),k) +1;
        
    end;
end;
histObj1 = histObj1./N;
histObj2 = histObj2./M;
%1-D EMD dist now

histObj1 = cumsum(histObj1,1);
histObj2 = cumsum(histObj2,1);
% histObj1(:,1:end-1) = cumsum(histObj1(:,1:end-1),1);
% histObj2(:,1:end-1) = cumsum(histObj2(:,1:end-1),1);
histObj1 = abs(histObj1-histObj2);
dvec = sum(histObj1,1)./(binsperdim-1);
intensediff = min(max(dvec).*2,1);

return;