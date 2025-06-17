function startup()
    toolboxPath = fileparts(mfilename('perceive')); % Get toolbox folder
    addpath(genpath(toolboxPath)); % Add all subfolders
    savepath; % Save changes persistently

    % Set preferences for first-time setup
    if ~ispref('perceive', 'initialized')
        setpref('perceive', 'initialized', true);
        disp('perceive toolbox initialized successfully.');
    end
end