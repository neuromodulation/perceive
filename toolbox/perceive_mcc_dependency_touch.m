function perceive_mcc_dependency_touch()
%PERCEIVE_MCC_DEPENDENCY_TOUCH Direct references so mcc -m traces helper .m files.
    try %#ok<TRYNC>
        hdr = struct('Groups', struct('Initial', [], 'Final', []));
        check_stim(0, 0, hdr);
    catch %#ok<CTCH>
    end
    try %#ok<TRYNC>
        set_firstsample('0');
    catch %#ok<TRYNC>
    end
    try %#ok<TRYNC>
        check_fullname(tempname);
    catch %#ok<TRYNC>
    end
    try %#ok<TRYNC>
        fh = @onAppClose;
        clear fh %#ok<CLFUNC>
    catch %#ok<CTCH>
    end
end
