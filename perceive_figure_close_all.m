% perceive_figure_close_all
%
% Close all figures.
%
% Arguments:
% Returns: 
%
% Created by: T.Sieger, 2021-03-15
%
function f = perceive_figure_close_all()
    global popt;

    pdbg('closing all figures');
    close all
    popt.rt.openFigures=struct('total',0);
end
