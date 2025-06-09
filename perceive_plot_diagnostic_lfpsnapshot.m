function perceive_plot_diagnostic_lfpsnapshot(d)

% plot power spectra from a DiagnosticData.LFPTrends snapshot event

% inputs:
%   d: single struct from perceive_extract_diagnostic_lfpsnapshot

if ~isfield(d, 'trial') || isempty(d.trial)
    warning('Skipping invalid snapshot struct (missing trial).');
    return
end

freq = d.time{1};
pow = d.trial{1}';  % transpose to [freq x 2]
chanlabels = d.label;

% replace ZEROTWO etc. in channel labels 
clean_channels = regexprep(chanlabels, 'ZERO', '0');
clean_channels = regexprep(clean_channels, 'ONE', '1');
clean_channels = regexprep(clean_channels, 'TWO', '2');
clean_channels = regexprep(clean_channels, 'THREE', '3');

% extract event info and stim group from d (if available)
eventName = '';
stimGroup = '';
timestamp = '';

if isfield(d, 'eventname')
    eventName = d.eventname;
end
if isfield(d, 'stimgroup')
    stimGroup = ['STIM GROUP ' d.stimgroup];
end
if isfield(d, 'fnamedate')
    timestamp = char(d.realtime{1});
end

% create title
plotTitle = {strrep(d.hdr.fname, '_', ' '), timestamp, eventName, stimGroup};
plotTitle = plotTitle(~cellfun(@isempty, plotTitle));  % remove empty parts

% plot
figure('Units','centimeters','PaperUnits','centimeters','Position',[1 1 25 15])
plot(freq, pow, 'LineWidth', 2)
xlabel('Frequency [Hz]')
ylabel('Power spectral density [uV^2/Hz]')
legend(strrep(clean_channels, '_', ' '), 'Interpreter', 'none')
title(plotTitle, 'Interpreter', 'none')

% save
perceive_print(fullfile(d.hdr.fpath, d.fname));

% close the figure
close(gcf)

end
