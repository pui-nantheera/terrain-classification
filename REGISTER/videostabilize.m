%%% STABILIZE VIDEO
function[ motion, stable ] = videostabilize( frames, roi, L )

% Hany Farid and Jeffrey B. Woodward, "Video stabilization & Enhancement” TR2007- 605, 
% Technical Report, TR2007-605, Dartmouth College, Computer Science, 2007.

N = length( frames );
roiorig = roi;
%%% ESTIMATE PAIRWISE MOTION
Acum = [1 0 ; 0 1];
Tcum = [0 ; 0];
stable(1).roi = roiorig;
for k = 1 : N-1
    [A,T] = opticalflow( frames(k+1).im, frames(k).im, roi, L );
    motion(k).A = A;
    motion(k).T = T;
    [Acum,Tcum] = accumulatewarp( Acum, Tcum, A, T );
    roi = warp( roiorig, Acum, Tcum );
end
%%% STABILIZE TO LAST FRAME
stable(N).im = frames(N).im;
Acum = [1 0 ; 0 1];
Tcum = [0 ; 0];
for k = N-1 : -1 : 1
    [Acum,Tcum] = accumulatewarp( Acum, Tcum, motion(k).A, motion(k).T );
    stable(k).im = warp( frames(k).im, Acum, Tcum );
end