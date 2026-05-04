function perceive_localsettings_construction()
% Construct local settings for different institutions and save them as JSON files

%% Define taskItems per institution
taskItems.Charite = { ...
    'Rest','RestTap','RestTapCont','RestFace','FingerTap','FingerTapL','FingerTapR','Rota','UPDRS', ...
    'MovArtWalk','MovArtStand','MovArtHead','MovArtArms','MonRevDyt','FTGRampUpThres','FTGFastRamp125Hz', ...
    'FTG110Hz','FTGBilateral','FTG145Hz','MID','SMTS','MSST','DualTask','Sync1','Sync2','RestTapBlock', ...
    'RestTapMonoRev','RestTapMonoRevNoBreaks','RestMovBlock','RestMovMonoRev','RestMovMonoRevNoBreaks', ...
    'RestMonoRev','RestMonoRevNoBreaks','Entrainment','TASK1','TASK2','TASK3','TASK4','TASK5','XXXXX'};
taskItems.Wuerzburg   = taskItems.Charite;
taskItems.Duesseldorf = taskItems.Charite;
taskItems.Default     = taskItems.Charite;

%% Define stimItems per institution
stimItems.Charite = { ...
    'StimOff','StimOnR','StimOnL','StimOnB','StimX', ...
    'BurstL','BurstR','BurstB', ...
    'StimOn1L','StimOn1aL','StimOn1bL','StimOn1cL', ...
    'StimOn2L','StimOn2aL','StimOn2bL','StimOn2cL', ...
    'StimOn1R','StimOn1aR','StimOn1bR','StimOn1cR', ...
    'StimOn2R','StimOn2aR','StimOn2bR','StimOn2cR'};
stimItems.Wuerzburg   = stimItems.Charite;
stimItems.Duesseldorf = stimItems.Charite;
stimItems.Default     = stimItems.Charite;

%% Define booleans per institution
check_followup_time.Charite     = true;
check_followup_time.Wuerzburg   = false;
check_followup_time.Duesseldorf = false;
check_followup_time.Default     = false;

check_gui_tasks.Charite     = true;
check_gui_tasks.Wuerzburg   = false;
check_gui_tasks.Duesseldorf = false;
check_gui_tasks.Default     = false;

check_gui_med.Charite     = true;
check_gui_med.Wuerzburg   = false;
check_gui_med.Duesseldorf = false;
check_gui_med.Default     = false;

convert2bids.Charite     = true;
convert2bids.Wuerzburg   = false;
convert2bids.Duesseldorf = false;
convert2bids.Default     = false;

%% Define datafields per institution
datafields.Charite = { ...
    'IndefiniteStreaming','LfpMontageTimeDomain'};
datafields.Wuerzburg = { ...
    'BrainSenseTimeDomain','BrainSenseSurveys','CalibrationTests','PatientEvents','DiagnosticData'};
datafields.Duesseldorf = { ...
    'EventSummary','Impedance','MostRecentInSessionSignalCheck','BrainSenseLfp','BrainSenseTimeDomain', ...
    'IndefiniteStreaming','BrainSenseSurvey','BrainSenseSurveysTimeDomain','BrainSenseSurveys'};
datafields.Default = { ...
    'EventSummary','Impedance','MostRecentInSessionSignalCheck','BrainSenseLfp','BrainSenseTimeDomain', ...
    'LfpMontageTimeDomain','IndefiniteStreaming','BrainSenseSurvey','CalibrationTests','PatientEvents', ...
    'DiagnosticData','BrainSenseSurveysTimeDomain','BrainSenseSurveys'};

%% Toolbox root = directory containing perceive.m
toolboxDir = fileparts(which('perceive'));
if isempty(toolboxDir)
    error('Function perceive must be on the MATLAB path to locate toolbox/config.');
end
configPath = fullfile(toolboxDir, 'config');

%% Write JSON files
institutions = {'Default','Charite','Wuerzburg','Duesseldorf'};
for i = 1:numel(institutions)
    inst = institutions{i};
    settingsStruct = struct( ...
        'taskItems', {taskItems.(inst)}, ...
        'stimItems', {stimItems.(inst)}, ...
        'check_followup_time', check_followup_time.(inst), ...
        'check_gui_tasks', check_gui_tasks.(inst), ...
        'check_gui_med', check_gui_med.(inst), ...
        'convert2bids', convert2bids.(inst), ...
        'datafields', {datafields.(inst)} );

    jsonText = jsonencode(settingsStruct, 'PrettyPrint', true);
    fname = fullfile(configPath, ['perceive_localsettings_' lower(inst) '.json']);
    fid = fopen(fname,'w');
    if fid == -1
        error('Cannot open file %s for writing.', fname);
    end
    fwrite(fid, jsonText, 'char');
    fclose(fid);
end

end
