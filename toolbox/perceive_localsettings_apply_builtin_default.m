function config = perceive_localsettings_apply_builtin_default(config, requestedInstitution)
%PERCEIVE_LOCALSETTINGS_APPLY_BUILTIN_DEFAULT Same fields as perceive_localsettings_default.json (embedded).
    if nargin < 2 || isempty(requestedInstitution)
        requestedInstitution = 'default';
    end
    if ~strcmpi(requestedInstitution, 'default')
        warning('perceive_localsettings:UsingBuiltinDefault', ...
            ['No perceive_localsettings_*.json found; using built-in default ', ...
             'instead of institution "%s".'], char(requestedInstitution));
    end
    config_js = jsondecode(perceive_localsettings_default_json_minified());
    config_js = perceive_localsettings_normalize_json_types(config_js);
    institution = 'default';
    config.name                = institution;
    config.taskItems           = config_js.taskItems(:)';
    config.stimItems           = config_js.stimItems(:)';
    config.check_followup_time = logical(config_js.check_followup_time);
    config.check_gui_tasks     = logical(config_js.check_gui_tasks);
    config.check_gui_med       = logical(config_js.check_gui_med);
    config.convert2bids        = logical(config_js.convert2bids);
    config.datafields          = config_js.datafields(:)';
    config.plotfields          = config_js.datafields(:)';   % default: plot all datafields
    config.devmode             = logical(config_js.devmode);
end

function config_js = perceive_localsettings_normalize_json_types(config_js)
    config_js.taskItems = perceive_cellstr_from_json_array(config_js.taskItems);
    config_js.stimItems = perceive_cellstr_from_json_array(config_js.stimItems);
    config_js.datafields = perceive_cellstr_from_json_array(config_js.datafields);
    if ~isfield(config_js, 'devmode') || isempty(config_js.devmode)
        config_js.devmode = false;
    end
    % plotfields defaults to all datafields (backward compatible)
    if ~isfield(config_js, 'plotfields') || isempty(config_js.plotfields)
        config_js.plotfields = config_js.datafields;
    end
end

function c = perceive_cellstr_from_json_array(v)
    if isstring(v)
        c = cellstr(v);
    elseif ischar(v)
        c = {v};
    else
        c = v;
    end
end

function s = perceive_localsettings_default_json_minified()
% Minified copy of config/perceive_localsettings_default.json (keep in sync when editing JSON).
    s = ['{"taskItems":["Rest","RestTap","RestTapCont","RestFace","FingerTap","FingerTapL","FingerTapR","Rota","UPDRS","MovArtWalk","MovArtStand","MovArtHead","MovArtArms","MonRevDyt","FTGRampUpThres","FTGFastRamp125Hz","FTG110Hz","FTGBilateral","FTG145Hz","MID","SMTS","MSST","DualTask","Sync1","Sync2","RestTapBlock","RestTapMonoRev","RestTapMonoRevNoBreaks","RestMovBlock","RestMovMonoRev","RestMovMonoRevNoBreaks","RestMonoRev","RestMonoRevNoBreaks","Entrainment","TASK1","TASK2","TASK3","TASK4","TASK5","XXXXX"],"stimItems":["StimOff","StimOnR","StimOnL","StimOnB","StimX","BurstL","BurstR","BurstB","StimOn1L","StimOn1aL","StimOn1bL","StimOn1cL","StimOn2L","StimOn2aL","StimOn2bL","StimOn2cL","StimOn1R","StimOn1aR","StimOn1bR","StimOn1cR","StimOn2R","StimOn2aR","StimOn2bR","StimOn2cR"],"check_followup_time":false,"check_gui_tasks":false,"check_gui_med":false,"convert2bids":false,"datafields":["EventSummary","Impedance","MostRecentInSessionSignalCheck","BrainSenseLfp","BrainSenseTimeDomain","LfpMontageTimeDomain","IndefiniteStreaming","BrainSenseSurvey","CalibrationTests","PatientEvents","DiagnosticData","BrainSenseSurveysTimeDomain","BrainSenseSurveys"],"devmode":false}'];
end
