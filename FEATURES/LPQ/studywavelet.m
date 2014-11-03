img = zeros(128,128);
img(:,65:128) = 255;

h = fspecial('gaussian', [15 15], 1);
imgblur = imfilter(img,h, 'replicate');

% fourier transform
H = fft2(h,128,128);
absH = abs(H);
angleH = angle(H);
Img = fft2(img);
absImg = abs(Img);
angleImg = angle(Img);

% imgblur = ifft2(H.*Img);
ImgBlur = fft2(imgblur);
absImgBlur = abs(ImgBlur);
angleImgBlur = angle(ImgBlur);

% wavelet transform
wlevels = 4;
[Faf, Fsf] = NDAntonB2; %(Must use ND filters for both)
[af, sf] = NDdualfilt1;
w = NDxWav2DMEX(double(img), wlevels, Faf, af, 1);
for level = 1:wlevels
    highcoef{level} = [];
    for c = 1:2
        for d = 1:3
            highcoef{level} = cat(3,highcoef{level},w{level}{1}{c}{d} + 1i*w{level}{2}{c}{d});
        end
    end
end
lowcoef = 0.25*(w{wlevels+1}{1}{1}+w{wlevels+1}{1}{2}+w{wlevels+1}{2}{1}+w{wlevels+1}{2}{2});

w = NDxWav2DMEX(double(imgblur), wlevels, Faf, af, 1);
for level = 1:wlevels
    highcoefb{level} = [];
    for c = 1:2
        for d = 1:3
            highcoefb{level} = cat(3,highcoefb{level},w{level}{1}{c}{d} + 1i*w{level}{2}{c}{d});
        end
    end
end
lowcoefb = 0.25*(w{wlevels+1}{1}{1}+w{wlevels+1}{1}{2}+w{wlevels+1}{2}{1}+w{wlevels+1}{2}{2});

for level = 2:wlevels
    if level == 2
        angleall1 = 180/pi*angle( [highcoef{level}(66,:,1)]');
        angleall2 = 180/pi*angle( [highcoefb{level}(66,:,1)]');
        angleall1(1:59,:) = angleall1(1:59,:) - 360;
        angleall1(67:end,:) = angleall1(67:end,:) + 360;
        angleall2(1:58,:) = angleall2(1:58,:) - 360;
        angleall2(67:end,:) = angleall2(67:end,:) + 360;
        angleall =  [angleall1 angleall2];
        figure; plot( [angleall1 angleall2]); title(['angle of level ',num2str(level)]);
    elseif level == 1
        angleall1 = 180/pi*angle( [highcoef{level}(66,:,1)]');
        angleall2 = 180/pi*angle( [highcoefb{level}(66,:,1)]');
        angleall1(1:42,:) = angleall1(1:42,:) - 360;
        angleall1(71:end,:) = angleall1(71:end,:) + 360;
        angleall2(1:42,:) = angleall2(1:42,:) - 360;
        angleall2(71:end,:) = angleall2(71:end,:) + 360;
        angleall =  [angleall1 angleall2];
    end
    
    
    figure; 
    x = -64:63;
    y1 = abs( [highcoef{level}(66,:,1); highcoefb{level}(66,:,1)]');
    y2 = angleall;
    [AX,H1,H2] = plotyy(x,y1,x,y2,'plot');
    set(get(AX(1),'Ylabel'),'String','Magitudes') 
    set(get(AX(2),'Ylabel'),'String','Phase (degree)')
    legend('|w|','|w\_blur|','\angle w','\angle w\_blur');
    
    figure; plot(-64:63, [angleall abs( [highcoef{level}(66,:,1); highcoefb{level}(66,:,1)]')]); title(['angle of level ',num2str(level)]);
    figure; plot(-64:63, ); title(['angle of level ',num2str(level)]);
%     figure; plot(-64:63, real( [highcoef{level}(66,:,1); highcoefb{level}(66,:,1)]')); title(['angle of level ',num2str(level)]);
%     figure; plot(-64:63, real( [highcoef{level}(66,:,3); highcoefb{level}(66,:,3)]')); title(['angle of level ',num2str(level)]);
%      figure; plot(-64:63, 180/pi*angle( [highcoef{level}(66,:,3); highcoefb{level}(66,:,3)]')); title(['angle of level ',num2str(level)]);
end