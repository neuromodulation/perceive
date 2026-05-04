function perceive_init_logging_if_deployed()
%PERCEIVE_INIT_LOGGING_IF_DEPLOYED Append command-window output to perceive.log next to the EXE.
    if ~isdeployed
        return;
    end
    try
        logDir = perceive_exe_directory_for_logging();
        logFile = fullfile(logDir, 'perceive.log');
        fid = fopen(logFile, 'a');
        if fid ~= -1
            fprintf(fid, '\n\n======== Session start %s ========\n', ...
                datestr(now, 'yyyy-mm-dd HH:MM:SS.FFF'));
            fclose(fid);
        end
        diary(logFile);
        diary on
    catch ME
        try
            fprintf(2, 'perceive: could not start log diary: %s\n', ME.message);
        catch %#ok<CTCH>
        end
    end
end
