function localsettings = perceive_localsettings_from_mat(localsettings_name)

    % Default argument handling
    if nargin < 1 || isempty(localsettings_name)
        localsettings_name = 'default';
    end

    % Load maps from localsettings.mat (config next to perceive.m)
    toolboxDir = fileparts(which('perceive'));
    if isempty(toolboxDir)
        error('Function perceive must be on the MATLAB path to locate toolbox/config/localsettings.mat.');
    end
    configPath = fullfile(toolboxDir, 'config', 'localsettings.mat');
    data        = load(configPath);

    % Normalize names
    if strcmpi(localsettings_name,'') || strcmpi(localsettings_name,'default')
        institution = 'Default';   % empty string and 'default' → Default
    else
        institution = localsettings_name;  % Charite, Duesseldorf, Wuerzburg, etc.
    end

    % Check if institution exists in maps
    if ~isKey(data.taskItems,institution)
        error('Unknown institution "%s". Available options: %s', ...
              institution, strjoin(keys(data.taskItems),', '));
    end

    % Collapse maps into plain struct
    localsettings.name                = institution;
    localsettings.taskItems           = data.taskItems(institution);
    localsettings.stimItems           = data.stimItems(institution);
    localsettings.check_followup_time = data.check_followup_time(institution);
    localsettings.check_gui_tasks     = data.check_gui_tasks(institution);
    localsettings.check_gui_med       = data.check_gui_med(institution);
    localsettings.convert2bids        = data.convert2bids(institution);
    localsettings.datafields          = data.datafields(institution);

end
