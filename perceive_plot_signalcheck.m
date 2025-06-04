function perceive_plot_signalcheck(signalcheck)

% plots PSDs for the MostRecentInSessionSignalCheck
%
% input:
%   signalcheck: struct from perceive_extract_signalcheck

freq = signalcheck.freq;
pow = signalcheck.pow;
bad = signalcheck.bad;
peaks = signalcheck.peaks;
channels = signalcheck.channels;
hdr = signalcheck.hdr;
mod = signalcheck.mod;

figure('Units','centimeters','PaperUnits','centimeters','Position',[1 1 40 20])

% ===== RIGHT HEMISPHERE =====
ir = perceive_ci([hdr.chan '_R'], channels);
subplot(1,2,2)
p = plot(freq, pow(ir,:)');
set(p(find(bad(ir))), 'LineStyle', '--')  % dashed lines for artifacts
hold on
plot(freq, nanmean(pow(ir,:), 1), 'k', 'LineWidth', 2)  % average
xlim([1 35])
plot(peaks(ir,1), peaks(ir,2), 'k.', 'MarkerSize', 12)
for c = 1:length(ir)
    if peaks(ir(c),1) > 0
        text(peaks(ir(c),1), peaks(ir(c),2), ...
            [' ' num2str(peaks(ir(c),1),3) ' Hz'], 'FontSize', 8)
    end
end
xlabel('Frequency [Hz]')
ylabel('Power spectral density [\muV^2/Hz]')
title(strrep({hdr.subject, char(hdr.SessionEndDate), 'RIGHT'}, '_', ' '))
legend(strrep(channels(ir), '_', ' '), 'Location', 'northeastoutside')

% ===== LEFT HEMISPHERE =====
il = perceive_ci([hdr.chan '_L'], channels);
subplot(1,2,1)
p = plot(freq, pow(il,:)');
set(p(find(bad(il))), 'LineStyle', '--')
hold on
plot(freq, nanmean(pow(il,:), 1), 'k', 'LineWidth', 2)
xlim([1 35])
plot(peaks(il,1), peaks(il,2), 'k.', 'MarkerSize', 12)
for c = 1:length(il)
    if peaks(il(c),1) > 0
        text(peaks(il(c),1), peaks(il(c),2), ...
            [' ' num2str(peaks(il(c),1),3) ' Hz'], 'FontSize', 8)
    end
end
xlabel('Frequency [Hz]')
ylabel('Power spectral density [\muV^2/Hz]')
title(strrep({'MostRecentSignalCheck', hdr.subject, char(hdr.SessionEndDate), 'LEFT'}, '_', ' '))
legend(strrep(channels(il), '_', ' '), 'Location', 'northeastoutside')

% save figure
perceive_print(fullfile(hdr.fpath, [hdr.fname '_' mod]));

end
