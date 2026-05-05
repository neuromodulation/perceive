function build_perceive_gui_startup_standalone()
% Build perceive_gui_startup as a standalone app for the current OS.
% End users run it with MATLAB Runtime (no MATLAB license required).

    appFile = fullfile(fileparts(mfilename('fullpath')), 'perceive_gui_startup.mlapp');
    if ~exist(appFile, 'file')
        error('Could not find perceive_gui_startup.mlapp next to this script.');
    end

    fprintf('Building standalone app from: %s\n', appFile);
    fprintf('This build targets the current OS only.\n');

    compiler.build.standaloneApplication(appFile, ...
        'ExecutableName', 'perceive_gui_startup', ...
        'OutputDir', fileparts(appFile), ...
        'TreatInputsAsNumeric', false);

    fprintf('\nBuild complete.\n');
    fprintf('Distribute the generated app with MATLAB Runtime R2026a.\n');
end
