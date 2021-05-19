% pdisp
%
% Perceive-specific disp. Used to display info messages, report progress, and also provide debug prints.
%
% Arguments:
%   txt: text to be printed
%   level: (optional) level of detail, if missing, the default value of 1 is supplied
%
% Created by: T.Sieger, 2021-03-12
%
function pdisp(txt,level)
    global popt;

    if nargin<2
        level=1;
    end

    if isempty(popt) || ~isfield(popt,'verbosity') || level<=popt.verbosity
        disp(txt);
    end
end
