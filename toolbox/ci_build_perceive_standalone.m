function ci_build_perceive_standalone(logPrefix)
% CI wrapper for perceive standalone build with robust logs.

    if nargin < 1 || isempty(logPrefix)
        logPrefix = "ci_perceive";
    end
    if ischar(logPrefix)
        logPrefix = string(logPrefix);
    end

    diaryFile = char(logPrefix + "_build.log");
    errFile = char(logPrefix + "_build_error.txt");

    try
        diary(diaryFile);
        diary on
        build_perceive_standalone();
        diary off
    catch ME
        try
            diary off
        catch %#ok<CTCH>
        end
        report = getReport(ME, "extended", "hyperlinks", "off");
        disp(report);
        fid = fopen(errFile, "w");
        if fid ~= -1
            fprintf(fid, "%s\n", report);
            fclose(fid);
        end
        rethrow(ME);
    end
end
