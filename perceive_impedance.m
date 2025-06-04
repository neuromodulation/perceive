% replaced

% function []=perceive_impedance(data, hdr)
% mod = 'mod-Impedance';
% T=table;
% save_impedance=1;
% for c = 1:length(data.Hemisphere)
%     tmp=strsplit(data.Hemisphere(c).Hemisphere,'.');
%     side = tmp{2}(1);
%     %electrodes = unique([{data.Hemisphere(c).SessionImpedance.Monopolar.Electrode2} {data.Hemisphere(c).SessionImpedance.Monopolar.Electrode1}]);
%     e1 = strrep([{data.Hemisphere(c).SessionImpedance.Monopolar.Electrode1} {data.Hemisphere(c).SessionImpedance.Bipolar.Electrode1}],'ElectrodeDef.','') ;
%     e2 = [{data.Hemisphere(c).SessionImpedance.Monopolar.Electrode2} {data.Hemisphere(c).SessionImpedance.Bipolar.Electrode2}];
%     if ~ischar([data.Hemisphere(c).SessionImpedance.Monopolar.ResultValue]) && ~ischar([data.Hemisphere(c).SessionImpedance.Bipolar.ResultValue])
%         imp = [[data.Hemisphere(c).SessionImpedance.Monopolar.ResultValue] [data.Hemisphere(c).SessionImpedance.Bipolar.ResultValue]];
%         for e = 1:length(imp)
%             if strcmp(e1{e},'Case')
%                 T.([hdr.chan '_' side e2{e}(end)]) = imp(e);
%             else
%                 T.([hdr.chan '_' side e2{e}(end) e1{e}(end)]) = imp(e);
%             end
%         end
%     else
%         warning('impedance values too high, not being saved...')
%         save_impedance=0;
%     end
% 
% end
% 
% %plot impedance
% if save_impedance
%     figure
%     barh(table2array(T(1,:))')
%     set(gca,'YTick',1:length(T.Properties.VariableNames),'YTickLabel',strrep(T.Properties.VariableNames,'_',' '))
%     xlabel('Impedance')
%     title(strrep({hdr.subject, hdr.session,'Impedances'},'_',' '))
%     perceive_print(fullfile(hdr.fpath,[hdr.fname '_' mod]))
%     writetable(T,fullfile(hdr.fpath,[hdr.fname '_' mod '.csv']));
% end
% end