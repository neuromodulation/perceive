function perceive_export_signalcheck(signalcheck)

% exports PSD and peak data from MostRecentSignalCheck to CSV
%
% input:
%   signalcheck: struct from perceive_extract_signalcheck

freq = signalcheck.freq;
pow = signalcheck.pow;
rpow = signalcheck.rpow;
lfit = signalcheck.lfit;
channels = signalcheck.channels;
peaks = signalcheck.peaks;
hdr = signalcheck.hdr;
mod = signalcheck.mod;

% --- create power spectra table ---
% columns: Frequency, POW_channel1, ..., RPOW_channel1, ..., LFIT_channel1, ...
VarNames = [{'Frequency'}, strcat('POW', channels), strcat('RPOW', channels), strcat('LFIT', channels)];
T1 = array2table([freq'; pow; rpow; lfit]', 'VariableNames', VarNames);
writetable(T1, fullfile(hdr.fpath, [hdr.fname '_' mod 'PowerSpectra.csv']));

% --- create peak table ---
T2 = array2table(peaks', ...
    'VariableNames', channels, ...
    'RowNames', {'PeakFrequency', 'PeakPower'});
writetable(T2, fullfile(hdr.fpath, [hdr.fname '_' mod 'Peaks.csv']), 'WriteRowNames', true);

end
