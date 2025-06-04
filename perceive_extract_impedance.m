function T = perceive_extract_impedance(data, hdr)

% extracts impedance values and saves them in table T
% if impedance values are too high, an empty T is saved (to be used as
% input for perceive_plot_impedance)

mod = 'mod-Impedance';
T = table;
save_impedance = true;

for c = 1:length(data.Hemisphere)
    tmp = strsplit(data.Hemisphere(c).Hemisphere, '.');
    side = tmp{2}(1);

    e1 = strrep([{data.Hemisphere(c).SessionImpedance.Monopolar.Electrode1}, ...
                 {data.Hemisphere(c).SessionImpedance.Bipolar.Electrode1}], ...
                 'ElectrodeDef.', '');
    e2 = [{data.Hemisphere(c).SessionImpedance.Monopolar.Electrode2}, ...
          {data.Hemisphere(c).SessionImpedance.Bipolar.Electrode2}];

    if ~ischar([data.Hemisphere(c).SessionImpedance.Monopolar.ResultValue]) && ...
       ~ischar([data.Hemisphere(c).SessionImpedance.Bipolar.ResultValue])
        imp = [[data.Hemisphere(c).SessionImpedance.Monopolar.ResultValue], ...
               [data.Hemisphere(c).SessionImpedance.Bipolar.ResultValue]];
        for e = 1:length(imp)
            if strcmp(e1{e}, 'Case')
                T.([hdr.chan '_' side e2{e}(end)]) = imp(e);
            else
                T.([hdr.chan '_' side e2{e}(end) e1{e}(end)]) = imp(e);
            end
        end
    else
        warning('Impedance values too high or invalid; not being saved...')
        save_impedance = false;
    end
end

% Save if valid
if save_impedance
    writetable(T, fullfile(hdr.fpath, [hdr.fname '_' mod '.csv']));
else
    T = table(); % return empty table
end

end
