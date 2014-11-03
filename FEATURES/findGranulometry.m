function Granhist = findGranulometry(cubeImg, granNum, dispPlots)
%granulometry

if nargin < 2
    granNum = 12;   %granulometry level
end
if nargin < 3
    dispPlots = 0;
end

th = 0.7;
highfirst = 1;
while (highfirst==1)&&(th>0)
    %threshold
    T = cubeImg > round(100*th*max(cubeImg(:)))/100;
    sumT = sum(T(:));
    
    surfarea = zeros(1,granNum+1);
    for counter = 0:granNum
        E = spherElem(counter);
        
        remain = imopen(T, E);
        sumR = sum(remain(:));
        surfarea(counter + 1) = sumR;
        if sumR == 0
            break;
        end
    end
    surfareaRS = surfarea/sumT;
    derivsurfarea{1} = -diff(surfareaRS);
    highfirst = derivsurfarea{1}(1) > derivsurfarea{1}(2);
    th = th-0.05;
end

it = 2;
jt = 2;
while it <= floor(granNum/3)
    derivsurfarea{jt} = filtfilt(gausswin(it)/sum(gausswin(it)),1,derivsurfarea{jt-1});
    it = it*2;
    jt = jt+1;
end
% histogram Granhist
Granhist = derivsurfarea{1};
for it=2:length(derivsurfarea)
    dsfT = downsample(derivsurfarea{it},2^(it-1));
    Granhist = [Granhist dsfT];
end

if dispPlots
    temp = Granhist;
    figure; 
    plot(Granhist(1:granNum), 'r','LineWidth', 1); hold on
    temp(1:granNum) = [];
    for k = 2:length(derivsurfarea)
        plot(temp(1:granNum/(2^(k-1))),'LineWidth', k);
        temp(1:granNum/(2^(k-1))) = [];
    end
    xlabel('particle size');
    ylabel('number of particles');
end