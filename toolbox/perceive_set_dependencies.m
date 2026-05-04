function perceive_set_dependencies()
    % Anchor subfolders on the directory that contains perceive.m
    toolboxDir = fileparts(which('perceive'));
    if isempty(toolboxDir)
        error(['perceive.m must be on the MATLAB path so helper_functions and standalone_scripts ', ...
               'can be added relative to the toolbox.']);
    end

    helperFunctionsPath = fullfile(toolboxDir, 'helper_functions');
    standaloneScriptsPath = fullfile(toolboxDir, 'standalone_scripts');

    if ~exist(helperFunctionsPath, 'dir')
        error('Expected helper folder at %s (next to perceive.m).', helperFunctionsPath);
    end
    addpath(helperFunctionsPath);
    if exist(standaloneScriptsPath, 'dir')
        addpath(standaloneScriptsPath);
    end

    % List of functions to check
    functionsToCheck = {'set_firstsample', 'check_fullname', 'check_stim', 'onAppClose'};

    % Check each function
    for i = 1:length(functionsToCheck)
        functionName = functionsToCheck{i};
        if exist(functionName, 'file') ~= 2
            % Function does not exist
            error('The function ''%s'' is not found in the specified location.\nPlease ensure the function is in the ''perceive\\toolbox\\helper_functions'' subfolder or provide the full path to the function.\nYou can also check for typos in the function name or ensure the function is correctly saved.', functionName);
        else
            % Function exists
            % fprintf('The function ''%s'' is available.\n', functionName);
        end
    end
end