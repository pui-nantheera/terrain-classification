function [x_pos, y_pos] = selectPoint(avgFrame,numberPoints,titleMessage, markersize)

if nargin < 4
    markersize = 5;
end
if max(avgFrame(:))<=10
    avgFrame = avgFrame*255;
end
h = figure; imshow(uint8(avgFrame)); title(titleMessage);
hold on
x_pos = zeros(1,numberPoints);
y_pos = zeros(1,numberPoints);
for k = 1:numberPoints
    [x_pos(k), y_pos(k)] = ginput(1);
    plot(x_pos(k),y_pos(k),'+','color','r','MarkerSize',markersize);
end
close(h)