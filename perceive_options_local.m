% perceive_options_local
%
% Local user-specific perceive options.
%
% Note: this file is USER-SPECIFIC and MUST NOT be under version control.
% Each user can update this file as they wish, but they MUST NOT COMMIT
% this file, as they would have alter the other users' settings!
%
% Arguments: a structure of global options (see perceive_options.m)
% Returns: a structure of refined options
%
function popt = perceive_options_local(popt)

    % User-specific options that override the global options.

    % Users can refine existing options in the 'popt' structure,
    % create new fields in 'popt', or even create a competely new 'popt'
    % structure.

    popt.maxOpenFigures.total = 5;
    popt.maxOpenFigures.DiagnosticData_LfpFrequencySnapshotEvents = 2;

end
