function [bestc, bestg] = gridSearch(Group, Training)

bestcv = 0; nextLoop = 1;
rangeLc = -3:3;
rangeLg = -3:3;
stepc = 1; stepg = 1;
pbestLc = -100; pbestLg = -100;
countL = 0;
while (nextLoop)&&(stepg>0.125)&&(countL<5)
    for log2c = rangeLc
        for log2g = rangeLg
            cmd = ['-t 2 -v 3 -c ', num2str(2^log2c), ' -g ', num2str(2^log2g)];
            cv = svmtrain(Group, Training, cmd);
            if (cv > bestcv),
                bestcv = cv; bestc = 2^log2c; bestg = 2^log2g;
                bestLc = log2c; bestLg = log2g;
            end
        end
    end
    if (bestcv>80)||(stepg==0.25)||((bestLc==pbestLc)&&(bestLg==pbestLg))
        nextLoop = 0;
    else
        nextLoop = 1;
        if (bestLc==rangeLc(1))&&(stepc==1)
            rangeLc = bestLc-2:bestLc+1;
        elseif (bestLc==rangeLc(end))&&(stepc==1)
            rangeLc = bestLc-1:bestLc+2;
        else
            stepc = stepc/2;
            rangeLc = bestLc-stepc*2:stepc:bestLc+stepc*2;
        end
        if (bestLg==rangeLg(1))&&(stepg==1)
            rangeLg = bestLg-2:bestLg+1;
        elseif (bestLc==rangeLg(end))&&(stepg==1)
            rangeLg = bestLg-1:bestLg+2;
        else
            stepg = stepg/2;
            rangeLg = bestLg-stepg*2:stepg:bestLg+stepg*2;
        end
    end
    pbestLc = bestLc; pbestLg = bestLg;
    countL = countL + 1;
end
