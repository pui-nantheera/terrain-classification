function intensityFeatures = findIntensityDistFeatures(cubeImg)
%#codegen
coder.inline('never');

% 1) mean
meanCube = mean(cubeImg);
% 2) variance
varCube = var(cubeImg);
% 3) skewness
    % skewCube = skewness(cubeImg(mask(:)>0));
    % Need to tile the output of nanmean to center X.
    tile = ones(1,2);
    tile(1) = length(cubeImg);

    % Center X, compute its third and second moments, and compute the
    % uncorrected skewness.
    x0 = cubeImg - repmat(nanmean(cubeImg), tile);
    s2 = nanmean(x0.^2); % this is the biased variance estimator
    m3 = nanmean(x0.^3);
    skewCube = m3 ./ s2.^(1.5);


% 4) kurtosis
    % kurtCube = kurtosis(cubeImg(mask(:)>0));
    m4 = nanmean(x0.^4);
    kurtCube = m4 ./ s2.^2;

% 5) entropy
% entropyCube = entropy(cubeImg(mask(:)>0));
    if max(cubeImg(:)) < 10
        p = hist(255*cubeImg,0:255);
    else
        p = hist(cubeImg,0:255);
    end
    p(p==0) = [];
    % normalize p so that sum(p) is one.
    p = p ./ numel(cubeImg);
    entropyCube = -sum(p.*log2(p));

% combine
intensityFeatures = [meanCube varCube skewCube kurtCube entropyCube];