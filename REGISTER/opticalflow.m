%%% ALIGN TWO FRAMES (f2 to f1)
function[ Acum, Tcum, f2 ] = opticalflow( f1, f2, roi, L )
f2orig = f2;
Acum = [1 0 ; 0 1];
Tcum = [0 ; 0];
for k = L : -1 : 0
    %%% DOWN-SAMPLE
    f1d = down( f1, k );
    f2d = down( f2, k );
    ROI = down( roi, k );
    %%% COMPUTE MOTION
    [Fx,Fy,Ft] = spacetimederiv( f1d, f2d );
    [A,T] = computemotion( Fx, Fy, Ft, ROI );
    T = (2^k) * T;
    [Acum,Tcum] = accumulatewarp( Acum, Tcum, A, T );
    %%% WARP ACCORDING TO ESTIMATED MOTION
    f2 = warp( f2orig, Acum, Tcum );
end