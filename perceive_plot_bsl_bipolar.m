function perceive_plot_bsl_bipolar(d)

% plots LFP and stimulation amplitude for BrainSense LFP bipolar recordings (BSL)
%
% input:
%   d: FieldTrip-compatible struct with fields:
%      - realtime: timestamps
%      - trial{1}: matrix of signal and stimulation data
%      - label: channel labels
%
% LEFT = rows 1 (LFP) and 3 (stimulation)
% RIGHT = rows 2 (LFP) and 4 (stimulation)

figure('Units','centimeters','PaperUnits','centimeters','Position',[1 1 40 20])

% LEFT
subplot(2,1,1)
yyaxis left
lp = plot(d.realtime, d.trial{1}(1,:), 'LineWidth', 2);
ylabel('LFP Amplitude')
yyaxis right
sp = plot(d.realtime, d.trial{1}(3,:), 'LineWidth', 2, 'LineStyle', '--');
ylabel('Stimulation Amplitude')
title('LEFT')
legend([lp sp], strrep(d.label([1 3]), '_', ' '), 'Location', 'northoutside')
xlabel('Time')
xlim([d.realtime(1) d.realtime(end)])

% RIGHT
subplot(2,1,2)
yyaxis left
lp = plot(d.realtime, d.trial{1}(2,:), 'LineWidth', 2);
ylabel('LFP Amplitude')
yyaxis right
sp = plot(d.realtime, d.trial{1}(4,:), 'LineWidth', 2, 'LineStyle', '--');
ylabel('Stimulation Amplitude')
title('RIGHT')
legend([lp sp], strrep(d.label([2 4]), '_', ' '), 'Location', 'northoutside')
xlabel('Time')
xlim([d.realtime(1) d.realtime(end)])

% title for entire figure
sgtitle(strrep(d.fname, '_', '-'))

end
