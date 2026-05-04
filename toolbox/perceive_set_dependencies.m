function perceive_set_dependencies()
    % Resolve toolbox directory: prefer the folder of this file (robust for
    % packaged/installed toolboxes and MATLAB Compiler deployments where
    % which('perceive') may point at a different copy on the path).
    thisDir = fileparts(mfilename('fullpath'));
    perceiveDir = fileparts(which('perceive'));

    if exist(fullfile(thisDir, 'helper_functions'), 'dir')
        toolboxDir = thisDir;
    elseif ~isempty(perceiveDir) && exist(fullfile(perceiveDir, 'helper_functions'), 'dir')
        toolboxDir = perceiveDir;
    else
        error(['Could not find helper_functions next to perceive_set_dependencies (%s) ', ...
               'or next to perceive.m (%s).'], thisDir, perceiveDir);
    end

    helperFunctionsPath = fullfile(toolboxDir, 'helper_functions');
    standaloneScriptsPath = fullfile(toolboxDir, 'standalone_scripts');

    addpath(helperFunctionsPath);
    if exist(standaloneScriptsPath, 'dir')
        addpath(standaloneScriptsPath);
    end

    functionsToCheck = {'set_firstsample', 'check_fullname', 'check_stim', 'onAppClose'};

    for i = 1:numel(functionsToCheck)
        functionName = functionsToCheck{i};
        helperFile = fullfile(helperFunctionsPath, [functionName '.m']);
        if exist(helperFile, 'file') ~= 2
            error(['Required helper ''%s'' is missing at:\n%s\n', ...
                   'Rebuild the toolbox so helper_functions is included next to perceive.m.'], ...
                  functionName, helperFile);
        end
    end
end
