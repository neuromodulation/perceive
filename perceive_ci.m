function [channelindex,channelnames] = perceive_ci(channels,possible_list,exact)

if ~exist('exact','var')
    exact = 0;
end

if ischar(channels)
    channels = {channels};
end
x=[];


for a = 1:length(channels)
    for b  =1:length(possible_list)
        if ~exact
            nsearch = length(possible_list{b});
        elseif exact > 0
            nsearch = 1;    
        end
        for c =1:nsearch
            if exact ==1 
                x(a,b,c) = strcmpi(channels{a},possible_list{b}(c:end));
            else
                x(a,b,c) = strncmpi(channels{a},possible_list{b}(c:end),length(channels{a}));
            end
        end
    end
end
sx=sum(x,3);
i=[];
for a = 1:length(channels)
    index = find(sx(a,:));
            i = [i index];
        index = [];
end

channelnames = possible_list(i);
if numel(i) ~= numel(unique(i))
    warning('Duplicates found and erased')
    channelindex = unique(i,'stable');
else
    channelindex = i;
end

% display(channelnames);

