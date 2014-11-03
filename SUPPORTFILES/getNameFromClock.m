function namet = getNameFromClock

t = fix(clock);
namet = num2str(t(1));
for k = 2:6
    insertzero = '';
    if t(k)<10
        insertzero = '0';
    end
    namet = [namet, insertzero, num2str(t(k))];
    if k==3
        namet = [namet,'_'];
    end
end