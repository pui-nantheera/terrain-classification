function histB = binaryUDTCWTinterlevel(img,wlevels,startlevel,numfeatures, mask)
% histB = binaryUDTCWTinterlevel(img,wlevels,startlevel,mask)
%           Find histogram of binary phase of undecimated DT-CWT (UDT-CWT)
%       inputs:
%           img - 2D matrix of grayscale image
%               - cell array of wavelet coefficients (result of UDT-CWT)
%           wlevels - Total decomposition level (default = log2(min(size(img)))-3);
%           startlevel - Finest included level  (default = 2);
%           numfeatures - number of features produced by histogram
%                         (default = 2^(2*(wlevels-startlevel+1)))
%           mask - 2D matrix defines region of interest
%       output:
%           histB - concatenated histogram of bit-planes of 6 subbands
%                   a number of features = 6*ceil(numfeatures/6);
%
%   v1.0 17-02-14 Pui Anantrasirichai, University of Bristol


% check inputs
% ------------
if size(img,3)>1
    img = rgb2gray(img);
end
if (nargin < 2) || isempty(wlevels)
    if ~iscell(img)
        wlevels = log2(min(size(img)))-3;
        disp(['Total decomposition level is not defined. L = ',num2str(wlevels),' is used.']);
    else
        wlevels = length(img) - 1;
    end
end
if (nargin < 3) || isempty(startlevel)
    startlevel = 2;
    disp('Finest included level is not defined. l_0 = 2 is used.');
end
if (nargin < 4) || isempty(numfeatures) || (numfeatures==0)
    rangeh = 0:(2^(2*(wlevels-startlevel+1)) - 1);
else
    eachsub = ceil(numfeatures/6);
    steph  = (2^(2*(wlevels-startlevel+1))-1)/(eachsub-1);
    rangeh = 0:steph:(2^(2*(wlevels-startlevel+1)) - 1);
end

% UDTCWT transformation
% ---------------------
if ~iscell(img)
    addpath('C:\Locomotion\code_motion\DTCWT\UDTCWT\');
    [Faf, ~] = NDAntonB2; %(Must use ND filters for both)
    [af, ~] = NDdualfilt1;
    w = NDxWav2DMEX(double(img), wlevels, Faf, af, 1);
    % image dimenstion
    [height, width] = size(img);
else
    w = img;
    % image dimenstion
    [height, width] = size(w{1}{1}{1}{1});
end

% check if mask is defined
% ------------------------
if (nargin < 5) || isempty(mask)
    mask = ones(height, width);
end

% Create bit-planes for each subband and generate histograms
% ----------------------------------------------------------
histindlength = length(rangeh);
histB = zeros(1,histindlength);
for c = 1:2
    for d = 1:3
        bitplanes = zeros(height, width);
        for level = startlevel:wlevels
            if level == wlevels
                realcoef = w{level}{1}{c}{d};
                imgcoef  = w{level}{2}{c}{d};
            else
                % Interlevel products
                parent = w{level+1}{1}{c}{d} + 1i*w{level+1}{2}{c}{d};
                parent = abs(parent).*exp(1i*2*angle(parent));
                child  = w{level}{1}{c}{d}   + 1i*w{level}{2}{c}{d};
                interProduct = child.*conj(parent);
                realcoef = real(interProduct);
                imgcoef  = imag(interProduct);
            end
            bitplanes = bitplanes + (realcoef>0)*(2^(2*(level-startlevel)));
            bitplanes = bitplanes + (imgcoef >0)*(2^(2*(level-startlevel)+1));
        end
        % histogram
        if (nargin >= 5)
            histQ1 = hist(bitplanes(mask(:)>0),rangeh);
        else
            histQ1 = hist(bitplanes(:),rangeh);
        end
        histQ1 = histQ1/sum(histQ1);
        histB(((c-1)*3+d-1)*histindlength + (1:histindlength)) = histQ1;
    end
end