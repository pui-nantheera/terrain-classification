function [walkingfreq, nextsharpframe] = findWalkingFreq(steppattern,framerate)

steppattern = smooth(steppattern); % remove noise by averaging
Fs = framerate;                 % Sampling frequency
T = 1/Fs;                       % Sample time
L = length(steppattern);        % Length of signal
t = (0:L-1)*T;                  % Time vector
NFFT = 2^nextpow2(L);           % Next power of 2 from length of steppattern
Y = fft(steppattern,NFFT)/L;
f = (Fs/2*linspace(0,1,NFFT/2+1));
% convert to frame frequecy
framestep = Fs./f;
fftmag = 2*abs(Y(1:NFFT/2+1));
fftmag = fftmag(framestep<Fs*2);
freqrange = f(framestep<Fs*2);
framestep = framestep(framestep<Fs*2);
% find high magnitude
[~, ind] = sort(fftmag, 'descend');
freqrangesort = round(framestep(ind));
% first three possible walking/step frequency (frames/step)
walkingfreq = freqrangesort(1:min(3,length(freqrangesort)));

% predict next sharpest frame
sharprec = zeros(1,walkingfreq(1)); 

for k = 1:walkingfreq(1)
    sharprec(k) = median(steppattern(k:walkingfreq(1):end));
end
% rank sharpest
[~, indk] = sort(sharprec(~isnan(sharprec)), 'descend');
nextsharpframe = ones(1,length(indk));
for k = 1:length(indk)
    sharppattern = indk(k):walkingfreq(1):length(steppattern);
    nextsharpframe(k) = sharppattern(end) + walkingfreq(1) - length(steppattern);
end



