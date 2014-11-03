function featuresList = getFeatureListfromFULLtexture(featureGroupNum, spec)
% generate feature index (featureList) followed the defined
% 'featureGroupNum'. The full list of texture feature can be found in
% findTextureFeatures.m

if nargin < 2
    spec = '';
end

if strcmpi(spec,'best')
    
    % from best performance: aka featureGroupNum=6,
    % runPrepareTrainingFearues extract features only in this group
    featuresList = 1:120;
else
    % list of features
    % -------------------------------------------------------------------------
    intensity = 1:5;
    runlength = 6:16;
    glcmprop  = 17:23;
    wavelet   = 24:135;
    wavelet   = [wavelet(1:8) wavelet(17:64)]; % use only magnitude
    waveletglcm = 136:142;
    waveletrun  = 143:153;
    lbphist   = 154:212;
    
    selectedFeatures{1} = [wavelet lbphist];
    selectedFeatures{2} = [wavelet];
    selectedFeatures{3} = [lbphist];
    selectedFeatures{4} = [intensity wavelet]; %**best performance
    selectedFeatures{5} = [intensity lbphist];
    selectedFeatures{6} = [intensity wavelet lbphist]; %**best performance
    selectedFeatures{7} = [wavelet waveletrun];
    selectedFeatures{8} = [wavelet waveletrun lbphist];
    selectedFeatures{9} = [intensity runlength glcmprop wavelet lbphist];
    selectedFeatures{10} = [intensity runlength glcmprop wavelet waveletrun lbphist];
    % test wavelet 3 levels
    selectedFeatures{11} = [wavelet(1:3) wavelet(5:7) wavelet(9:26) wavelet(33:50)];
    % test wavelet only mean all subband
    selectedFeatures{12} = [wavelet(1:8)];
    
    featuresList = selectedFeatures{featureGroupNum};
end