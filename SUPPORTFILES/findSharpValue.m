function sharpValue = findSharpValue(img, mask)
% sharpValue = findSharpValue(img)
%   use gradient to find sharpness

% dimension
[h,w,d] = size(img);

if nargin < 2
    % create mask
    mask = zeros(h,w);
    mask(100:end-100,100:end-100) = 1;
    divider = h*w;
else
    divider = sum(mask(:));
end

% colour transform
if d==3
    yuv = rgb2ycbcr(img);
    img = yuv(:,:,1);
end
% find sharpness from gradient
[Gx, Gy]= gradient(double(img));
sharpValue = sum(sum((Gx.*Gx+Gy.*Gy).*mask))/divider;