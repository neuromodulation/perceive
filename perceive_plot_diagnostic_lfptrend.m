function perceive_plot_diagnostic_lfptrend(d)

% plot LFP and STIM trends from DiagnosticData
%
% input:
%   d: FieldTrip-style struct (combined DiagnosticData.LFPTrends)

mod = 'CHRONIC';

figure('Units','centimeters','PaperUnits','centimeters','Position',[1 1 40 20]);

% LEFT subplot
subplot(2,1,1)
title({strrep(d.hdr.fname,'_',' '),'CHRONIC LEFT'})
yyaxis left
scatter(d.time{1}, d.trial{1}(1,:), 20, 'filled', 'Marker', 'o')
ylabel('LFP Amplitude')
yyaxis right
scatter(d.time{1}, d.trial{1}(3,:), 20, 'filled', 'Marker', 's')
ylabel('STIM Amplitude')
xlabel('Time')

% RIGHT subplot
subplot(2,1,2)
yyaxis left
scatter(d.time{1}, d.trial{1}(2,:), 20, 'filled', 'Marker', 'o')
ylabel('LFP Amplitude')
yyaxis right
scatter(d.time{1}, d.trial{1}(4,:), 20, 'filled', 'Marker', 's')
ylabel('STIM Amplitude')
title('RIGHT')
xlabel('Time')

% save plot
perceive_print(fullfile(d.hdr.fpath, [d.hdr.fname '_' mod]));

end
