function perceive_plot_impedance(T, hdr)

% plots impedances; if input T is empty no plot is generated

mod = 'mod-Impedance';

if isempty(T)
    warning('Impedance values too high or invalid;, skipping plot.')
    return;
end

figure;
barh(table2array(T(1,:))');
set(gca, 'YTick', 1:length(T.Properties.VariableNames), ...
         'YTickLabel', strrep(T.Properties.VariableNames, '_', ' '));
xlabel('Impedance');
title(strrep({hdr.subject, hdr.session, 'Impedances'}, '_', ' '));
perceive_print(fullfile(hdr.fpath, [hdr.fname '_' mod]));

end
