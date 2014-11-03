function textureType = svmPrediction(features, modelTexture, scaling1, scaling2)

% normalisation data
data = features;
Testing = (data - repmat(scaling1,size(data,1),1)).*(repmat(scaling2,size(data,1),1));

% prediction
textureType = svmpredict(1, Testing, modelTexture);