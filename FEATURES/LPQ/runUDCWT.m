% run UDT-CWT
clear all

rootDir = 'C:\Locomotion\temp\LPQ\project LAVA\';
resizeRatio = 1;
addpath('C:\Locomotion\code_motion\DTCWT\UDTCWT\');
[Faf, ~] = NDAntonB2; %(Must use ND filters for both)
[af, ~] = NDdualfilt1;

for cnum = 23
    for k = 8
        imgname = ['T',sprintf('%02s',num2str(cnum)),'_',sprintf('%02s',num2str(k))];
        img = imread([rootDir,'images\',imgname,'.jpg']);
        if resizeRatio~=1
            img = imresize(img,resizeRatio);
        end
        for wlevels = [7]
            
            % find maximal decomposition level
            maxlevel = min(wlevels, floor(log2(min(size(img))/5)));
            % wavelet transform
            w = NDxWav2DMEX(double(img), maxlevel, Faf, af, 1);
            % if more levels are required
            if wlevels > maxlevel
                lowcoef = (w{maxlevel+1}{1}{1}+w{maxlevel+1}{1}{2}+w{maxlevel+1}{2}{1}+w{maxlevel+1}{2}{2});
                morelevels = wlevels - maxlevel;
                wmore = NDxWav2DMEX(double(lowcoef), morelevels, af, af, 1);
                for level = 1:morelevels+1
                    w{maxlevel+level} = wmore{level};
                end
            end
            save([rootDir,'images\resize',num2str(resizeRatio),'\',imgname,'w',num2str(wlevels),'.mat'],'w');
            
        end
    end
end