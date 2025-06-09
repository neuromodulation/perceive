function alldata_lmtd = perceive_extract_lfp_montage_time_domain(data, hdr, config, idxDatafield)

% extraction of LfpMontageTimeDomain data into FieldTrip-like format
%
% inputs:
%   data - input data struct from Percept JSON
%   hdr - header struct with fields like hdr.d0, hdr.chan, hdr.fpath, etc.
%   config - configuration struct with optional field config.ecg_cleaning (logical)
%   idxDatafield - index indicating which data field this is in the full JSON
%
% output:
%   alldata_lmtd - cell array of structs per run

alldata_lmtd = {};
datafields = fieldnames(data);
FirstPacketDateTime = strrep(strrep({data(:).FirstPacketDateTime},'T',' '),'Z','');
runs = unique(FirstPacketDateTime);

% extract global sequence and packet size info
Pass = {data(:).Pass};
GlobalSequences = cellfun(@str2num, {data(:).GlobalSequences}, 'UniformOutput', false)';
GlobalPacketSizes = cellfun(@str2num, {data(:).GlobalPacketSizes}, 'UniformOutput', false)';

fsample = data(1).SampleRateInHz;

% channel formatting
rawChannels = {data(:).Channel}';
tmp1 = split(rawChannels, regexpPattern("(_AND_)|((?<!.*_.*)_(?!.*_AND_.*))"));
ch1 = regexprep(tmp1(:,1), {'ZERO','ONE','TWO','THREE'}, {'0','1','2','3'});
ch2 = regexprep(tmp1(:,2), {'ZERO','ONE','TWO','THREE'}, {'0','1','2','3'});
Channel = strcat(hdr.chan, '_', ch1, '_', ch2);

for idxRun = 1:length(runs)
    i = perceive_ci(runs{idxRun}, FirstPacketDateTime);
    d = struct();
    d.hdr = hdr;
    d.datatype = datafields{idxDatafield};
    d.hdr.IS.Pass = regexprep(strrep(unique(strtok(Pass(i), '_')), {'FIRST','SECOND'}, {'1','2'}), '_', '');
    d.hdr.IS.GlobalSequences = GlobalSequences(i,:);
    d.hdr.IS.GlobalPacketSizes = GlobalPacketSizes(i,:);
    d.hdr.IS.FirstPacketDateTime = runs{idxRun};

    d.trial{1} = [data(i).TimeDomainData]';
    d.label = Channel(i);
    d.hdr.label = d.label;
    d.fsample = fsample;
    d.hdr.Fs = fsample;

    % time alignment
    startTime = datetime(runs{idxRun}, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
    d.time{1} = linspace(seconds(startTime - hdr.d0), ...
                         seconds(startTime - hdr.d0) + size(d.trial{1},2)/fsample, ...
                         size(d.trial{1},2));
    d.realtime = startTime + seconds(d.time{1} - d.time{1}(1));

    % sample info
    firstsample = set_firstsample(data(i(1)).TicksInMses);
    lastsample = firstsample + size(d.trial{1},2);
    % d.sampleinfo = [firstsample lastsample];  % Uncomment if needed

    d.trialinfo(1) = idxRun;
    mod = 'mod-LMTD';
    d.fname = [hdr.fname '_' mod];
    d.fnamedate = [char(datetime(runs{idxRun}, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'Format', 'yyyyMMddHHmmss')), '_', num2str(idxRun)];

    % optional ECG cleaning
    if isfield(config, 'ecg_cleaning') && config.ecg_cleaning
        d = call_ecg_cleaning(d, hdr, d.trial{1});
    end

    alldata_lmtd{end+1} = d;
end

end
