addpath('./dtcwt/');
RGB = imread('tmp.png');
%RGB = imresize(RGB, 0.5);
hmindepthfactor = 0.05;
t1= 0.9;
t2= 0.7;
[overlay,intolay,map,intmap, gsurf] = runseg(RGB, t1,t2,hmindepthfactor,0,1);