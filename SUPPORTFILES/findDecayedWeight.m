function wt = findDecayedWeight(probGroup,weighttype,mask,probPath,gapPixel,varProb,frey,frex,GOP)

switch weighttype
    case 'projfreq'
        % compute weight from frequency projection
        wt = findWeightFromFreq(probGroup,mask,probPath,gapPixel,varProb,frey,frex,GOP);
    case 'raisedcosine'
        beta = 1;
        T = 1/(size(probGroup,1));
        f = abs((1:size(probGroup,1)) - 1/T);
        wcosine = T/2*(1+cos(pi*T*(f - (1-beta)/2/T)/beta));
        wcosine(f<=((1-beta)/2/T)) = T;
        wcosine(f>((1+beta)/2/T)) = 0;
        wt = wcosine'/sum(wcosine);
    case 'linear'
        linwt = 1:size(probGroup,1);
        wt = linwt'/sum(linwt);
    case 'gaussian'
        f = -size(probGroup,1)+1:0;
        varf  = 2*size(probGroup,1);
        wexpo = exp(-(f.^2)/2/varf);
        wt = wexpo'/sum(wexpo);
    otherwise
        wt = ones(size(probGroup,1),1)/size(probGroup,1);
end