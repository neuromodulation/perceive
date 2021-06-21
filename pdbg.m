% pdbg
%
% Perceive-specific debug prints.
%
% Arguments:
%   txt: text to be printed
%   level: (optional) level of detail, if missing, the default value of 1 is supplied
%
% Created by: T.Sieger, 2021-03-22
%
function pdbg(txt)
    global popt;

    pdisp(['dbg: ' txt],3);
end
