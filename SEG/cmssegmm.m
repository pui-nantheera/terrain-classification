function [overlay,intolay,map,intmap,gsurf,mapwithborder] =cmssegmm(someImVol, imorig, someHighCoefVol, levels,t1,t2, t3,hminfactor,merge, filterNoErode)
% [overlay,intolay,map,intmap] =cmssegmm(someImVol,type);
% Combined morphological-spectral multimodal segmentation
% Inputs -  someImVol: registered image set
%           someHighCoefVol are the High pass wavelet coefficients for all the images. 
%           type: only joint is used here - well there's only one image
%           input
%
% Outputs - overlay,intoverlay: segmentation overlayed on mean image
%           map, intmap: integer segmentation maps
%
% "int" refers to the intermediate map, before spectral clustering

if isempty(someHighCoefVol);
    [~,someHighCoefVol] = dtwavexfm2(imorig,levels,'antonini','qshift_06');
end

N=size(someImVol,1);
M=size(someImVol,2);
gsurf = zeros(N,M);

global globalmax;
globalmax = zeros(levels.*6,size(someImVol,3));
%%
tvol = [];

for k=1:size(someImVol,3);
    someIm = someImVol(:,:,k);
    tvold = someHighCoefVol(:,k);
    
    for n=1:levels;
        tvold{n} = abs(tvold{n}(:,:,[1 6 3 4 2 5]));  %rearrange for backward compatibility with older code
        globalmax((n-1)*6+1:n*6,k) = squeeze(max(max(tvold{n},[],2),[],1))./(2.^n);
    end;
    if k <=1
        col = 0;
    else 
        col = 1;
    end;
    
    [gsurfpart(:,:,k),tvolpart,tvolNoErode] =segprotomm(tvold,double(someIm), col, filterNoErode);
    tvol=cat(3,tvol,tvolpart);
end;
clear tvolpart tvold someIm someHighCoefVol;

    gsurf = sum(gsurfpart,3);
    gradmed = median(gsurf(:));
    map = watershed(imhmin(gsurf,hminfactor*gradmed));
 %%   

    clear gradmed
    %shave off nobbly bits in watersheds (trust me, I know what I'm talking about)
    sed = strel('square',3);
    map2 = zeros(size(map));
    for k=1:max(map(:));
        map2(imclose(map==k,sed)) = k;
    end;

    intmap = map2;
    someImVol = imorig;
    if( merge )
        map = mergestatcombmm(map2,tvolNoErode,double(someImVol),t1,t2, t3);
    else
        map = map2;
    end
    
    % <PUI> I guess this part is for removing region boudaries (map==0).
    mapwithborder = map;
    bw = ones(size(map));
    border = find(map==0);
    bw(border)=0;
    [D ind] = bwdist(bw);
    map(border) = map(ind(border));
    
    %crappy pixel fusion just to see overlay result
    someIm = uint8(mean(double(someImVol),3));
    
    % <PUI> For display
    edges = zeros(size(map));
    edges(1:end-1,:) = map(1:end-1,:)~=map(2:end,:);
    edges(:,1:end-1) = edges(:,1:end-1) + (map(:,1:end-1)~=map(:,2:end));
    edges = (edges>0)*255;
    overlay = max(uint8(edges),someIm);
    edges = (intmap==0).*255;
    intolay = max(uint8(edges),someIm);

clear gsurfpart


return;