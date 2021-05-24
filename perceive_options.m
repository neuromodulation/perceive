% perceive_options
%
% Global perceive options.
%
% Note: put your local (user-specific) options in perceive_options_local.m,
% which is not under version control.
%
% Arguments: none
% Returns: a structure of options
%
% Created by: T.Sieger, 2021-03-09
%
function popt = perceive_options()

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Global options
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%-----------------------------------------------------------------
    %% progress reporting

    % verbosity level (the higher value, the more verbose output)
    % 0 = no output,
    % 1 = basic progress output,
    % 2 = verbose progress output,
    % 3 = detailed progress output (useful for debugging)
    popt.verbosity = 1;


    %%-----------------------------------------------------------------
    %% plotting
    %%

    % Make PDF plots?
    popt.printToPdf = true;

    % Make PNG plots?
    popt.printToPng = true;

    % The maximum number of open figures in total.
    % (must be positive)
    % If set to 1, a single figure gets reused for all plots. This can be
    % handy when you run perceive as a background job and do not want to be
    % bothered with new figures being created over and over again.
    popt.maxOpenFigures.total = 50;
    % The maximum number of open figures of individual plot types.
    popt.maxOpenFigures.BrainSenseLfp = Inf;
    popt.maxOpenFigures.BrainSenseSurvey = Inf;
    popt.maxOpenFigures.BrainSenseTimeDomain = Inf;
    popt.maxOpenFigures.CalibrationTests = Inf;
    popt.maxOpenFigures.DiagnosticData = Inf;
    popt.maxOpenFigures.DiagnosticData_LFPTrends = Inf;
    popt.maxOpenFigures.DiagnosticData_LfpFrequencySnapshotEvents = 20;
    popt.maxOpenFigures.Ecg = Inf;
    popt.maxOpenFigures.Impedance = Inf;
    popt.maxOpenFigures.IndefiniteStreaming = Inf;
    popt.maxOpenFigures.LfpMontageTimeDomain = Inf;
    popt.maxOpenFigures.MostRecentInSessionSignalCheck = Inf;


    if 0 %% local (user-, or folder-specific) options disabled for now (subject for discussion)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Refine global options with local user-specific options
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % if there are local options, populate the global options with them
    if exist('perceive_options_local.m','file')
        try
            pdisp('Adapting options using local options.',2);
            popt=perceive_options_local(popt);
        catch
            pdisp('Error using local options, please check ''perceive_options_local.m''.');
        end
    else
        % generate perceive_options_local.m
        fcont={
            '% perceive_options_local',...
            '%',...
            '% Local user-specific perceive options.',...
            '%',...
            '% Note: this file is USER-SPECIFIC and MUST NOT be under version control.',...
            '% Each user can update this file as they wish, but they MUST NOT COMMIT',...
            '% this file, as they would have alter the other users'' settings!',...
            '%',...
            '% Arguments: a structure of global options (see perceive_options.m)',...
            '% Returns: a structure of refined options',...
            '%',...
            'function popt = perceive_options_local(popt)',...
            '',...
            '    % User-specific options that override the global options.',...
            '',...
            '    % Users can refine existing options in the ''popt'' structure,',...
            '    % create new fields in ''popt'', or even create a competely new ''popt''',...
            '    % structure.',...
            '',...
            '    % example:',...
            '    % popt.maxOpenFigures.total = 5; % limit the max number of all open figures to 5',...
            '    % popt.maxOpenFigures.DiagnosticData_LfpFrequencySnapshotEvents = 2; % limit the max number of LFP snapshots to 2',...
            '',...
            'end'};

        fh = fopen('perceive_options_local.m','w');
        if fh~=-1
            for li = 1:length(fcont)
                line = fcont{li};
                fprintf(fh,'%s\n',line);
            end
            fclose(fh);
            error(['perceive_options: perceive_options_local.m was not present > generated in the current directory ' ...
                pwd '. Please review it, adapt according to your needs, but DO NOT COMMIT this file! Then, rerun perceive.']);
        else
            error(['perceive_options: perceive_options_local.m was not present, but can''t create it the current directory ' pwd]);
        end

    end
    end % local options disabled for now


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Options check
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Here come sanity checks ensuring options hold reasonable values.
    if popt.maxOpenFigures.total <= 0
        error('popt.maxOpenFigures.total must be positive');
    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Runtime settings
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    popt=perceive_options_rt(popt);

end
