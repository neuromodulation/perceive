% perceive_figure
%
% Prepare figure: create a new one or reuse an existing figure,
% depending on whether the limit on the maximal number of figures is
% reached: if not, a new figure gets created, otherwise already
% existing gets reused. This enables to process a large number of data
% (e.g. hundreds or thousands of LfpTrendLogs) without exhausting
% grapical resources.
%
% Arguments:
%   plot type: character string specifying the type of plot
%           corresponding to specific Percept data type,
%           see perceive_data_fields(). If empty (''),
%           a non-specific figure gets prepared.
% Returns: figure handle
%
% Created by: T.Sieger, 2021-03-12
%
function f = perceive_figure(dataType,varargin)
    global popt;

    if nargin<1
        % supply non-specific data type
        dataType='';
    end

    pdbg(['opening a figure of type: ' dataType]);

    curFigTotal=popt.rt.openFigures.total;
    pdbg(['openFigures total: ' num2str(curFigTotal)]);
    maxFigTotal=popt.maxOpenFigures.total;
    pdbg(['maxOpenFigures total: ' num2str(maxFigTotal)]);

    if isempty(dataType)
        % opening a non-specific figure
        maxFig=NaN;
        curFig=NaN;
    elseif ~ismember(dataType,fieldnames(popt.maxOpenFigures))
        % opening a specific figure having no maximal number of figures configured
        warning('perceive:options',['maxOpenFigures'' not configured for dataType ''' dataType ''', using generic setting']);
        maxFig=NaN;
        curFig=NaN;
    else
        % opening a specific figure having maximal number of figures configured
        if ~ismember(dataType,fieldnames(popt.rt.openFigures))
            pdbg(['creating record for popt.rt.maxOpenFigures for type ''' dataType '''']);
            popt.rt.openFigures=setfield(popt.rt.openFigures,dataType,0);
            curFig=0;
        else
            % get existing figure count for given dataType
            curFig=getfield(popt.rt.openFigures,dataType);
        end
        pdbg(['currently open figures for type ''' dataType ''': ' num2str(curFig)]);
        maxFig=getfield(popt.maxOpenFigures,dataType);
        pdbg(['maxOpenFigures for type ''' dataType ''': ' num2str(maxFig)]);
    end

    if curFigTotal+1<=maxFigTotal && (isnan(curFig) || curFig+1<=maxFig)
        % we can open a new figure
        pdbg('opening a new figure');
        f=figure(varargin{:});
        % update the number of total open figures
        popt.rt.openFigures.total=curFigTotal+1;
        % update the number of specific open figures, if available
        if ~isnan(curFig)
            popt.rt.openFigures=setfield(popt.rt.openFigures,dataType,curFig+1);
        end
    else
        % reuse the current figure
        pdbg('reusing the current figure');
        f=gcf();
        if length(varargin)>0
            if mod(length(varargin),2)==0
                for i=1:length(varargin)/2
                    set(f,varargin{2*(i-1)+1},varargin{2*(i-1)+2});
                end
            elseif length(varargin)>1
                error(['unsupported number of ' num2str(length(varargin)) ' arguments']);
            else
                if isnumeric(varargin{1})
                error('percept_figure(num) is unuspported');
            else
                error(['unsupported argument type to percept_figure(): ' class(varargin{1})]);
            end
        end
    end
end
