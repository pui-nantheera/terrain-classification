function imagefile = isimage(filename)

% read extension
extName = filename(end-2:end);

imagefile = false;
% compare to all image file type
if strcmpi(extName,'png')||strcmpi(extName,'bmp')||strcmpi(extName,'tif')||strcmpi(extName,'gif')||...
        strcmpi(extName,'cur')||strcmpi(extName,'ico')||strcmpi(extName,'jp2')||strcmpi(extName,'iff')||...
        strcmpi(extName,'ppm')||strcmpi(extName,'ras')||strcmpi(extName,'pgm')||strcmpi(extName,'pbm')||...
        strcmpi(extName,'xwd')
    imagefile = true;
end