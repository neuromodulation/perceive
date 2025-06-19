function perceive_extract_brainsensesurvey(data, hdr)

% extraction of BrainSenseSurvey data into FieldTrip-like format
%
% inputs:
%   data - input data struct from Percept JSON
%   hdr - header struct with fields like hdr.d0, hdr.chan, hdr.fpath, etc.
%
% output:
%   none

channels={};
pow=[];rpow=[];lfit=[];bad=[];
for c = 1:length(data)
    cdata = data(c);
    if iscell(cdata)
        cdata=cdata{1};
    end
    tmp=strsplit(cdata.Hemisphere,'.');
    side=tmp{2}(1);
    tmp=strsplit(cdata.SensingElectrodes,'.');tmp=strrep(tmp{2},'_AND_','');
    ch = strrep(strrep(strrep(strrep(tmp,'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3');
    channels{c} = [hdr.chan '_' side '_' ch];
    freq = cdata.LFPFrequency;
    pow(c,:) = cdata.LFPMagnitude;
    rpow(c,:) = perceive_power_normalization(pow(c,:),freq);
    lfit(c,:) = perceive_fftlogfitter(freq,pow(c,:));
    bad(c,1) = strcmp('IFACT_PRESENT',cdata.ArtifactStatus(end-12:end));

    try
        peaks(c,1) = cdata.PeakFrequencyInHertz;
        peaks(c,2) = cdata.PeakMagnitudeInMicroVolt;
    catch
        peaks(c,:)=nan(1,2);
    end
end

T=array2table([freq';pow;rpow;lfit]','VariableNames',[{'Frequency'};strcat({'POW'},channels');strcat({'RPOW'},channels');strcat({'LFIT'},channels')]);
mod = 'mod-BrainSenseSurveyBip';
writetable(T,fullfile(hdr.fpath,[hdr.fname '_' mod 'PowerSpectra.csv']));
T=array2table(peaks','VariableNames',channels,'RowNames',{'PeakFrequency','PeakPower'});
writetable(T,fullfile(hdr.fpath,[hdr.fname '_' mod 'Peaks.csv']));

figure('Units','centimeters','PaperUnits','centimeters','Position',[1 1 40 20])
ir = perceive_ci([hdr.chan '_R'],channels);
subplot(1,2,2)
p=plot(freq,pow(ir,:));
set(p(find(bad(ir))),'linestyle','--')
hold on
plot(freq,nanmean(pow(ir,:)),'color','k','linewidth',2)
xlim([1 35])
plot(peaks(ir,1),peaks(ir,2),'LineStyle','none','Marker','.','MarkerSize',12)
for c = 1:length(ir)
    if peaks(ir(c),1)>0
        text(peaks(ir(c),1),peaks(ir(c),2),[' ' num2str(peaks(ir(c),1),3) ' Hz'])
    end
end
xlabel('Frequency [Hz]')
ylabel('Power spectral density [uV^2/Hz]')
title(strrep({hdr.subject,char(hdr.SessionEndDate),'RIGHT'},'_',' '))
legend(strrep(channels(ir),'_',' '))
il = perceive_ci([hdr.chan '_L'],channels);
subplot(1,2,1)
p=plot(freq,pow(il,:));
set(p(find(bad(il))),'linestyle','--')
hold on
plot(freq,nanmean(pow(il,:)),'color','k','linewidth',2)
xlim([1 35])
title(strrep({hdr.subject,char(hdr.SessionEndDate),'LEFT'},'_',' '))
plot(peaks(il,1),peaks(il,2),'LineStyle','none','Marker','.','MarkerSize',12)
xlabel('Frequency [Hz]')
ylabel('Power spectral density [uV^2/Hz]')
for c = 1:length(il)
    if peaks(il(c),1)>0
        text(peaks(il(c),1),peaks(il(c),2),[' ' num2str(peaks(il(c),1),3) ' Hz'])
    end
end
legend(strrep(channels(il),'_',' '))
%savefig(fullfile(hdr.fpath,[hdr.fname '_run-BrainSenseSurvey.fig']))
%pause(2)
perceive_print(fullfile(hdr.fpath,[hdr.fname '_' mod]))