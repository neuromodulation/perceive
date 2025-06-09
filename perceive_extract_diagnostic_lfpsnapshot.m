function alldata_diag_lfpsnap = perceive_extract_diagnostic_lfpsnapshot(snapshotEvents, hdr)

% extract LFP Snapshot Events from DiagnosticData

% inputs:
%   snapshotEvents: struct from data.LfpFrequencySnapshotEvents
%   hdr: header info
%
% output:
%   alldata_diag_lfpsnap: cell array of diagnostic snapshot data

alldata_diag_lfpsnap = {};
Tpow = table;
chanlabels = {};
events = {};
DT = datetime.empty;
stimgroups = {};
hdr.fname = strrep(hdr.fname, 'StimOff', 'StimX');

% TODO: replace simple StimX replacement with code that overwrites from
% StimOff to StimOn based on actual stim settings. Probably needs to be done
% through the use of lfptrend data where current stim amp is saved (compare
% datetime of snapshot with that lfptrend, would need to be an input to
% this function) - could also be valuable to save the stimAmp

for idxSnap = 1:length(snapshotEvents)
    try
        lfp = snapshotEvents{idxSnap};
    catch
        lfp = snapshotEvents(idxSnap);
    end

    if ~lfp.LFP || ~isfield(lfp, 'LfpFrequencySnapshotEvents')
        warning('LFP Snapshot Event without LFP data present.')
        continue
    end

    DT(idxSnap) = datetime(lfp.DateTime(1:end-1), 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss');
    events{idxSnap} = lfp.EventName;

    % extract stimulation group if available
    if isfield(lfp.LfpFrequencySnapshotEvents, 'HemisphereLocationDef_Left')
        stimgroups{idxSnap} = lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Left.GroupId(end);
    elseif isfield(lfp.LfpFrequencySnapshotEvents, 'HemisphereLocationDef_Right')
        stimgroups{idxSnap} = lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Right.GroupId(end);
    else
        stimgroups{idxSnap} = 'unknown';
    end

    % left hemisphere
    if isfield(lfp.LfpFrequencySnapshotEvents, 'HemisphereLocationDef_Left')
        tmp = strsplit(strrep(lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Left.SenseID, '_AND', ''), '.');
        if isempty(tmp{1}) || isscalar(tmp)
            tmp = {'', 'unknown'};
        end
        ch1 = strcat(hdr.chan, '_L_', strrep(tmp{2}, '_', ''));
        freq = lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Left.Frequency;
    else
        ch1 = 'n/a';
    end

    % right hemisphere
    if isfield(lfp.LfpFrequencySnapshotEvents, 'HemisphereLocationDef_Right')
        tmp = strsplit(strrep(lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Right.SenseID, '_AND', ''), '.');
        if isempty(tmp{1}) || isscalar(tmp)
            tmp = {'', 'unknown'};
        end
        ch2 = strcat(hdr.chan, '_R_', strrep(tmp{2}, '_', ''));
        if ~exist('freq', 'var')  % use right freq if left isn't available
            freq = lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Right.Frequency;
        end
    else
        ch2 = 'n/a';
    end

    chanlabels{idxSnap} = {ch1, ch2};

    % power extraction
    if isfield(lfp.LfpFrequencySnapshotEvents, 'HemisphereLocationDef_Left') && ...
       isfield(lfp.LfpFrequencySnapshotEvents, 'HemisphereLocationDef_Right')
        pow(:, 1) = lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Left.FFTBinData;
        pow(:, 2) = lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Right.FFTBinData;
    elseif isfield(lfp.LfpFrequencySnapshotEvents, 'HemisphereLocationDef_Left')
        pow(:, 1) = lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Left.FFTBinData;
        pow(:, 2) = zeros(size(pow(:, 1)));
    elseif isfield(lfp.LfpFrequencySnapshotEvents, 'HemisphereLocationDef_Right')
        pow(:, 2) = lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Right.FFTBinData;
        pow(:, 1) = zeros(size(pow(:, 2)));
    else
        error('No valid FFTBinData found for left or right hemisphere.')
    end

    % save into table for export
    tag = strrep([events{idxSnap} '_' num2str(idxSnap) '_' ch1 '_' char(datetime(DT(idxSnap), 'Format', 'yyyyMMddHHmmss'))], ' ', '');
    Tpow.Frequency = freq;
    Tpow.([tag '_L']) = pow(:, 1);
    Tpow.([tag '_R']) = pow(:, 2);

    % store in d-struct for plotting function
    d = struct();
    d.hdr = hdr;
    d.label = {ch1, ch2};
    d.trial{1} = pow';
    d.time{1} = freq';
    d.datatype = 'DiagnosticData.LFPTrends';
    d.fsample = NaN;
    d.fname = [hdr.fname '_LFPSnapshot_' events{idxSnap} '-' num2str(idxSnap)];
    d.realtime{1} = DT(idxSnap);  % for plot title
    d.fnamedate = char(datetime(DT(idxSnap), 'Format', 'yyyyMMddHHmmss'));
    d.eventname = events{idxSnap};
    d.stimgroup = stimgroups{idxSnap};
    alldata_diag_lfpsnap{end+1} = d;
end

% export power table
writetable(Tpow, fullfile(hdr.fpath, [hdr.fname '_LFPSnapshotEvents.csv']));

end
