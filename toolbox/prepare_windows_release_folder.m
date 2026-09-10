function prepare_windows_release_folder()
% Prepare/update flat install folder with compiled app payload.

    toolboxDir = fileparts(mfilename('fullpath'));
    projectRoot = fileparts(toolboxDir);
    releaseDir = fullfile(projectRoot, 'install');
    if ~exist(releaseDir, 'dir')
        mkdir(releaseDir);
    end

    appExe = fullfile(toolboxDir, 'perceive.exe');
    if ~exist(appExe, 'file')
        warning('Compiled app not found yet: %s', appExe);
        warning('Build perceive.exe first, then run this helper again.');
    else
        copyfile(appExe, fullfile(releaseDir, 'perceive.exe'), 'f');
    end

    installer = fullfile(toolboxDir, 'MCRInstaller.exe');
    if exist(installer, 'file')
        copyfile(installer, fullfile(releaseDir, 'MCRInstaller.exe'), 'f');
    end

    fprintf('Install folder is ready:\n%s\n', releaseDir);
end
