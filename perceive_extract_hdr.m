function [hdr, datafields] = perceive_extract_hdr(js, filename, config)

% extract metadata and filenames from a Percept JSON struct and user config

arguments
    js struct
    filename char
    config struct
end

% ----------------------------
% parse top-level info
% ----------------------------
[~, fname, ~] = fileparts(filename);
hdr.OriginalFile = filename;
hdr.fname = fname;
hdr.js = js;

% infofields to copy over if present
infofields = {'SessionDate','SessionEndDate','PatientInformation','DeviceInformation','BatteryInformation', ...
              'LeadConfiguration','Stimulation','Groups','Impedance','PatientEvents','EventSummary','DiagnosticData'};
for i = 1:length(infofields)
    if isfield(js, infofields{i})
        hdr.(infofields{i}) = js.(infofields{i});
    end
end

% fix datetime formats
hdr.SessionDate = datetime(strrep(js.SessionDate(1:end-1),'T',' '));
hdr.SessionEndDate = datetime(strrep(js.SessionEndDate(1:end-1),'T',' '));

% diagnosis
if isfield(js.PatientInformation, "Final") && ~isempty(js.PatientInformation.Final.Diagnosis)
    parts = strsplit(js.PatientInformation.Final.Diagnosis, '.');
    if numel(parts) > 1
        hdr.Diagnosis = parts{2};
    else
        hdr.Diagnosis = '';
    end
else
    hdr.Diagnosis = '';
end

% implant date
hdr.ImplantDate = strrep(strrep(js.DeviceInformation.Final.ImplantDate(1:end-1), 'T', '_'), ':', '-');

% battery %
if isfield(js, 'BatteryInformation')
    hdr.BatteryPercentage = js.BatteryInformation.BatteryPercentage;
else
    hdr.BatteryPercentage = NaN;
end

% lead Location
if isfield(hdr, 'LeadConfiguration')
    loc = hdr.LeadConfiguration.Final(1).LeadLocation;
    hdr.LeadLocation = strsplit(loc, '.');
    hdr.LeadLocation = hdr.LeadLocation{end};
else
    hdr.LeadLocation = 'UNK';
end

% ----------------------------
% subject handling
% ----------------------------
if isempty(config.subject)
    % generate subject from ImplantDate, Diagnosis, LeadLocation
    if ~isempty(hdr.ImplantDate) && ~isnan(str2double(hdr.ImplantDate(1)))
        hdr.subject = ['sub-' strrep(strtok(hdr.ImplantDate,'_'),'-','') hdr.Diagnosis(1) hdr.LeadLocation];
    else
        hdr.subject = ['sub-000' hdr.Diagnosis(1) hdr.LeadLocation];
    end
else
    hdr.subject = config.subject;
end

% ----------------------------
% session handling
% ----------------------------
if isempty(config.session)
    hdr.session = ['ses-' datestr(hdr.SessionEndDate, 'yyyymmddHHMM') num2str(hdr.BatteryPercentage)];
else
    % compute follow-up time if needed
    if isfield(config.localsettings, 'followup')
        diffmonths = config.localsettings.followup{1}(3:end-1);
    else
        d_implant = datetime(strrep(strtok(hdr.ImplantDate,'_'),'-',''), 'InputFormat','yyyyMMdd');
        d_session = hdr.SessionEndDate;
        % rawmonths = between(d_implant, d_session, 'months');
        presetmonths = [0,1,2,3,6,12,18,24,30,36,42,48,60,72,84,96,108,120]; % check this!!! --> different for different diagnoses
        % diffmonths = interp1(presetmonths, presetmonths, rawmonths, 'nearest');
        diffmonths = calmonths(between(d_implant, d_session));
        diffmonths = interp1(presetmonths, presetmonths, diffmonths, 'nearest');

        diffmonths = num2str(diffmonths);
    end
    hdr.session = ['ses-Fu' pad(diffmonths,2,'left','0') 'm' config.session];
end

% ----------------------------
% output directory and file label
% ----------------------------
hdr.fpath = fullfile(hdr.subject, hdr.session, 'ieeg');
if ~exist(hdr.fpath, 'dir')
    mkdir(hdr.fpath);
end

hdr.task = config.task;
hdr.acq = config.acq;
hdr.mod = config.mod;
hdr.run = config.run;

hdr.fname = sprintf('%s_%s_task-%s_acq-%s', ...
    hdr.subject, hdr.session, hdr.task, hdr.acq);

% run not included in old code, maybe change later to default run 0
% hdr.fname = sprintf('%s_%s_task-%s_acq-%s_run-%d', ...
%     hdr.subject, hdr.session, hdr.task, hdr.acq, hdr.run);

% channel label
hdr.chan = ['LFP_' hdr.LeadLocation];

% abnormal end check
if isfield(js, 'AbnormalEnd') && js.AbnormalEnd
    warning('This recording had an abnormal end');
    hdr.d0 = datetime(js.DeviceInformation.Final.DeviceDateTime(1:10));
else
    hdr.d0 = datetime(js.SessionEndDate(1:10));
end

% ----------------------------
% version check
% ----------------------------
if isfield(js, 'DataVersion')
    assert(strcmp(js.DataVersion, '1.2'), 'Only DataVersion 1.2 supported');
    hdr.DataVersion = 1.2;
else
    hdr.DataVersion = 0;
end

% ----------------------------
% default datafields if missing
% ----------------------------
if isempty(config.datafields)
    datafields = sort({'EventSummary','Impedance','MostRecentInSessionSignalCheck','BrainSenseLfp','BrainSenseTimeDomain', ...
        'LfpMontageTimeDomain','IndefiniteStreaming','BrainSenseSurvey','CalibrationTests','PatientEvents','DiagnosticData', ...
        'BrainSenseSurveysTimeDomain','BrainSenseSurveys'});
else
    datafields = config.datafields;
end

end
