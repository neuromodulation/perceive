function d = perceive_exe_directory_for_logging()
%PERCEIVE_EXE_DIRECTORY_FOR_LOGGING Folder containing perceive.exe (Windows) or pwd.
    d = '';
    if ispc
        try
            proc = System.Diagnostics.Process.GetCurrentProcess;
            exePath = proc.MainModule.FileName;
            if isa(exePath, 'System.String')
                exePath = char(exePath);
            else
                exePath = char(exePath);
            end
            d = fileparts(exePath);
        catch %#ok<CTCH>
        end
    end
    if isempty(d) || ~exist(d, 'dir')
        d = pwd;
    end
end
