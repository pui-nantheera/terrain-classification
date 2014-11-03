function histQ = histCWT(img,wlevels,option,biort,qshift, mask)

addpath('C:\Locomotion\code_motion\DTCWT\');
addpath('C:\Locomotion\code_motion\FEATURES\');

if nargin < 3
    option = 0;
end
if nargin < 4
    biort = 'antonini';
end
if nargin < 5
    qshift = 'qshift_06';
end


if (option == 2)||(option == 4)
    % overcomplete wavelet
    [lowcoef,highcoef] = dtwavexfm2overcomplete(double(img),wlevels,biort,qshift);
elseif (option >= 8)
    if ~iscell(img)
        % Paul's UDTCWT
        addpath('C:\Locomotion\code_motion\DTCWT\UDTCWT\');
        [Faf, Fsf] = NDAntonB2; %(Must use ND filters for both)
        [af, sf] = NDdualfilt1;
        maxlevel = min(wlevels, floor(log2(min(size(img))/5)));
        w = NDxWav2DMEX(double(img), maxlevel, Faf, af, 1);
        % if more levels are required
        if wlevels > maxlevel
            lowcoef = (w{maxlevel+1}{1}{1}+w{maxlevel+1}{1}{2}+w{maxlevel+1}{2}{1}+w{maxlevel+1}{2}{2});
            morelevels = wlevels - maxlevel;
            wmore = NDxWav2DMEX(double(lowcoef), morelevels, af, af, 1);
            for level = 1:morelevels+1
                w{maxlevel+level} = wmore{level};
            end
        end
        if (option ~= 16)&&(option ~= 161)
            for level = 1:maxlevel
                highcoef{level} = [];
                for c = 1:2
                    for d = 1:3
                        highcoef{level} = cat(3,highcoef{level},w{level}{1}{c}{d} + 1i*w{level}{2}{c}{d});
                    end
                end
            end
            lowcoef = (w{maxlevel+1}{1}{1}+w{maxlevel+1}{1}{2}+w{maxlevel+1}{2}{1}+w{maxlevel+1}{2}{2});
            if wlevels > maxlevel
                morelevels = wlevels - maxlevel;
                w = NDxWav2DMEX(double(lowcoef), morelevels, Faf, af, 1);
                for level = 1:morelevels
                    highcoef{maxlevel+level} = [];
                    for c = 1:2
                        for d = 1:3
                            highcoef{maxlevel+level} = cat(3,highcoef{maxlevel+level},w{level}{1}{c}{d} + 1i*w{level}{2}{c}{d});
                        end
                    end
                end
                lowcoef = (w{morelevels+1}{1}{1}+w{morelevels+1}{1}{2}+w{morelevels+1}{2}{1}+w{morelevels+1}{2}{2});
            end
        end
        % image dimenstion
        [height, width] = size(img);
    else
        w = img;
        % image dimenstion
        [height, width] = size(w{1}{1}{1}{1});
    end
elseif (option ~= 7)
    % wavelet transform
    [lowcoef,highcoef] = dtwavexfm2(double(img),wlevels,biort,qshift);
end

if nargin < 6
    mask = ones(height, width);
end

if option == 0
    % find mean and variance of each subband and each level
    histQ = findCWTProp(lowcoef, highcoef, 0, 8, [], 0);
elseif option == 1
    % quantise
    quantiseMap = zeros(size(highcoef{1},1),size(highcoef{1},2));
    for level = 1:wlevels
        curMap = mean(highcoef{level},3);
        if level > 1
            temp = curMap;
            curMap = zeros(size(quantiseMap));
            for ki = 1:(2^(level-1))
                for kj = 1:(2^(level-1))
                    curMap(ki:(2^(level-1)):end,kj:(2^(level-1)):end) = temp;
                end
            end
        end
        quantiseMap = quantiseMap + (real(curMap)>0)*(2^((level-1)*2+1-1));
        quantiseMap = quantiseMap + (imag(curMap)>0)*(2^((level-1)*2+2-1));
    end
    % histogram
    histQ = hist(quantiseMap(:),0:(2^(wlevels*2) - 1));
    histQ = histQ/sum(histQ);
elseif option == 2
    % quantise
    quantiseMap = zeros(size(img));
    for level = 1:wlevels
        curMap = mean(highcoef{level},3);
        quantiseMap = quantiseMap + (real(curMap)>0)*(2^((level-1)*2+1-1));
        quantiseMap = quantiseMap + (imag(curMap)>0)*(2^((level-1)*2+2-1));
    end
    % histogram
    histQ = hist(quantiseMap(:),0:(2^(wlevels*2) - 1));
    histQ = histQ/sum(histQ);
elseif (option == 4)||(option == 8)
    % quantise
    quantiseMap = zeros(size(img));
    for level = 1:wlevels
        curMap = mean(highcoef{level},3);
        quantiseMap = quantiseMap + (real(curMap)>0)*(2^((level-1)*2+1-1));
        quantiseMap = quantiseMap + (imag(curMap)>0)*(2^((level-1)*2+2-1));
    end
    % histogram
    histQ1 = hist(quantiseMap(:),0:(2^(wlevels*2) - 1));
    histQ1 = histQ1/sum(histQ1);
    % find mean and variance of each subband and each level
    histQ2 = findCWTProp(lowcoef, highcoef, 0, 8, [], 0);
    histQ  = [histQ1 histQ2];
elseif option == 5
    histQ = [];
    for level = 2:wlevels
        curHx = abs(highcoef{level});
        range = 0:0.3*((level-1)*3+1):15*((level-1)*3+1);
        nx = hist(abs(curHx(:)),range);
        histQ = [histQ nx(wlevels-level+2:end)];
    end
elseif option == 6.5 % (0 + 1.5)
    quantiseMap = zeros(size(highcoef{1},1),size(highcoef{1},2));
    for level = 1:wlevels
        realH = real(mean(highcoef{level},3));
        imagH = imag(mean(highcoef{level},3));
        if level > 1
            % interpolate
            realH = imresize(realH, 2^(level-1));
            imagH = imresize(imagH, 2^(level-1));
        end
        quantiseMap = quantiseMap + (realH>0)*(2^((level-1)*2+1-1));
        quantiseMap = quantiseMap + (imagH>0)*(2^((level-1)*2+2-1));
    end
    % histogram
    histQ2 = hist(quantiseMap(:),0:(2^(wlevels*2) - 1));
    histQ2 = histQ2/sum(histQ2);
    % find mean and variance of each subband and each level
    histQ1 = findCWTProp(lowcoef, highcoef, 0, 8, [], 0);
    histQ  = [histQ1 histQ2];
elseif option == 7
    [lowcoef,highcoef] = dtwavexfm2overcompleteDecorr(double(img),wlevels,biort,qshift);

elseif (option == 9)
    % quantise
    quantiseMap = zeros(size(img));
    for level = 1:wlevels
        curMap = mean(highcoef{level},3);
        quantiseMap = quantiseMap + (real(curMap)>0)*(2^((level-1)*2+1-1));
        quantiseMap = quantiseMap + (imag(curMap)>0)*(2^((level-1)*2+2-1));
    end
    % histogram
    histQ1 = hist(quantiseMap(:),0:(2^(wlevels*2) - 1));
    histQ1 = histQ1/sum(histQ1);
    % find mean and variance of each subband and each level
    histQ2 = findCWTProp(lowcoef, highcoef, 0, 8, [], 0);
    histQ  = [histQ1 histQ2];
    % for each subband
    for subband = 1:6
        quantiseMap = zeros(size(img));
        for level = 1:wlevels
            curMap = highcoef{level}(:,:,subband);
            quantiseMap = quantiseMap + (real(curMap)>0)*(2^((level-1)*2+1-1));
            quantiseMap = quantiseMap + (imag(curMap)>0)*(2^((level-1)*2+2-1));
        end
        % histogram
        histQ1 = hist(quantiseMap(:),0:(2^(wlevels*2) - 1));
        histQ1 = histQ1/sum(histQ1);
        histQ = [histQ histQ1];
    end
elseif (option == 10)||(option == 11)
    % find mean and variance of each subband and each level
    histQ = findCWTProp(lowcoef, highcoef, 0, 8, [], 0);
 
    % for each subband
    for subband = 1:6
        quantiseMap = zeros(size(img));
        for level = 1:wlevels
            curMap = highcoef{level}(:,:,subband);
            quantiseMap = quantiseMap + (real(curMap)>0)*(2^((level-1)*2+1-1));
            quantiseMap = quantiseMap + (imag(curMap)>0)*(2^((level-1)*2+2-1));
        end
        % histogram
        histQ1 = hist(quantiseMap(:),0:(2^(wlevels*2) - 1));
        histQ1 = histQ1/sum(histQ1);
        histQ = [histQ histQ1];
    end
elseif (option == 12)
    histQ = [];
    % for each subband
    for subband = 1:6
        quantiseMap = zeros(size(img));
        for level = 1:wlevels
            curMap = highcoef{level}(:,:,subband);
            quantiseMap = quantiseMap + (real(curMap)>0)*(2^((level-1)*2+1-1));
            quantiseMap = quantiseMap + (imag(curMap)>0)*(2^((level-1)*2+2-1));
        end
        % histogram
        histQ1 = hist(quantiseMap(:),0:(2^(wlevels*2) - 1));
        histQ1 = histQ1/sum(histQ1);
        histQ = [histQ histQ1];
    end
elseif (option == 13)
    % find mean and variance of each subband and each level
    histQ = findCWTProp(lowcoef, highcoef, 0, 8, [], 0);
    % for each subband
    for subband = 1:6
        % real part
        quantiseMap = zeros(size(img));
        for level = 1:wlevels
            curMap = highcoef{level}(:,:,subband);
            quantiseMap = quantiseMap + (real(curMap)>0)*(2^(level-1));
        end
        histQ1 = hist(quantiseMap(:),0:(2^(wlevels) - 1));
        histQ1 = histQ1/sum(histQ1);
        histQ = [histQ histQ1];
        % imaginary part
        quantiseMap = zeros(size(img));
        for level = 1:wlevels
            curMap = highcoef{level}(:,:,subband);
            quantiseMap = quantiseMap + (imag(curMap)>0)*(2^(level-1));
        end
        histQ1 = hist(quantiseMap(:),0:(2^(wlevels) - 1));
        histQ1 = histQ1/sum(histQ1);
        histQ = [histQ histQ1];
    end
elseif (option == 14)||(option == 15)
    % find mean and variance of each subband and each level
    histQ = [];
    if (option == 14)
        if (nargin >= 6)
            histQ = findCWTProp(lowcoef, highcoef, mask, 8, [], 0);
        else
            histQ = findCWTProp(lowcoef, highcoef, 0, 8, [], 0);
        end
    end
 
    % for each subband
    for subband = 1:6
        quantiseMap = zeros(size(img));
        for level = 1:wlevels-1
            curMap = highcoef{level+1}(:,:,subband);
            quantiseMap = quantiseMap + (real(curMap)>0)*(2^((level-1)*2+1-1));
            quantiseMap = quantiseMap + (imag(curMap)>0)*(2^((level-1)*2+2-1));
        end
        % histogram
        if (nargin >= 6)
            histQ1 = hist(quantiseMap(mask(:)>0),0:(2^((wlevels-1)*2) - 1));
        else
            histQ1 = hist(quantiseMap(:),0:(2^((wlevels-1)*2) - 1));
        end
        histQ1 = histQ1/sum(histQ1);
        histQ = [histQ histQ1];
    end
elseif (option == 16)
    
    startlevel = 2;
    rangeh = 0:(2^(2*(wlevels-startlevel+1)) - 1);
    bitplanes = zeros(height, width);
    for level = startlevel:wlevels
        realcoef = zeros(height, width);
        imgcoef = zeros(height, width);
        for c = 1:2
            for d = 1:3
                realcoef = realcoef + w{level}{1}{c}{d};
                imgcoef  = imgcoef + w{level}{2}{c}{d};
            end
        end
        realcoef = realcoef/6;
        imgcoef  = imgcoef/6;
        bitplanes = bitplanes + (realcoef>0)*(2^(2*(level-startlevel)));
        bitplanes = bitplanes + (imgcoef >0)*(2^(2*(level-startlevel)+1));
    end
    % histogram
    if (nargin >= 6)
        histQ1 = hist(bitplanes(mask(:)>0),rangeh);
    else
        histQ1 = hist(bitplanes(:),rangeh);
    end
    histQ = histQ1/sum(histQ1);

elseif (option == 161)
    
    meanAbs   = [];  varAbs    = [];
    meanAbsAll   = [];  varAbsAll    = [];
    startlevel = 2;
    rangeh = 0:(2^(2*(wlevels-startlevel+1)) - 1);
    bitplanes = zeros(height, width);
    for level = startlevel:wlevels
        realcoef = zeros(height, width);
        imgcoef = zeros(height, width);
        curData = [];
        for c = 1:2
            for d = 1:3
                realcoef = realcoef + w{level}{1}{c}{d};
                imgcoef  = imgcoef + w{level}{2}{c}{d};
                subData = (w{level}{1}{c}{d}(:) + 1i*w{level}{2}{c}{d}(:));
                curData = [curData; subData];
                meanAbs = [meanAbs mean(abs(subData(mask(:))))];
                varAbs  = [varAbs var(abs(subData(mask(:))))];
            end
        end
        realcoef = realcoef/6;
        imgcoef  = imgcoef/6;
        meanAbsAll = [meanAbsAll mean(abs(curData(:)))];
        varAbsAll  = [varAbsAll var(abs(curData(:)))];
        bitplanes = bitplanes + (realcoef>0)*(2^(2*(level-startlevel)));
        bitplanes = bitplanes + (imgcoef >0)*(2^(2*(level-startlevel)+1));
    end
    % histogram
    if (nargin >= 6)
        histQ1 = hist(bitplanes(mask(:)>0),rangeh);
    else
        histQ1 = hist(bitplanes(:),rangeh);
    end
    histQ = histQ1/sum(histQ1);
    
    % properties of the high-pass subband
    histQ = [histQ meanAbsAll varAbsAll meanAbs varAbs];
end
