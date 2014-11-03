% create problem

totalClass = 25;
totalSamples = 40;

numTrainControl = totalSamples/2;

for prob = 1:50
    trainInd = zeros(totalClass,numTrainControl);
    testInd  = zeros(totalClass,totalSamples - numTrainControl);
    for numc = 1:totalClass
        inxControl = [];
        while length(inxControl)<numTrainControl
            moreind = numTrainControl - length(inxControl);
            temp = randi(totalSamples,1,numTrainControl);
            inxControl = unique([inxControl temp(1:min(length(temp),moreind))]);
        end
        trainInd(numc,:) = inxControl(1:numTrainControl);
        inxTest = 1:totalSamples;
        inxTest(inxControl(1:numTrainControl)) = [];
        testInd(numc,:) = inxTest;
    end
    dlmwrite(['C:\Locomotion\temp\LPQ\project LAVA\problem',num2str(prob),'train.txt'],trainInd);
    dlmwrite(['C:\Locomotion\temp\LPQ\project LAVA\problem',num2str(prob),'test.txt'],testInd);
end