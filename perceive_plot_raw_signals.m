function [raw,time,chanlabels,p]=perceive_plot_raw_signals(data,chanlabels,time)

if ~exist('data','var') || isempty(data)
    [files,path] = uigetfile('*.mat','Select exported Percept FieldTrip .mat file','MultiSelect','on');
    files = strcat(path,files);
else
    files = data;
end

for a=1:length(files)
    
    if iscell(files)
        load(files{a})
    end
    
    if isstruct(data)
        if isfield(data,'realtime')
            try
                time = data.realtime{1};
            catch
                time = data.realtime;
            end
        else
            time = data.time{1};
        end
        chanlabels = data.label;
        fname = data.fname;
        fs = data.fsample;
        raw = data.trial{1};
        
    else
        raw = data;
        fname = '';
        fs = 250;
        if ~exist('time','var') || isempty(time)
            time = linspace(0,length(data)/fs,length(data));
        end
    end
    
    if ~exist('chanlabels','var')
        for a = 1:size(data,1)
            chanlabels{a} = ['chan' num2str(a)];
        end
    end
    raw(isnan(raw))=0;
    figure('Units','centimeters','PaperUnits','centimeters','Position',[1 1 40 20])
    for b = 1:size(raw,1)
        p(b)=plot(time,zscore(raw(b,:)')'./10+b);
        hold on
    end
    set(gca,'YTick',[1:size(raw,1)],'YTickLabel',strrep(chanlabels,'_',' '),'YTickLabelRotation',45);
    xlabel('Time')
    ylabel('Amplitude')
    xlim([time(1) time(end)]);
    ylim([0 length(chanlabels)+1]);
    title(strrep(fname,'_',' '))
    
end
