function alldata_ct = perceive_extract_calibrationtests(data, hdr, plotfields)

% perceive_extract_calibrationtests
% Extracts calibration test runs from Perceive data and returns them as
% FieldTrip-like data structures in a cell array alldata_ct.

alldata_ct = {};

%% --- Parse timestamps and metadata ---
FirstPacketDateTime = strrep(strrep({data(:).FirstPacketDateTime}, 'T', ' '), 'Z', '');
runs = unique(FirstPacketDateTime);

Pass = {data(:).Pass};

% GlobalSequences
tmp = {data(:).GlobalSequences};
GlobalSequences = cell(length(tmp),1);
for c = 1:length(tmp)
    GlobalSequences{c} = str2num(tmp{c}); %#ok<ST2NM>
end

% GlobalPacketSizes
tmp = {data(:).GlobalPacketSizes};
GlobalPacketSizes = cell(length(tmp),1);
for c = 1:length(tmp)
    GlobalPacketSizes{c} = str2num(tmp{c}); %#ok<ST2NM>
end

%% --- Parse channel names ---
Channel = strings(1,length(data));
for c = 1:length(data)
    % Parse channel name
    [tmp1,tmp2] = strtok(strrep({data(c).Channel}','_AND',''),'_');
    ch1 = strrep(strrep(strrep(strrep(tmp1,'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3');
    [tmp1,tmp2] = strtok(tmp2,'_');
    ch2 = strrep(strrep(strrep(strrep(tmp1,'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3');
    side = strrep(strrep(strtok(tmp2,'_'),'LEFT','L'),'RIGHT','R');
    Channel(c) = strcat(hdr.chan,'_',side,'_', ch1, ch2);
end

%% --- Plot all calibration tests ---
if any(strcmp(plotfields, 'CalibrationTests'))
    figure
    defaultBlue = [0 0.4470 0.7410]; % MATLAB default blue
    for c = 1:length(data)
        fsample = data(c).SampleRateInHz;
        tdtmp = zscore(data(c).TimeDomainData)./10 + c;
        ttmp = (1:length(tdtmp)) ./ fsample;
        plot(ttmp, tdtmp, 'Color', defaultBlue)
        hold on
    end
    xlim([ttmp(1), ttmp(end)])
    set(gca,'YTick',1:c,'YTickLabel',strrep(Channel,'_',' '),'YTickLabelRotation',45)
    xlabel('Time [s]')
    title(strrep({hdr.subject, hdr.session, 'All CalibrationTests'}, '_', ' '))
    perceive_print(fullfile(hdr.fpath, [hdr.fname '_mod-CalibrationTests']))
end


%% --- Build output structures per run ---
for c = 1:length(runs)

    i = perceive_ci(runs{c}, FirstPacketDateTime);

    raw = [data(i).TimeDomainData]';

    d = [];
    d.hdr = hdr;
    d.datatype = 'CalibrationTests';

    % Calibration test metadata
    d.hdr.CT.Pass = strrep(strrep(unique(strtok(Pass(i),'_')), 'FIRST','1'), 'SECOND','2');
    d.hdr.CT.GlobalSequences = GlobalSequences(i,:);
    d.hdr.CT.GlobalPacketSizes = GlobalPacketSizes(i,:);
    d.hdr.CT.FirstPacketDateTime = runs{c};

    % Channels
    d.label = Channel(i);

    % Trial
    d.trial{1} = raw;

    % Time axis
    % OLD
    % t0 = seconds(datetime(runs{c}, 'Inputformat','yyyy-MM-dd HH:mm:ss.SSS') - hdr.d0);

    % NEW
    t0 = seconds(timeofday(datetime(runs{c}, 'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')));
    
    d.time{1} = linspace(t0, t0 + size(d.trial{1},2)/fsample, size(d.trial{1},2));

    d.fsample = fsample;

    % Sampleinfo
    firstsample = set_firstsample(data(i(1)).TicksInMses);
    lastsample = firstsample + size(d.trial{1},2);
    d.sampleinfo(1,:) = [firstsample lastsample];

    d.trialinfo(1) = c;
    d.hdr.label = d.label;
    d.hdr.Fs = d.fsample;

    % Filename
    d.fname = [hdr.fname '_mod-CalibrationTests' ...
               char(datetime(runs{c}, 'Inputformat','yyyy-MM-dd HH:mm:ss.SSS', ...
               'format','yyyyMMddhhmmss'))];

    % Append
    alldata_ct{end+1} = d;
end

end
