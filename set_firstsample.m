function firstsample = set_firstsample(string_of_TicksInMses)

    parts = strsplit(string_of_TicksInMses, ',');

    % extract the first part and convert it to a number, divide by 50ms

    firstsample = str2num(parts{1})/50;
    
    if isempty(firstsample)
        firstsample=1;
    end

end