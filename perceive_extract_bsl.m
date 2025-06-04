function [alldata, counterBSL] = perceive_extract_bsl(data, hdr)

% extracts BrainSense LFP data into FieldTrip-compatible structures
%
% inputs:
%   data: struct from BrainSenseLfp JSON
%   hdr: metadata header (subject, session, file path, etc.)
%
% outputs:
%   alldata: cell array of FieldTrip structs
%   counterBSL: number of BSL blocks extracted

alldata = {};
counterBSL = 0;

FirstPacketDateTime = strrep(strrep({data(:).FirstPacketDateTime},'T',' '),'Z','');
runs = unique(FirstPacketDateTime);

for c = 1:length(runs)
    cdata = data(c);
    tmp = strrep(cdata.Channel,'_AND','');
    tmp = strsplit(strrep(strrep(strrep(strrep(strrep(tmp,'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3'),'_',''),',');

    if length(tmp)==2
        lfpchannels = {[hdr.chan '_' tmp{1}(3) '_' tmp{1}(1:2)], ...
                       [hdr.chan '_' tmp{2}(3) '_' tmp{2}(1:2)]};
    elseif length(tmp)==1
        lfpchannels = {[hdr.chan '_' tmp{1}(3) '_' tmp{1}(1:2)]};
    else
        error('Unsupported number of channels in BrainSenseLfp: %d', length(tmp));
    end

    d = [];
    d.hdr = hdr;
    d.hdr.BSL.TherapySnapshot = cdata.TherapySnapshot;
    lfpsettings = cell(2,1);
    stimchannels = cell(2,1);
    acq_stimcontact = '';
    acq_freq = '';
    acq_pulse = '';

    % LEFT
    if isfield(d.hdr.BSL.TherapySnapshot, 'Left')
        tmp = d.hdr.BSL.TherapySnapshot.Left;
        lfpsettings{1} = sprintf('PEAK%dHz_THR%.1f-%.1f_AVG%dms', ...
            round(tmp.FrequencyInHertz), tmp.LowerLfpThreshold, ...
            tmp.UpperLfpThreshold, round(tmp.AveragingDurationInMilliSeconds));
        stimchannels{1} = sprintf('STIM_L_%dHz_%dus', tmp.RateInHertz, tmp.PulseWidthInMicroSecond);
        for el = 1:length(tmp.ElectrodeState)
            elstate = tmp.ElectrodeState{el};
            if isfield(elstate,'ElectrodeAmplitudeInMilliAmps') && elstate.ElectrodeAmplitudeInMilliAmps > 0.5
                acq_stimcontact = [acq_stimcontact , elstate.Electrode(end-1:end)];
            end
        end
        acq_freq = [num2str(tmp.RateInHertz) 'Hz'];
        acq_pulse = [num2str(tmp.PulseWidthInMicroSecond) 'us'];
    else
        lfpsettings{1} = 'LFP n/a';
        stimchannels{1} = 'STIM_L_n/a';
    end

    % RIGHT
    if isfield(d.hdr.BSL.TherapySnapshot, 'Right')
        tmp = d.hdr.BSL.TherapySnapshot.Right;
        lfpsettings{2} = sprintf('PEAK%dHz_THR%.1f-%.1f_AVG%dms', ...
            round(tmp.FrequencyInHertz), tmp.LowerLfpThreshold, ...
            tmp.UpperLfpThreshold, round(tmp.AveragingDurationInMilliSeconds));
        stimchannels{2} = sprintf('STIM_R_%dHz_%dus', tmp.RateInHertz, tmp.PulseWidthInMicroSecond);
        for el = 1:length(tmp.ElectrodeState)
            elstate = tmp.ElectrodeState{el};
            if isfield(elstate,'ElectrodeAmplitudeInMilliAmps') && elstate.ElectrodeAmplitudeInMilliAmps > 0.5
                acq_stimcontact = [acq_stimcontact , elstate.Electrode(end-1:end)];
            end
        end
        if isempty(acq_freq)
            acq_freq = [num2str(tmp.RateInHertz) 'Hz'];
            acq_pulse = [num2str(tmp.PulseWidthInMicroSecond) 'us'];
        end
    else
        lfpsettings{2} = 'LFP n/a';
        stimchannels{2} = 'STIM_R_n/a';
    end

    d.label = [strcat(lfpchannels','_',lfpsettings)' stimchannels'];
    d.hdr.label = d.label;

    d.fsample = cdata.SampleRateInHz;
    d.hdr.Fs = d.fsample;

    tstart = cdata.LfpData(1).TicksInMs / 1000;
    for e = 1:length(cdata.LfpData)
        d.trial{1}(1:2,e) = [cdata.LfpData(e).Left.LFP; cdata.LfpData(e).Right.LFP];
        d.trial{1}(3:4,e) = [cdata.LfpData(e).Left.mA; cdata.LfpData(e).Right.mA];
        d.time{1}(e) = seconds(datetime(runs{c},'InputFormat','yyyy-MM-dd HH:mm:ss.SSS') - hdr.d0) ...
                      + ((cdata.LfpData(e).TicksInMs/1000) - tstart);
        d.realtime(e) = datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS','Format','yyyy-MM-dd HH:mm:ss.SSS') ...
                      + seconds(d.time{1}(e) - d.time{1}(1));
        d.hdr.BSL.seq(e) = cdata.LfpData(e).Seq;
    end

    d.trialinfo(1) = c;
    d.hdr.realtime = d.realtime;

    counterBSL = counterBSL + 1;
    mod = 'mod-BSL';
    d.fname = [hdr.fname '_' mod];
    d.fname = strrep(d.fname, 'task-Rest', ['task-TASK' num2str(counterBSL)]);

    if contains(d.label{3}, 'STIM_L')
        LAmp = d.trial{1}(3,:);
    elseif contains(d.label{4}, 'STIM_L')
        LAmp = d.trial{1}(4,:);
    else
        LAmp = 0;
    end

    if contains(d.label{3}, 'STIM_R')
        RAmp = d.trial{1}(3,:);
    elseif contains(d.label{4}, 'STIM_R')
        RAmp = d.trial{1}(4,:);
    else
        RAmp = 0;
    end

    acq = check_stim(LAmp, RAmp, d.hdr);
    if ~strcmp(acq,'StimOff')
        acq = [acq, acq_stimcontact, acq_freq, acq_pulse];
    end
    assert(ischar(acq));

    d.fname = strrep(d.fname, 'StimOff', acq);
    d.fnamedate = char(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS','format','yyyyMMddhhmmss'));

    alldata{end+1} = d;
end
end

