function numpix = readNumberPix

% read number images
storedir = 'C:\Locomotion\code_motion\SUPPORTFILES\numberpix\';
numbername = dir([storedir,'number*.png']);

for k = 1:length(numbername)
    numpix{k} = im2double(imread([storedir, numbername(k).name]));
end