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
    popt.verbosity = 2;


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


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Refine global options with local user-specific options
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % if there are local options, populate the global options with them
    if exist('perceive_options_local.m','file')
        try
            disp('Adapting options using local options.');
            popt=perceive_options_local(popt);
        catch
            disp('Error using local options, please check ''perceive_options_local.m''.');
        end
    end


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
