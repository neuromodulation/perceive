function signalcheck = perceive_extract_signalcheck(data, hdr, mod)

% extracts data for MostRecentInSessionSignalCheck into a structured format
%
% inputs:
%   data: array of structs from JSON
%   hdr: metadata header with fields like hdr.chan, hdr.fpath
%   mod: string, module label (e.g. 'mod-MostRecentSignalCheck')
%
% output:
%   signalcheck: struct containing frequency, power, peak, and label data

channels = {};
pow = []; rpow = []; lfit = []; bad = []; peaks = [];

for c = 1:length(data)
    cdata = data(c);
    if iscell(cdata)
        cdata = cdata{1};
    end

    % get side label (L or R)
    tmp = strsplit(cdata.Channel, '_');
    side = tmp{3}(1);

    % get cleaned-up channel name
    tmp = strsplit(cdata.Channel, '.');
    tmp = strrep(tmp{2}, '_AND_', '');
    tmp = strsplit(tmp, '_');
    ch = strrep(strrep(strrep(strrep(strcat(tmp{1}, tmp{2}), 'ZERO','0'), 'ONE','1'), 'TWO','2'), 'THREE','3');

    channels{c} = [hdr.chan '_' side '_' ch];

    freq = cdata.SignalFrequencies;
    pow(c,:) = cdata.SignalPsdValues;
    rpow(c,:) = perceive_power_normalization(pow(c,:), freq);
    lfit(c,:) = perceive_fftlogfitter(freq, pow(c,:));

    bad(c,1) = strcmp('ARTIFACT_PRESENT', cdata.ArtifactStatus(end-12:end));

    try
        peaks(c,1) = cdata.PeakFrequencyInHertz;
        peaks(c,2) = cdata.PeakMagnitudeInMicroVolt;
    catch
        peaks(c,:) = [0 0];
    end
end

signalcheck = struct();
signalcheck.channels = channels;
signalcheck.freq = freq;
signalcheck.pow = pow;
signalcheck.rpow = rpow;
signalcheck.lfit = lfit;
signalcheck.bad = bad;
signalcheck.peaks = peaks;
signalcheck.hdr = hdr;
signalcheck.mod = mod;

end
