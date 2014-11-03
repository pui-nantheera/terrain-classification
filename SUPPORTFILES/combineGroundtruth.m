% This code is to stitch region to make groundtruth
clear all

% input
dirName = 'C:\Locomotion\videos\walking 60 degree\groundtruth\MVI_0146_a\';

% class names
dirnameclass = {'hard surface', 'soft surface', 'unwalkable', 'segmentmap'};

% get filenames
for curdir = 1:length(dirnameclass)
    [namelist{curdir}, filenames{curdir}] = getAllfileNames([dirName,dirnameclass{curdir},'\']);
end

% find frame index
for classnum = 1:3
    listframe{classnum} = [];
    listarea{classnum} = [];
    for num = 1:length(filenames{classnum})
        curname = filenames{classnum}{num};
        apos = find(curname=='a');
        dotpos = find(curname=='.');
        fnum = str2num(curname(2:apos-1));
        anum = str2num(curname(apos+1:dotpos-1));
        listframe{classnum} = [listframe{classnum} fnum];
        listarea{classnum}  = [listarea{classnum} anum];
    end
end

% frame-by-frame
for framenum = 1:length( filenames{4})
    framenum
    % read segmap
    cursegmap = double(imread([dirName,'segmentmap\f',num2str(framenum),'.tif']));
    % groundtruth init
    gtImage = zeros(size(cursegmap));
    % for each region
    regInd = unique(cursegmap(:));
    regInd(regInd==0) = [];
    % find list of regions
    for classnum = 1:3
        inda{classnum} = listarea{classnum}(listframe{classnum} ==  framenum);
    end
    % for each region
    for regnum = regInd'
        mask = bwmorph(cursegmap==regnum,'open');
        areatype = 0;
        for classnum = 1:3
            % find such area
            if sum(inda{classnum}==regnum)>0
                areatype = classnum;
            end
        end
        gtImage(mask) = areatype;
    end
    gtImagefinal = zeros(size(cursegmap));
    for classnum = 1:3
        mask = imclose(gtImage==classnum,strel('disk',2));
        mask = imfill(mask,'holes');
        gtImagefinal(mask>0) = classnum;
    end
    % write groundtruth
    imwrite(uint8(gtImagefinal*100), [dirName,'gt',num2str(framenum),'.tif'], 'tif');
end