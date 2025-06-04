function perceive_export_bsl_csv(d)

% exports BrainSense BSL data (from one block) to a CSV file
%
% input:
%   d: FieldTrip-compatible struct from perceive_extract_bsl

T = table;
T.Time = d.realtime';

for c = 1:length(d.label)
    label = d.label{c};
    try
        T.(label) = d.trial{1}(c,:)';
    catch
        safeLabel = matlab.lang.makeValidName(label);
        T.(safeLabel) = d.trial{1}(c,:)';
    end
end

mod = 'mod-BrainsenseLFP';
csvname = fullfile(d.hdr.fpath, [d.fname '_' mod '.csv']);
writetable(T, csvname);
end
