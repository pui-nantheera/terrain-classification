function LBPhist = findLBPhist(cubeImg, mask)

% addpath('./FEATURES/disCLBP/');

if nargin<2
    mask = ones(size(cubeImg));
end

numSample = 8;
mapping=getmapping(numSample,'u2'); 

% if cubeImg contains zeros
if sum(cubeImg(:)==0)
     for k = 1:size(cubeImg,2)
         curLine = cubeImg(:,k,:);
         ind = curLine(:,1,1)==0;
         if (ind(1)==1)
             [~,lastindx] = max(ind(1:end-1)-ind(2:end));
             getind = min(length(ind),lastindx + (lastindx:-1:1));
             cubeImg(1:lastindx,k,:) = curLine(getind,:,:);
         end
         if (ind(end)==1)
             [~,firstinx] = max(ind(end:-1:2)-ind(end-1:-1:1));
             getind = max(1,length(ind)-firstinx:-1:length(ind)-2*firstinx+1);
             cubeImg(end-firstinx+1:end,k,:) = curLine(getind,:,:);
         end
         % double check
         curLine = cubeImg(:,k,:);
         ind = curLine(:,1,1)==0;
         if (ind(1)==1)
             [~,lastindx] = max(ind(1:end-1)-ind(2:end));
             getind = min(length(ind),lastindx + (lastindx:-1:1));
             cubeImg(1:lastindx,k,:) = curLine(getind,:,:);
         end
         if (ind(end)==1)
             [~,firstinx] = max(ind(end:-1:2)-ind(end-1:-1:1));
             getind = max(1,length(ind)-firstinx:-1:length(ind)-2*firstinx+1);
             cubeImg(end-firstinx+1:end,k,:) = curLine(getind,:,:);
         end
     end
end

LBPhist = zeros(1,mapping.num);
for k = 1:size(cubeImg,3)
    I = cubeImg(:,:,k);
    LBPhist = LBPhist + LBP(I,1,numSample,mapping,'h', mask);
end
LBPhist = LBPhist/numel(cubeImg);