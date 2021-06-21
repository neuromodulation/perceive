% perceive_options_rt
%
% Runtime perceive options. Internal, not subject to user changes.
% This function enriches the shared 'popt' options with runtime settings.
%
% Arguments: a structure of options
% Returns: a structure of options
%
% Created by: T.Sieger, 2021-03-15
%
function popt = perceive_options_rt(popt)

    popt.rt.maxOpenFigures.total = 0;
    popt.rt.openFigures.total = 0;

end
