function [farRangei,farRangej,template6rg, htemplate, wtemplate] = getDefaultPosition(height,width)

% specified regions here
farRangei = 1:round(2/6*height);
farRangej = round(1/5*width):round(4/5*width);

htemplate = length(farRangei);
wtemplate = length(farRangej);
template6rg = ones(htemplate,wtemplate);
template6rg(round(1:htemplate/2),:) = 2;
template6rg(:,round(wtemplate/3:wtemplate)) = template6rg(:,round(wtemplate/3:wtemplate))+2;
template6rg(:,round(2*wtemplate/3+1:wtemplate)) = template6rg(:,round(2*wtemplate/3+1:wtemplate))+2;