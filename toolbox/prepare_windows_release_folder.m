function prepare_windows_release_folder()
% Prepare a clean Windows release folder with all user-facing launch files.

    toolboxDir = fileparts(mfilename('fullpath'));
    projectRoot = fileparts(toolboxDir);
    releaseDir = fullfile(projectRoot, 'release', 'windows', 'perceive_gui_startup');
    if ~exist(releaseDir, 'dir')
        mkdir(releaseDir);
    end

    filesToCopy = {
        fullfile(toolboxDir, 'perceive_gui_startup.exe')
        fullfile(toolboxDir, 'run_perceive_gui_startup.bat')
        fullfile(toolboxDir, 'detect_matlab_runtime_windows.ps1')
        fullfile(toolboxDir, 'readme.txt')
    };

    optionalFiles = {
        fullfile(toolboxDir, 'MCRInstaller.exe')
    };

    for i = 1:numel(filesToCopy)
        src = filesToCopy{i};
        if ~exist(src, 'file')
            error('Required file missing: %s', src);
        end
        [~, name, ext] = fileparts(src);
        copyfile(src, fullfile(releaseDir, [name ext]), 'f');
    end

    for i = 1:numel(optionalFiles)
        src = optionalFiles{i};
        if exist(src, 'file')
            [~, name, ext] = fileparts(src);
            copyfile(src, fullfile(releaseDir, [name ext]), 'f');
        end
    end

    fprintf('Windows release folder is ready:\n%s\n', releaseDir);
end
