function tf = perceive_should_open_startup_gui(files, sub, sesMedOffOn01, extended, gui, localsettings_name, nPassedArgs)
%PERCEIVE_SHOULD_OPEN_STARTUP_GUI True if we should open perceive_gui_startup instead of batch processing.
%
%   - MATLAB: perceive start  (command form) or perceive('start') opens the GUI.
%   - Deployed (exe / .app / Linux binary): no input arguments opens the GUI (double-click).
%   - MATLAB: perceive() with no args keeps legacy behavior (cwd JSON / file picker).

    if perceive_files_is_start_keyword(files)
        tf = true;
        return
    end

    if isdeployed && nPassedArgs == 0
        tf = true;
        return
    end

    tf = false;
end

function tf = perceive_files_is_start_keyword(files)
    tf = false;
    if isempty(files)
        return
    end
    if ischar(files)
        tf = strcmpi(strtrim(files), 'start');
        return
    end
    if iscell(files) && numel(files) == 1
        f1 = files{1};
        if ischar(f1)
            tf = strcmpi(strtrim(f1), 'start');
        elseif isstring(f1) && isscalar(f1)
            tf = strcmpi(strtrim(char(f1)), 'start');
        end
    end
end
