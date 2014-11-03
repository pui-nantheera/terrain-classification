function [normh, bin] = normHistogram(data, specBin)

if nargin<2
    mindata = min(data(:));
    maxdata = max(data(:));
    gap = (maxdata-mindata)/100;
    specBin = mindata-gap:gap:maxdata+gap;
end
[f, bin] = hist(data(:), specBin);
normh = f/trapz(bin,f);