function alldata_bstd = perceive_extract_bstd(data, hdr, config)

% extracts BrainSense Time Domain (BSTD) data into FieldTrip-compatible structures
% 
% inputs:
%   data: struct from BrainSenseTimeDomain JSON
%   hdr: metadata header (subject, session, file path, etc.)
%   config: configuration options (e.g. enable ECG cleaning)
%
% outputs:
%   alldata_bstd: cell array of FieldTrip structs, one per BSTD run
%
% description:
%   Parses each BSTD recording run, reconstructs time vectors using TicksInMses and 
%   GlobalPacketSizes, builds FieldTrip-compatible trial structs (`d`) with appropriate 
%   sampleinfo, labels, timestamps, and metadata. Handles stimulation metadata and 
%   optional ECG cleaning (via `call_ecg_cleaning`). Each output `d` is added to `alldata_bstd`.
%
% notes:
%   - Assumes 'runs' are grouped by unique FirstPacketDateTime.
%   - Time is reconstructed relative to hdr.d0 (session reference datetime).


mod = 'mod-BSTD';
fsample = data.SampleRateInHz;
FirstPacketDateTime = strrep(strrep({data(:).FirstPacketDateTime}, 'T', ' '), 'Z', '');
runs = unique(FirstPacketDateTime);
Pass = {data(:).Pass};
GlobalSequences = cell(size(data));
GlobalPacketSizes = cell(size(data));
TicksInS = cell(size(data));
time_real = cell(size(data));
alldata_bstd = {};

% parse meta fields
for idxData = 1:length(data)
    GlobalSequences{idxData} = str2num(data(idxData).GlobalSequences); %#ok<ST2NM>
    TicksInMs = str2num(data(idxData).TicksInMses); %#ok<ST2NM>
    TicksInS{idxData} = (TicksInMs - TicksInMs(1)) / 1000;
    GlobalPacketSizes{idxData} = str2num(data(idxData).GlobalPacketSizes); %#ok<ST2NM>
    time_real{idxData} = TicksInS{idxData}(1):1/fsample:TicksInS{idxData}(end) + (GlobalPacketSizes{idxData}(end) - 1)/fsample;
    time_real{idxData} = round(time_real{idxData}, 3);
end

% parse channel info
[tmp1, tmp2] = strtok(strrep({data(:).Channel}', '_AND', ''), '_');
ch1 = regexprep(tmp1, {'ZERO', 'ONE', 'TWO', 'THREE'}, {'0', '1', '2', '3'});
[tmp1, tmp2] = strtok(tmp2, '_');
ch2 = regexprep(tmp1, {'ZERO', 'ONE', 'TWO', 'THREE'}, {'0', '1', '2', '3'});
side = strrep(strrep(strtok(tmp2, '_'), 'LEFT', 'L'), 'RIGHT', 'R');
Channel = strcat(hdr.chan, '_', side, '_', ch1, ch2);

% parse per-run
for idxRun = 1:length(runs)
    i = perceive_ci(runs{idxRun}, FirstPacketDateTime);
    raw1 = [data(i).TimeDomainData]';

    d = struct();
    d.hdr = hdr;
    d.datatype = 'BrainSenseTimeDomain';
    d.hdr.CT.Pass = strrep(strrep(unique(strtok(Pass(i), '_')), 'FIRST', '1'), 'SECOND', '2');
    d.hdr.CT.GlobalSequences = GlobalSequences(i);
    d.hdr.CT.GlobalPacketSizes = GlobalPacketSizes(i);
    d.hdr.CT.FirstPacketDateTime = runs{idxRun};
    d.label = Channel(i);
    d.trial{1} = raw1;
    d.fsample = fsample;

    t0 = datetime(runs{idxRun}, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
    rel_start = seconds(t0 - hdr.d0);
    d.time{1} = linspace(rel_start, rel_start + size(d.trial{1}, 2)/fsample, size(d.trial{1}, 2));
    d.time_real = time_real{i(1)};
    
    d.hdr.Fs = d.fsample;
    d.hdr.label = d.label;

    firstsample = set_firstsample(data(i(1)).TicksInMses);
    lastsample = firstsample + size(d.trial{1}, 2) - 1;
    d.sampleinfo(1, :) = [firstsample, lastsample];

    d.BrainSenseDateTime = [t0, t0 + seconds(size(d.trial{1}, 2)/fsample)];
    d.trialinfo(1) = idxRun;

    d.fname = [hdr.fname '_' mod];
    d.fnamedate = char(datetime(runs{idxRun}, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'Format', 'yyyyMMddHHmmss'));

    % Optional ECG cleaning
    if isfield(config, 'ecg_cleaning') && config.ecg_cleaning
        d = call_ecg_cleaning(d, hdr, raw1);
    end

    alldata_bstd{end+1} = d;
end

end
