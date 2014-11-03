function glcmStat = findGLCMProp(cubeImg, mask)

%addpath('./FEATURES/disCLBP/');

if nargin < 2
    mask = ones(size(cubeImg));
end

if max(cubeImg(:))>1
    cubeImg = cubeImg/255;
    cubeImg(cubeImg>1) = 1;
end

% 1) angular second moment or energy
energyCube = [];
% 2) correlation
correlateCube = [];
% 3) contrast or inertia
contrastCube = [];
% 4) entropy
entropyCube = [];
% 5) Cluster Shade
clusterCube = [];
% 6) inverse difference moment
invertDiffMomentCube = [];
% 7) Homogeneity
homoCube = [];

for k = 1:size(cubeImg,3)
    glcm = graycomatrix1(cubeImg(:,:,k),'Offset',[0 1;-1 1;-1 0;-1 -1], 'Mask', mask);
    out = GLCM_Features1(glcm);
    energyCube = [energyCube out.energ];
    correlateCube = [correlateCube out.corrm];
    contrastCube = [contrastCube out.contr];
    entropyCube = [entropyCube out.entro];
    clusterCube = [clusterCube out.cshad];
    invertDiffMomentCube = [invertDiffMomentCube out.idmnc];
    homoCube = [homoCube out.homom];
end
if size(cubeImg,3)>1
    reCubeImg = permute(cubeImg, [1 3 2]);
    remask = permute(mask, [1 3 2]);
    for k = 1:size(reCubeImg,3)
        glcm = graycomatrix1(reCubeImg(:,:,k),'Offset',[0 1;-1 1;-1 0;-1 -1], 'Mask', remask);
        out = GLCM_Features1(glcm);
        energyCube = [energyCube out.energ];
        correlateCube = [correlateCube out.corrm];
        contrastCube = [contrastCube out.contr];
        entropyCube = [entropyCube out.entro];
        clusterCube = [clusterCube out.cshad];
        invertDiffMomentCube = [invertDiffMomentCube out.idmnc];
        homoCube = [homoCube out.homom];
    end
    reCubeImg = permute(cubeImg, [3 2 1]);
    remask = permute(mask, [3 2 1]);
    for k = 1:size(reCubeImg,3)
        glcm = graycomatrix1(reCubeImg(:,:,k),'Offset',[0 1;-1 1;-1 0;-1 -1], 'Mask', remask);
        out = GLCM_Features1(glcm);
        energyCube = [energyCube out.energ];
        correlateCube = [correlateCube out.corrm];
        contrastCube = [contrastCube out.contr];
        entropyCube = [entropyCube out.entro];
        clusterCube = [clusterCube out.cshad];
        invertDiffMomentCube = [invertDiffMomentCube out.idmnc];
        homoCube = [homoCube out.homom];
    end
end
energyCube(isnan(energyCube)) = [];
correlateCube(isnan(correlateCube)) = [];
contrastCube(isnan(contrastCube)) = [];
entropyCube(isnan(entropyCube)) = [];
clusterCube(isnan(clusterCube)) = [];
invertDiffMomentCube(isnan(invertDiffMomentCube)) = [];
homoCube(isnan(homoCube)) = [];

energyCube = mean(energyCube);
correlateCube = mean(correlateCube);
contrastCube = mean(contrastCube);
entropyCube = mean(entropyCube);
clusterCube = mean(clusterCube);
invertDiffMomentCube = mean(invertDiffMomentCube);
homoCube = mean(homoCube);

% out put
glcmStat = [energyCube correlateCube contrastCube entropyCube clusterCube invertDiffMomentCube homoCube];