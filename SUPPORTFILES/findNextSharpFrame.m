function [nextsharpframe, freqstep, notsharp, addnumframe] = findNextSharpFrame(curFrameNum, startFrame, framerate, addnumframe, steppattern, ...
    avgSharp, prevSegFrame, mingapsharpframe, maxgapsharpframe, nextsharpframe, freqstep, notsharp, walkeffect, GOP)

if walkeffect
    if (curFrameNum > startFrame+0.25*framerate)&&((addnumframe(1)>3)||(steppattern(end)<avgSharp))
        if ((curFrameNum > (prevSegFrame+maxgapsharpframe))&&(steppattern(end)> avgSharp))||(curFrameNum > (prevSegFrame+1.5*maxgapsharpframe))
            nextsharpframe = curFrameNum-1;
            addnumframe = 1;
            notsharp = 0;
        else
            [freqstep, addnumframe] = findWalkingFreq(steppattern,framerate);
            nextsharpframe = curFrameNum + addnumframe;
            oknextsharp = (nextsharpframe > prevSegFrame+mingapsharpframe)&...
                ((nextsharpframe < prevSegFrame+maxgapsharpframe)|(curFrameNum > prevSegFrame+maxgapsharpframe));
            nextsharpframe(~oknextsharp) = [];
            if isempty(nextsharpframe)
                addnumframe = mingapsharpframe;
                nextsharpframe = curFrameNum + addnumframe - 1;
            else
                nextsharpframe = nextsharpframe(1);
            end
        end
    end
else
    if rem(curFrameNum,framerate)==1
        nextsharpframe = curFrameNum;
    end
end

% make sure that the next sharp frame will be in the GOP step
if GOP>1
    nextsharpframe = round(nextsharpframe/GOP)*GOP + rem(curFrameNum,GOP);
end