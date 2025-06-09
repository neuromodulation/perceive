function alldata_diagnostic_lfp = perceive_extract_diagnostic_lfptrend(data, hdr)

% extracts DiagnosticData.LFPTrendLogs into FieldTrip-like structs
% also saves a combined CSV file if both hemispheres are present

alldata_diagnostic_lfp = {};
modLeft = 'mod-ChronicLeft';
modRight = 'mod-ChronicRight';
modCombined = 'mod-Chronic';

LFPL = []; STIML = []; DTL = datetime([],[],[]);
LFPR = []; STIMR = []; DTR = datetime([],[],[]);

hdr.fname = strrep(hdr.fname,'StimOff','StimX');
hdr.fname = strrep(hdr.fname, 'task-Rest', 'task-None');

% extract LEFT
if isfield(data.LFPTrendLogs,'HemisphereLocationDef_Left')
    data.left = data.LFPTrendLogs.HemisphereLocationDef_Left;
    runs = fieldnames(data.left);
    for c = 1:length(runs)
        clfp = [data.left.(runs{c}).LFP];
        cstim = [data.left.(runs{c}).AmplitudeInMilliAmps];
        cdt = datetime({data.left.(runs{c}).DateTime}, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss''Z''');
        [cdt, i] = sort(cdt);
        LFPL = [LFPL, clfp(i)];
        STIML = [STIML, cstim(i)];
        DTL = [DTL, cdt];

        d = struct();
        d.hdr = hdr;
        d.datatype = 'DiagnosticData.LFPTrends';
        d.label = {'LFP_LEFT','STIM_LEFT'};
        d.trial{1} = [clfp(i); cstim(i)];
        d.time{1} = linspace(seconds(cdt(1) - hdr.d0), seconds(cdt(end) - hdr.d0), size(d.trial{1},2));
        d.realtime{1} = cdt;

        if length(d.time{1}) > 1
            d.fsample = abs(1/diff(d.time{1}(1:2)));
        else
            d.fsample = 1/600;
        end

        d.hdr.Fs = d.fsample;
        d.hdr.label = d.label;
        d.sampleinfo = [d.time{1}(1), d.time{1}(end)];
        d.fname = [hdr.fname '_' modLeft];
        d.fnamedate = char(datetime(cdt(1),'Format','yyyyMMddHHmmss'));
        d.keepfig = false;

        alldata_diagnostic_lfp{end+1} = d;
    end
end

% extract RIGHT
if isfield(data.LFPTrendLogs,'HemisphereLocationDef_Right')
    data.right = data.LFPTrendLogs.HemisphereLocationDef_Right;
    runs = fieldnames(data.right);
    for c = 1:length(runs)
        clfp = [data.right.(runs{c}).LFP];
        cstim = [data.right.(runs{c}).AmplitudeInMilliAmps];
        cdt = datetime({data.right.(runs{c}).DateTime}, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss''Z''');
        [cdt, i] = sort(cdt);
        LFPR = [LFPR, clfp(i)];
        STIMR = [STIMR, cstim(i)];
        DTR = [DTR, cdt];

        d = struct();
        d.hdr = hdr;
        d.datatype = 'DiagnosticData.LFPTrends';
        d.label = {'LFP_RIGHT','STIM_RIGHT'};
        d.trial{1} = [clfp(i); cstim(i)];
        d.time{1} = linspace(seconds(cdt(1) - hdr.d0), seconds(cdt(end) - hdr.d0), size(d.trial{1},2));
        d.realtime{1} = cdt;

        if length(d.time{1}) > 1
            d.fsample = abs(1/diff(d.time{1}(1:2)));
        else
            d.fsample = 1/600;
        end

        d.hdr.Fs = d.fsample;
        d.hdr.label = d.label;
        d.sampleinfo = [d.time{1}(1), d.time{1}(end)];
        d.fname = [hdr.fname '_' modRight];
        d.fnamedate = char(datetime(cdt(1),'Format','yyyyMMddHHmmss'));
        d.keepfig = false;

        alldata_diagnostic_lfp{end+1} = d;
    end
end

% combined matrix
LFP = []; STIM = [];
if isempty(DTL)
    DT = sort(DTR);
elseif isempty(DTR)
    DT = sort(DTL);
else
    DT = sort([DTL, setdiff(DTR, DTL)]);
end

for c = 1:length(DT)
    if ismember(DT(c), DTL)
        i = find(DTL == DT(c), 1, 'first');
        LFP(1,c) = LFPL(i);
        STIM(1,c) = STIML(i);
    else
        LFP(1,c) = nan;
        STIM(1,c) = nan;
    end
    if ismember(DT(c), DTR)
        i = find(DTR == DT(c), 1, 'first');
        LFP(2,c) = LFPR(i);
        STIM(2,c) = STIMR(i);
    else
        LFP(2,c) = nan;
        STIM(2,c) = nan;
    end
end

d = struct();
d.hdr = hdr;
d.datatype = 'DiagnosticData.LFPTrends';
d.label = {'LFP_LEFT','LFP_RIGHT','STIM_LEFT','STIM_RIGHT'};
d.trial{1} = [LFP; STIM];
d.time{1} = DT;
if numel(DT) > 1
    d.fsample = 1 / seconds(mean(diff(DT)));
else
    d.fsample = 1/600; % approximation if only one datapoint
end

d.sampleinfo = [d.time{1}(1), d.time{1}(end)];
d.fname = [hdr.fname '_' modCombined];
d.fnamedate = char(datetime(DT(1),'Format','yyyyMMddHHmmss'));
alldata_diagnostic_lfp{end+1} = d;

% save CSV
T = table;
T.Time = d.time{1}';
T.LFP_LEFT = d.trial{1}(1,:)';
T.LFP_RIGHT = d.trial{1}(2,:)';
T.STIM_LEFT = d.trial{1}(3,:)';
T.STIM_RIGHT = d.trial{1}(4,:)';
writetable(T, fullfile(hdr.fpath, [hdr.fname '_CHRONIC.csv']));

end
