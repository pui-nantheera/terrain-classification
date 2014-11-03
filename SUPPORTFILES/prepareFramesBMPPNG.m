clear

% input frames
maindir = 'C:\Locomotion\videos\walking 60 degree\MVI_0146_b\';

% read filenames from mplayer
pngfiles = dir([maindir,'*.png']);

% read filenames from MATLAB coder
bmpfiles = dir([maindir,'MATLAB\*.bmp']);

totalframe = length(bmpfiles);
curnum = 1;
replacebmp = [];
replacepng = [];
while curnum < totalframe
    curnum
    % read current frame
    frame1 = im2double(imread([maindir,'MATLAB\',bmpfiles(curnum).name]));
    
    % find number of shift frames between MATLAB and FFmpeg
    if curnum == 1
        n = 1;
        diffval = 0;
        while diffval < 1/256
            frame2 = im2double(imread([maindir,'MATLAB\',bmpfiles(curnum+n).name]));
            diffval = mean(abs(frame1(:)-frame2(:)));
            n = n + 1;
        end
        shiftnum = n - 1;
        curnum = n;
    else
        frame2 = im2double(imread([maindir,'MATLAB\',bmpfiles(curnum+1).name]));
        if mean(abs(frame1(:)-frame2(:))) < 1/256
            curpng = im2double(imread([maindir,pngfiles(curnum-shiftnum+1).name]));
            % copy png to bmp
            imwrite(curpng, [maindir,'MATLAB\',bmpfiles(curnum).name], 'bmp');
            replacebmp = [replacebmp curnum];
            replacepng = [replacepng (curnum-shiftnum+1)];
        end
        curnum  = curnum + 1;
    end
end