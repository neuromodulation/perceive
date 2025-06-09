function config = perceive_parse_args(files, sub, sesMedOffOn01, extended, gui, datafields, localsettings)

% parse and normalize inputs for perceive()

arguments
    files {mustBeA(files,["char","cell"])} = ''
    sub {mustBeA(sub,["char","cell","numeric"])} = ''
    sesMedOffOn01 {mustBeMember(sesMedOffOn01,["","MedOff","MedOn","MedDaily","MedOff01","MedOn01","MedOff02","MedOn02","MedOff03","MedOn03","MedOffOn01","MedOffOn02","MedOffOn03","MedOnPostOpIPG","MedOffPostOpIPG","Unknown"])} = ''
    extended {mustBeMember(extended,["","yes"])} = ''
    gui {mustBeMember(gui,["","yes"])} = 'yes'
    datafields {mustBeText} = ''
    localsettings = struct()
end

% -----------------------------
% file handling
% -----------------------------
if isempty(files)
    try
        files = perceive_ffind('*.json');
        if isempty(files)
            [f,p] = uigetfile('*.json','Select .json file','MultiSelect','on');
            if isequal(f,0)
                warning('No file selected, aborting.')
                config = [];
                return
            end
            files = strcat(p,f);
        end
    catch
        warning('Could not auto-find JSON files. Please select manually.')
        [f,p] = uigetfile('*.json','Select .json file','MultiSelect','on');
        files = strcat(p,f);
    end
end
if ischar(files)
    files = {files};
end

config.files = files;

% -----------------------------
% subject parsing
% -----------------------------
if isempty(sub)
    config.subject = '';
elseif isnumeric(sub)
    sub = num2str(sub);
    config.subject = ['sub-' pad(sub,3,'left','0')];
elseif ischar(sub)
    if all(isstrprop(sub, 'digit'))
        sub = ['sub-' pad(sub,3,'left','0')];
    elseif ~startsWith(sub, 'sub-')
        warning('Subject input "%s" not prefixed with "sub-". Fixing.', sub)
        sub = ['sub-' sub];
    end
    config.subject = sub;
elseif iscell(sub)
    config.subject = sub;  % will handle indexing later
end

% -----------------------------
% session setting
% -----------------------------
config.session = sesMedOffOn01;
if isempty(sesMedOffOn01)
    warning('Session not specified — session name will be derived from date + battery.')
end

% -----------------------------
% localsettings parsing
% -----------------------------
config.localsettings = localsettings;
config.check_followup_time = false;
config.check_gui_tasks = false;
config.check_gui_med = false;

if isfield(localsettings,'name')
    switch localsettings.name
        case 'Charite'
            config.check_followup_time = true;
            config.check_gui_tasks = true;
            config.check_gui_med = true;
            warning('Charité settings enabled.')
    end
end

% -----------------------------
% task / acq / mod / run defaults
% -----------------------------
config.task = 'Rest';
config.acq  = 'StimOff';
config.mod  = '';
config.run  = 0;
config.ecg_cleaning = false;

% -----------------------------
% extended / GUI flags
% -----------------------------
config.extended = strcmp(extended, 'yes');
config.gui = strcmp(gui, 'yes');

% -----------------------------
% datafields
% -----------------------------
legalDatafields = {
    ''
    'BrainSenseLfp'
    'BrainSenseSurvey'
    'BrainSenseTimeDomain'
    'CalibrationTests'
    'DiagnosticData'
    'EventSummary'
    'Impedance'
    'IndefiniteStreaming'
    'LfpMontageTimeDomain'
    'MostRecentInSessionSignalCheck'
    'PatientEvents'
};

if isempty(datafields)
    config.datafields = {};
elseif ischar(datafields)
    if strcmpi(datafields, 'all')
        config.datafields = setdiff(legalDatafields, {''});  % all valid, excluding ''
    else
        config.datafields = {datafields};
    end
else
    config.datafields = datafields;
end

% validate contents of datafields
if ~isempty(config.datafields)
    assert(iscellstr(config.datafields), 'datafields must be a cell array of strings.');
    invalid = setdiff(config.datafields, legalDatafields);
    if ~isempty(invalid)
        error(['Invalid datafield(s): %s\nValid options are:\n  %s'], ...
            strjoin(invalid, ', '), strjoin(legalDatafields, '\n  '));
    end
end


end
