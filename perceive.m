function perceive(files,subjectIDs,datafields)
% https://github.com/neuromodulation/perceive
% v0.1 Contributors Wolf-Julian Neumann, Gerd Tinkhauser
% This is an open research tool that is not intended for clinical purposes.

%% INPUT

% files:
% All input is optional, you can specify files as cell or character array
% (e.g. files = 'Report_Json_Session_Report_20200115T123657.json')
% if files isn't specified or remains empty, it will automatically include
% all files in the current working directory
% if no files in the current working directory are found, a you can choose
% files via the MATLAB uigetdir window.
%
% subjectIDs:
% you can specify a subject ID for each file in case you want to follow an
% IRB approved naming scheme for file export
% (e.g. run
% perceive('Report_Json_Session_Report_20200115T123657.json','Charite_sub-001')
% if unspecified or left empy, the subjectID will be created from
% ImplantDate, first letter of disease type and target (e.g. sub-2020110DGpi)


%% OUTPUT
% The script generates BIDS inspired subject and session folders with the
% ieeg format specifier. All time series data are being exported as
% FieldTrip .mat files, as these require no additional dependencies for creation.
% You can reformat with FieldTrip and SPM to MNE
% python and other formats (e.g. using fieldtrip2fiff([fullname '.fif'],data))

%% Recording type output naming
% Each of the FieldTrip data files correspond to a specific aspect of the
% Recording session:
% LMTD = LFP Montage Time Domain - BrainSenseSurvey
% IS = Indefinite Streaming - BrainSenseStreaming
% CT = Calibration Testing - Calibration Tests
% BSL = BrainSense LFP (2 Hz power average + stimulation settings)
% BSTD = BrainSense Time Domain (250 Hz raw data corresponding to the BSL
% file)

%% TODO:
% ADD DEIDENTIFICATION OF COPIED JSON
% BUG FIX UTC?
% ADD BATTERY DRAIN
% ADD BSL data to BSTD ephys file
% ADD PATIENT SNAPSHOT EVENT READINGS
% IMPROVE CHRONIC DIAGNOSTIC READINGS
% ADD Lead DBS Integration for electrode location

if ~exist('files','var') || isempty(files)
    try
        files=perceive_ffind('*.json');
    catch
        files = [];
    end
    if isempty(files)
        [files,path] = uigetfile('*.json','Select .json file','MultiSelect','on');
        if isempty(files)
            return
        end
        files = strcat(path,files);
        
    end
end

if ischar(files)
    files = {files};
end
if exist('subjectIDs','var') && ischar(subjectIDs)
    subjectIDs={subjectIDs};
end


for a = 1:length(files)
    filename = files{a};
    disp(['RUNNING ' filename])
    
    js = jsondecode(fileread(filename));
    js.PatientInformation.Initial.PatientFirstName ='';
    js.PatientInformation.Initial.PatientLastName ='';
    js.PatientInformation.Initial.PatientDateOfBirth ='';
    js.PatientInformation.Final.PatientFirstName ='';
    js.PatientInformation.Final.PatientLastName ='';
    js.PatientInformation.Final.PatientDateOfBirth ='';
    
    infofields = {'SessionDate','SessionEndDate','PatientInformation','DeviceInformation','BatteryInformation','LeadConfiguration','Stimulation','Groups','Stimulation','Impedance','PatientEvents','EventSummary','DiagnosticData'};
    for b = 1:length(infofields)
        if isfield(js,infofields{b})
            hdr.(infofields{b})=js.(infofields{b});
        end
    end
    disp(js.DeviceInformation.Final.NeurostimulatorLocation)
    
    hdr.SessionEndDate = datetime(strrep(js.SessionEndDate(1:end-1),'T',' '));
    hdr.SessionDate = datetime(strrep(js.SessionDate(1:end-1),'T',' '));
    hdr.Diagnosis = strsplit(js.PatientInformation.Final.Diagnosis,'.');hdr.Diagnosis=hdr.Diagnosis{2};
    hdr.OriginalFile = filename;
    hdr.ImplantDate = strrep(strrep(js.DeviceInformation.Final.ImplantDate(1:end-1),'T','_'),':','-');
    hdr.BatteryPercentage = js.BatteryInformation.BatteryPercentage;
    hdr.LeadLocation = strsplit(hdr.LeadConfiguration.Final(1).LeadLocation,'.');hdr.LeadLocation=hdr.LeadLocation{2};
    
    if ~exist('subjectIDs','var')
        if ~isempty(hdr.ImplantDate) &&  ~isnan(str2double(hdr.ImplantDate(1)))
            hdr.subject = ['sub-' strrep(strtok(hdr.ImplantDate,'_'),'-','') hdr.Diagnosis(1) hdr.LeadLocation];
        else
            hdr.subject = ['sub-000' hdr.Diagnosis(1) hdr.LeadLocation];
        end
    elseif iscell(subjectIDs) && length(subjectIDs) == length(files)
        hdr.subject = subjectIDs{a};
    elseif length(subjectIDs) == 1
        hdr.subject = subjectIDs{1};
    end
    hdr.session = ['ses-' char(datetime(hdr.SessionDate,'format','yyyyMMddhhmmss')) num2str(hdr.BatteryPercentage)];
    
    if ~exist(fullfile(hdr.subject,hdr.session,'ieeg'),'dir')
        mkdir(fullfile(hdr.subject,hdr.session,'ieeg'));
    end
    hdr.fpath = fullfile(hdr.subject,hdr.session,'ieeg');
    hdr.fname = [hdr.subject '_' hdr.session];
    hdr.chan = ['LFP_' hdr.LeadLocation];
    hdr.d0 = datetime(js.SessionDate(1:10));
    hdr.js = js;
    if ~exist('datafields','var')
        datafields = sort({'EventSummary','Impedance','MostRecentInSessionSignalCheck','BrainSenseLfp','BrainSenseTimeDomain','LfpMontageTimeDomain','IndefiniteStreaming','LFPMontage','CalibrationTests','PatientEvents','DiagnosticData'});
    end
    alldata = {};
    disp(['SUBJECT ' hdr.subject])
    for b = 1:length(datafields)
        if isfield(js,datafields{b})
            data = js.(datafields{b});
            if isempty(data)
                continue
            end
            switch datafields{b}
                case 'Impedance'
                    
                    T=table;
                    for c = 1:length(data.Hemisphere)
                        tmp=strsplit(data.Hemisphere(c).Hemisphere,'.');
                        side = tmp{2}(1);
                        electrodes = unique([{data.Hemisphere(c).SessionImpedance.Monopolar.Electrode2} {data.Hemisphere(c).SessionImpedance.Monopolar.Electrode1}]);
                        e1 = strrep([{data.Hemisphere(c).SessionImpedance.Monopolar.Electrode1} {data.Hemisphere(c).SessionImpedance.Bipolar.Electrode1}],'ElectrodeDef.','') ;
                        e2 = [{data.Hemisphere(c).SessionImpedance.Monopolar.Electrode2} {data.Hemisphere(c).SessionImpedance.Bipolar.Electrode2}];
                        imp = [[data.Hemisphere(c).SessionImpedance.Monopolar.ResultValue] [data.Hemisphere(c).SessionImpedance.Bipolar.ResultValue]];
                        
                        for e = 1:length(imp)
                            if strcmp(e1{e},'Case')
                                T.([hdr.chan '_' side e2{e}(end)]) = imp(e);
                            else
                                T.([hdr.chan '_' side e2{e}(end) e1{e}(end)]) = imp(e);
                            end
                        end
                    end
                    figure
                    barh(table2array(T(1,:))')
                    set(gca,'YTick',1:length(T.Properties.VariableNames),'YTickLabel',strrep(T.Properties.VariableNames,'_',' '))
                    xlabel('Impedance')
                    title({hdr.subject, hdr.session,'Impedances'})
                    perceive_print(fullfile(hdr.fpath,[hdr.fname '_run-Impedance']))
                    writetable(T,fullfile(hdr.fpath,[hdr.fname '_run-Impedance.csv']));
                    
                case 'PatientEvents'
                    disp(fieldnames(data));
                    
                case 'MostRecentInSessionSignalCheck'
                    if ~isempty(data)
                        channels={};
                        pow=[];rpow=[];lfit=[];bad=[];peaks=[];
                        for c = 1:length(data)
                            cdata = data(c);
                            if iscell(cdata)
                                cdata=cdata{1};
                            end
                            tmp=strsplit(cdata.Channel,'_');
                            side=tmp{3}(1);
                            tmp=strsplit(cdata.Channel,'.');tmp=strrep(tmp{2},'_AND_','');tmp=strsplit(tmp,'_');
                            ch = strrep(strrep(strrep(strrep(strcat(tmp{1},tmp{2}),'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3');
                            channels{c} = [hdr.chan '_' side '_' ch];
                            freq = cdata.SignalFrequencies;
                            pow(c,:) = cdata.SignalPsdValues;
                            rpow(c,:) = perceive_power_normalization(pow(c,:),freq);
                            lfit(c,:) = perceive_fftlogfitter(freq,pow(c,:));
                            bad(c,1) = strcmp('IFACT_PRESENT',cdata.ArtifactStatus(end-12:end));
                            
                            try
                                peaks(c,1) = cdata.PeakFrequencyInHertz;
                                peaks(c,2) = cdata.PeakMagnitudeInMicroVolt;
                            catch
                                peaks(c,:)=zeros(1,2);
                            end
                        end
                        
                        T=array2table([freq';pow;rpow;lfit]','VariableNames',[{'Frequency'};strcat({'POW'},channels');strcat({'RPOW'},channels');strcat({'LFIT'},channels')]);
                        writetable(T,fullfile(hdr.fpath,[hdr.fname '_run-MostRecentSignalCheckPowerSpectra.csv']));
                        T=array2table(peaks','VariableNames',channels,'RowNames',{'PeakFrequency','PeakPower'});
                        writetable(T,fullfile(hdr.fpath,[hdr.fname '_run-MostRecentSignalCheck_Peaks.csv']));
                        
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
                        ylabel('Power spectral density [uV²/Hz]')
                        title({hdr.subject,strrep(char(hdr.SessionDate),'_',' '),'RIGHT'})
                        legend(strrep(channels(ir),'_',' '))
                        il = perceive_ci([hdr.chan '_L'],channels);
                        subplot(1,2,1)
                        p=plot(freq,pow(il,:));
                        set(p(find(bad(il))),'linestyle','--')
                        hold on
                        plot(freq,nanmean(pow(il,:)),'color','k','linewidth',2)
                        xlim([1 35])
                        title(strrep({'MostRecentSignalCheck',hdr.subject,char(hdr.SessionDate),'LEFT'},'_',' '))
                        plot(peaks(il,1),peaks(il,2),'LineStyle','none','Marker','.','MarkerSize',12)
                        xlabel('Frequency [Hz]')
                        ylabel('Power spectral density [uV²/Hz]')
                        for c = 1:length(il)
                            if peaks(il(c),1)>0
                                text(peaks(il(c),1),peaks(il(c),2),[' ' num2str(peaks(il(c),1),3) ' Hz'])
                            end
                        end
                        legend(strrep(channels(il),'_',' '))
                        savefig(fullfile(hdr.fpath,[hdr.fname '_run-MostRecentSignalCheck.fig']))
                        perceive_print(fullfile(hdr.fpath,[hdr.fname '_run-MostRecentSignalCheck']))
                        
                    end
                case 'DiagnosticData'
                    
                    if isfield(data,'LFPTrendLogs')
                        
                        data.left=data.LFPTrendLogs.HemisphereLocationDef_Left;
                        data.right=data.LFPTrendLogs.HemisphereLocationDef_Right;
                        
                        runs = fieldnames(data.left);
                        LFP=[];
                        STIM=[];
                        DT=[];
                        for c = 1:length(runs)
                            ldata = data.left.(runs{c});
                            rdata = data.right.(runs{c});
                            LFP=[LFP;[[rdata(:).LFP];[ldata(:).LFP]]'];
                            STIM=[STIM;[[rdata(:).AmplitudeInMilliAmps];[ldata(:).AmplitudeInMilliAmps]]'];
                            DT = [DT datetime({ldata(:).DateTime},'InputFormat','yyyy-MM-dd''T''HH:mm:ss''Z''')];
                        end
                        [DT,i]=sort(DT);
                        LFP = LFP(i,:);
                        d.hdr = hdr;
                        d.fsample = 0.00166666666;
                        d.trial{1} = [LFP,STIM]';
                        d.label = {'LFP_LEFT','LFP_RIGHT','STIM_LEFT','STIM_RIGHT'};
                        d.time{1} = linspace(seconds(DT(1)-hdr.d0),seconds(DT(end)-hdr.d0),size(d.trial{1},2));
                        d.realtime{1} = DT;
                        d.fsample = 1/diff(d.time{1}(1:2));
                        d.hdr.Fs = d.fsample;
                        d.hdr.label = d.label;
                        firstsample = d.time{1}(1);
                        lastsample = d.time{1}(end);
                        d.sampleinfo(1,:) = [firstsample lastsample];
                        
                        
                        
                        d.fname = [hdr.fname '_run-CHRONIC' char(datetime(DT(1),'format','yyyyMMddhhmmss'))];
                        alldata{length(alldata)+1} = d;
                        
                        
                        figure('Units','centimeters','PaperUnits','centimeters','Position',[1 1 40 20])
                        subplot(2,1,1)
                        title({strrep(hdr.fname,'_',' '),'CHRONIC LEFT'})
                        yyaxis left
                        plot(DT,LFP(:,1),'Linestyle','none','Marker','.')
                        ylabel('LFP Amplitude')
                        yyaxis right
                        plot(DT,STIM(:,1),'Linewidth',2,'linestyle','--')
                        ylabel('STIM Amplitude')
                        xlabel('Time')
                        subplot(2,1,2)
                        yyaxis left
                        plot(DT,LFP(:,2),'Linestyle','none','Marker','.')
                        ylabel('LFP Amplitude')
                        yyaxis right
                        plot(DT,STIM(:,2),'Linewidth',2,'linestyle','--')
                        title('RIGHT')
                        xlabel('Time')
                        ylabel('STIM Amplitude')
                        savefig(fullfile(hdr.fpath,[hdr.fname '_CHRONIC.fig']))
                        perceive_print(fullfile(hdr.fpath,[hdr.fname '_CHRONIC']))
                    end
                    if isfield(data,'LfpFrequencySnapshotEvents')
                        cdata= data.LfpFrequencySnapshotEvents;
                        Tpow=table;Trpow=table;Tlfit=table;pow=[];rpow=[];lfit=[];lfp=struct;
                        for c = 1:length(cdata)
                            try 
                                lfp=cdata{c};
                            catch
                                lfp=cdata(c);
                            end
                            if lfp.LFP && isfield(lfp,'LfpFrequencySnapshotEvents')
                                ids(c) = lfp.EventID;
                                DT(c) = datetime(lfp.DateTime(1:end-1),'InputFormat','yyyy-MM-dd''T''HH:mm:ss');
                                events{c} = lfp.EventName;
                                tmp = strsplit(strrep(lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Left.SenseID,'_AND',''),'.');
                                ch1 = strcat(hdr.chan,'_L_',strrep(strrep(strrep(strrep(strrep(tmp{2},'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3'),'_',''));
                                tmp = strsplit(strrep(lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Right.SenseID,'_AND',''),'.');
                                ch2 = strcat(hdr.chan,'_R_',strrep(strrep(strrep(strrep(strrep(tmp{2},'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3'),'_',''));
                                chanlabels{c} = {ch1 ch2};
                                stimgroups{c} = lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Left.GroupId(end);
                                freq = lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Left.Frequency;
                                pow(:,1) = lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Left.FFTBinData;
                                pow(:,2) = lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Right.FFTBinData;
                                Tpow.Frequency = freq;
                                Tpow.(strrep([events{c} '_' num2str(c) '_' ch1 '_' char(datetime(DT(c),'Format','yyyMMddHHmmss'))],' ','')) = pow(:,1);
                                Tpow.(strrep([events{c} '_' num2str(c) '_' ch2 '_' char(datetime(DT(c),'Format','yyyMMddHHmmss'))],' ','')) = pow(:,2);
                                
                                
                                figure
                                plot(freq,pow)
                                legend(strrep(chanlabels{c},'_',' '))
                                title({strrep(hdr.fname,'_',' ');char(DT(c));events{c};['STIM GROUP ' stimgroups{c}]})
                                xlabel('Frequency [Hz]')
                                ylabel('Power spectral density [uV²/Hz]')
                                savefig(fullfile(hdr.fpath,[hdr.fname '_LFPSnapshot_' events{c} '-' num2str(c) '.fig']))
                                perceive_print(fullfile(hdr.fpath,[hdr.fname '_LFPSnapshot_' events{c} '-' num2str(c)]))
                            else
                                warning('LFP Snapshot Event without LFP data present.')
                            end
                        end
                        writetable(Tpow,fullfile(hdr.fpath,[hdr.fname '_LFPSnapshotEvents.csv']))
                   
                        
                    end
                    
                case 'BrainSenseTimeDomain'
                    
                    FirstPacketDateTime = strrep(strrep({data(:).FirstPacketDateTime},'T',' '),'Z','');
                    runs = unique(FirstPacketDateTime);
                    
                    Pass = {data(:).Pass};
                    tmp =  {data(:).GlobalSequences};
                    for c = 1:length(tmp)
                        GlobalSequences(c,:) = str2double(tmp{c});
                    end
                    tmp =  {data(:).GlobalPacketSizes};
                    for c = 1:length(tmp)
                        GlobalPacketSizes(c,:) = str2double(tmp{c});
                    end
                    
                    fsample = data.SampleRateInHz;
                    gain=[data(:).Gain]';
                    [tmp1,tmp2] = strtok(strrep({data(:).Channel}','_AND',''),'_');
                    ch1 = strrep(strrep(strrep(strrep(tmp1,'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3');
                    
                    [tmp1,tmp2] = strtok(tmp2,'_');
                    ch2 = strrep(strrep(strrep(strrep(tmp1,'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3');
                    side = strrep(strrep(strtok(tmp2,'_'),'LEFT','L'),'RIGHT','R');
                    Channel = strcat(hdr.chan,'_',side,'_', ch1, ch2);
                    d=[];
                    for c = 1:length(runs)
                        i=perceive_ci(runs{c},FirstPacketDateTime);
                        raw=[data(i).TimeDomainData]';
                        d.hdr = hdr;
                        d.datatype = datafields{b};
                        d.hdr.CT.Pass=strrep(strrep(unique(strtok(Pass(i),'_')),'FIRST','1'),'SECOND','2');
                        d.hdr.CT.GlobalSequences=GlobalSequences(i,:);
                        d.hdr.CT.GlobalPacketSizes=GlobalPacketSizes(i,:);
                        d.hdr.CT.FirstPacketDateTime = runs{c};
                        
                        d.label=Channel(i);
                        d.trial{1} = raw;
                        
                        d.time{1} = linspace(seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.sss')-hdr.d0),seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.sss')-hdr.d0)+size(d.trial{1},2)/fsample,size(d.trial{1},2));
                        
                        d.fsample = fsample;
                        
                        firstsample = 1+round(fsample*seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.sss')-hdr.d0));
                        lastsample = firstsample+size(d.trial{1},2);
                        d.sampleinfo(1,:) = [firstsample lastsample];
                        if firstsample<0
                            keyboard
                        end
                        d.trialinfo(1) = c;
                        d.fname = [hdr.fname '_run-BSTD' char(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.sss','format','yyyyMMddhhmmss'))];
                        d.hdr.Fs = d.fsample;
                        d.hdr.label = d.label;
                        alldata{length(alldata)+1} = d;
                    end
                case 'BrainSenseLfp'
              
                    FirstPacketDateTime = strrep(strrep({data(:).FirstPacketDateTime},'T',' '),'Z','');
                    runs = unique(FirstPacketDateTime);
                    bsldata=[];bsltime=[];bslchannels=[];
                    figure('Units','centimeters','PaperUnits','centimeters','Position',[1 1 40 20])
                    for c=1:length(runs)
                        cdata = data(c);
                        tmp = strrep(cdata.Channel,'_AND','');
                        tmp = strsplit(strrep(strrep(strrep(strrep(strrep(tmp,'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3'),'_',''),',');
                        lfpchannels = {[hdr.chan '_' tmp{1}(3) '_' tmp{1}(1:2) ], ...
                            [hdr.chan '_' tmp{2}(3) '_' tmp{2}(1:2)]};
                        d=[];
                        d.hdr = hdr;
                        d.hdr.BSL.TherapySnapshot = cdata.TherapySnapshot;
                        tmp = d.hdr.BSL.TherapySnapshot.Left;
                        lfpsettings{1,1} = ['PEAK' num2str(round(tmp.FrequencyInHertz)) 'Hz_THR' num2str(tmp.LowerLfpThreshold) '-' num2str(tmp.UpperLfpThreshold) '_AVG' num2str(round(tmp.AveragingDurationInMilliSeconds)) 'ms'];
                        stimchannels = ['STIM_L_' num2str(tmp.RateInHertz) 'Hz_' num2str(tmp.PulseWidthInMicroSecond) 'us'];
                        tmp = d.hdr.BSL.TherapySnapshot.Right;
                        lfpsettings{2,1} = ['PEAK' num2str(round(tmp.FrequencyInHertz)) 'Hz_THR' num2str(tmp.LowerLfpThreshold) '-' num2str(tmp.UpperLfpThreshold) '_AVG' num2str(round(tmp.AveragingDurationInMilliSeconds)) 'ms'];
                        stimchannels = {stimchannels,['STIM_R_' num2str(tmp.RateInHertz) 'Hz_' num2str(tmp.PulseWidthInMicroSecond) 'us']};
                        
                        
                        d.label = [strcat(lfpchannels','_',lfpsettings)' stimchannels];
                        d.hdr.label = d.label;
                        
                        d.fsample = cdata.SampleRateInHz;
                        d.hdr.Fs = d.fsample;
                  
                        for e =1:length(cdata.LfpData)
                            d.trial{1}(1:2,e) = [cdata.LfpData(e).Left.LFP;cdata.LfpData(e).Right.LFP];
                            d.trial{1}(3:4,e) = [cdata.LfpData(e).Left.mA;cdata.LfpData(e).Right.mA];
                            d.time{1}(e) = cdata.LfpData(e).TicksInMs/1000;
                            d.realtime(e) = datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS','Format','yyyy-MM-dd HH:mm:ss.SSS')+seconds((d.time{1}(e)-d.time{1}(1)));
                            d.hdr.BSL.seq(e)= cdata.LfpData(e).Seq;
                        end
                      
                        d.trialinfo(1) = c;
                        d.hdr.realtime = d.realtime;
                        
                        
                        d.fname = [hdr.fname '_run-BSL' char(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.sss','format','yyyyMMddhhmmss'))];
                        
                        subplot(2,1,1)
                        yyaxis left
                        lp=plot(d.realtime,d.trial{1}(1,:),'linewidth',2);
                        ylabel('LFP Amplitude')
                        yyaxis right
                        sp=plot(d.realtime,d.trial{1}(3,:),'linewidth',2,'linestyle','--');
                        title(strrep(d.fname,'_','-'))
                        ylabel('Stimulation Amplitude')
                        legend([lp sp],strrep(d.label([1 3]),'_',' '),'location','northoutside')
                        xlabel('Time')
                        xlim([d.realtime(1) d.realtime(end)])
                        subplot(2,1,2)
                        yyaxis left
                        lp=plot(d.realtime,d.trial{1}(2,:),'linewidth',2);
                        ylabel('LFP Amplitude')
                        yyaxis right
                        title('RIGHT')
                        sp=plot(d.realtime,d.trial{1}(4,:),'linewidth',2,'linestyle','--');
                        ylabel('Stimulation Amplitude')
                        legend([lp sp],strrep(d.label([1 3]),'_',' '),'location','northoutside')
                        xlabel('Time')
                        xlim([d.realtime(1) d.realtime(end)])
                        
                        
                        bsldata = [bsldata,d.trial{1}];
                        bsltime = [bsltime,d.realtime];
                        bslchannels = d.label;
                        alldata{length(alldata)+1} = d;
                        
                        savefig(fullfile(hdr.fpath,[d.fname '.fig']))
                        perceive_print(fullfile(hdr.fpath,[d.fname]))
                        
                        
                    end
                    T=table;
                    T.Time = bsltime';
                    for c = 1:length(bslchannels)
                        T.(bslchannels{c}) = bsldata(c,:)';
                    end
                    
                    writetable(T,fullfile(hdr.fpath,[hdr.fname '_run-BrainSenseLFP.csv']))
                    
                case 'LfpMontageTimeDomain'
                    
                    FirstPacketDateTime = strrep(strrep({data(:).FirstPacketDateTime},'T',' '),'Z','');
                    runs = unique(FirstPacketDateTime);
                    
                    Pass = {data(:).Pass};
                    tmp =  {data(:).GlobalSequences};
                    for c = 1:length(tmp)
                        GlobalSequences(c,:) = str2double(tmp{c});
                    end
                    tmp =  {data(:).GlobalPacketSizes};
                    for c = 1:length(tmp)
                        GlobalPacketSizes(c,:) = str2double(tmp{c});
                    end
                    
                    fsample = data.SampleRateInHz;
                    gain=[data(:).Gain]';
                    [tmp1,tmp2] = strtok(strrep({data(:).Channel}','_AND',''),'_');
                    ch1 = strrep(strrep(strrep(strrep(tmp1,'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3');
                    
                    [tmp1,tmp2] = strtok(tmp2,'_');
                    ch2 = strrep(strrep(strrep(strrep(tmp1,'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3');
                    side = strrep(strrep(strtok(tmp2,'_'),'LEFT','L'),'RIGHT','R');
                    Channel = strcat(hdr.chan,'_',side,'_', ch1, ch2);
                    d=[];
                    for c = 1:length(runs)
                        i=perceive_ci(runs{c},FirstPacketDateTime);
                        d.hdr = hdr;
                        d.datatype = datafields{b};
                        d.hdr.IS.Pass=strrep(strrep(unique(strtok(Pass(i),'_')),'FIRST','1'),'SECOND','2');
                        d.hdr.IS.GlobalSequences=GlobalSequences(i,:);
                        d.hdr.IS.GlobalPacketSizes=GlobalPacketSizes(i,:);
                        d.hdr.IS.FirstPacketDateTime = runs{c};
                        tmp = [data(i).TimeDomainData]';
                        d.trial{1} = [tmp];
                        d.label=Channel(i);
                        
                        d.time{1} = linspace(seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.sss')-hdr.d0),seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.sss')-hdr.d0)+size(d.trial{1},2)/fsample,size(d.trial{1},2));
                        d.fsample = fsample;
                        firstsample = 1+round(fsample*seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.sss')-datetime(FirstPacketDateTime{1})));
                        lastsample = firstsample+size(d.trial{1},2);
                        d.sampleinfo(1,:) = [firstsample lastsample];
                        d.trialinfo(1) = c;
                        
                        d.hdr.label = d.label;
                        d.hdr.Fs = d.fsample;
                        d.fname = [hdr.fname '_run-LMTD' char(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.sss','format','yyyyMMddhhmmss'))];
                        alldata{length(alldata)+1} = d;
                    end
                case 'LFPMontage'
                    
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
                    writetable(T,fullfile(hdr.fpath,[hdr.fname '_run-LFPMontagePowerSpectra.csv']));
                    T=array2table(peaks','VariableNames',channels,'RowNames',{'PeakFrequency','PeakPower'});
                    writetable(T,fullfile(hdr.fpath,[hdr.fname '_run-LFPMontage_Peaks.csv']));
                    
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
                    ylabel('Power spectral density [uV²/Hz]')
                    title({hdr.subject,strrep(char(hdr.SessionDate),'_',' '),'RIGHT'})
                    legend(strrep(channels(ir),'_',' '))
                    il = perceive_ci([hdr.chan '_L'],channels);
                    subplot(1,2,1)
                    p=plot(freq,pow(il,:));
                    set(p(find(bad(il))),'linestyle','--')
                    hold on
                    plot(freq,nanmean(pow(il,:)),'color','k','linewidth',2)
                    xlim([1 35])
                    title(strrep({hdr.subject,char(hdr.SessionDate),'LEFT'},'_',' '))
                    plot(peaks(il,1),peaks(il,2),'LineStyle','none','Marker','.','MarkerSize',12)
                    xlabel('Frequency [Hz]')
                    ylabel('Power spectral density [uV²/Hz]')
                    for c = 1:length(il)
                        if peaks(il(c),1)>0
                            text(peaks(il(c),1),peaks(il(c),2),[' ' num2str(peaks(il(c),1),3) ' Hz'])
                        end
                    end
                    legend(strrep(channels(il),'_',' '))
                    savefig(fullfile(hdr.fpath,[hdr.fname '_run-LFPMontage.fig']))
                    pause(2)
                    perceive_print(fullfile(hdr.fpath,[hdr.fname '_run-LFPMontage']))
         
                    
                case 'IndefiniteStreaming'
                    
                    FirstPacketDateTime = strrep(strrep({data(:).FirstPacketDateTime},'T',' '),'Z','');
                    runs = unique(FirstPacketDateTime);
                    
                    Pass = {data(:).Pass};
                    tmp =  {data(:).GlobalSequences};
                    for c = 1:length(tmp)
                        GlobalSequences(c,:) = str2double(tmp{c});
                    end
                    tmp =  {data(:).GlobalPacketSizes};
                    for c = 1:length(tmp)
                        GlobalPacketSizes(c,:) = str2double(tmp{c});
                    end
                    
                    fsample = data.SampleRateInHz;
                    gain=[data(:).Gain]';
                    [tmp1,tmp2] = strtok(strrep({data(:).Channel}','_AND',''),'_');
                    ch1 = strrep(strrep(strrep(strrep(tmp1,'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3');
                    
                    [tmp1,tmp2] = strtok(tmp2,'_');
                    ch2 = strrep(strrep(strrep(strrep(tmp1,'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3');
                    side = strrep(strrep(strtok(tmp2,'_'),'LEFT','L'),'RIGHT','R');
                    Channel = strcat(hdr.chan,'_',side,'_', ch1, ch2);
                    d=[];
                    for c = 1:length(runs)
                        i=perceive_ci(runs{c},FirstPacketDateTime);
                        d.hdr = hdr;
                        d.datatype = datafields{b};
                        d.hdr.IS.Pass=strrep(strrep(unique(strtok(Pass(i),'_')),'FIRST','1'),'SECOND','2');
                        d.hdr.IS.GlobalSequences=GlobalSequences(i,:);
                        d.hdr.IS.GlobalPacketSizes=GlobalPacketSizes(i,:);
                        d.hdr.IS.FirstPacketDateTime = runs{c};
                        tmp =  [data(i).TimeDomainData]';;
                        xchans = perceive_ci({'L_03','L_13','L_02','R_03','R_13','R_02'},Channel(i));
                        nchans = {'L_01','L_12','L_23','R_01','R_12','R_23'};
                        refraw = [tmp(xchans(1),:)-tmp(xchans(2),:);(tmp(xchans(1),:)-tmp(xchans(2),:))-tmp(xchans(3),:);tmp(xchans(3),:)-tmp(xchans(1),:);
                            tmp(xchans(4),:)-tmp(xchans(5),:);(tmp(xchans(4),:)-tmp(xchans(5),:))-tmp(xchans(6),:);tmp(xchans(6),:)-tmp(xchans(4),:)];
                        d.trial{1} = [refraw;tmp];
                        d.label=[Channel(i);strcat(hdr.chan,'_',nchans')];
                        
                        d.time{1} = linspace(seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.sss')-hdr.d0),seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.sss')-hdr.d0)+size(d.trial{1},2)/fsample,size(d.trial{1},2));
                        d.fsample = fsample;
                        firstsample = 1+round(fsample*seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.sss')-datetime(FirstPacketDateTime{1})));
                        lastsample = firstsample+size(d.trial{1},2);
                        d.sampleinfo(1,:) = [firstsample lastsample];
                        d.trialinfo(1) = c;
                        d.hdr.label=d.label;
                        d.hdr.Fs = d.fsample;
                        
                        d.fname = [hdr.fname '_run-IS' char(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.sss','format','yyyyMMddhhmmss'))];
                        alldata{length(alldata)+1} = d;
                    end
                    
                case 'CalibrationTests'
                    
                    FirstPacketDateTime = strrep(strrep({data(:).FirstPacketDateTime},'T',' '),'Z','');
                    runs = unique(FirstPacketDateTime);
                    Pass = {data(:).Pass};
                    tmp =  {data(:).GlobalSequences};
                    for c = 1:length(tmp)
                        GlobalSequences(c,:) = str2double(tmp{c});
                    end
                    tmp =  {data(:).GlobalPacketSizes};
                    for c = 1:length(tmp)
                        GlobalPacketSizes(c,:) = str2double(tmp{c});
                    end
                  
                    figure
                    for c = 1:length(data)
                    fsample = data(c).SampleRateInHz;
                    gain=[data(c).Gain]';
                    [tmp1,tmp2] = strtok(strrep({data(c).Channel}','_AND',''),'_');
                    ch1 = strrep(strrep(strrep(strrep(tmp1,'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3');
                    
                    [tmp1,tmp2] = strtok(tmp2,'_');
                    ch2 = strrep(strrep(strrep(strrep(tmp1,'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3');
                    side = strrep(strrep(strtok(tmp2,'_'),'LEFT','L'),'RIGHT','R');
                    Channel(c) = strcat(hdr.chan,'_',side,'_', ch1, ch2);
                    tdtmp = zscore(data(c).TimeDomainData)./10+c;
                    ttmp=[1:length(tdtmp)]./fsample;
                    plot(ttmp,tdtmp)
                    hold on
                    end
                    xlim([ttmp(1),ttmp(end)])
                    set(gca,'YTick',1:c,'YTickLabel',strrep(Channel,'_',' '),'YTickLabelRotation',45)
                    xlabel('Time [s]')
                    title({hdr.subject,hdr.session,'All CalibrationTests'})
                    savefig(fullfile(hdr.fpath,[hdr.fname '_run-AllCalibrationTests.fig']))
                    perceive_print(fullfile(hdr.fpath,[hdr.fname '_run-AllCalibrationTests']))
         
                    
                    for c = 1:length(runs)
                    d=[];
                    
                        i=perceive_ci(runs{c},FirstPacketDateTime);
                        raw=[data(i).TimeDomainData]';
                        d.hdr = hdr;
                        d.datatype = datafields{b};
                        d.hdr.CT.Pass=strrep(strrep(unique(strtok(Pass(i),'_')),'FIRST','1'),'SECOND','2');
                        d.hdr.CT.GlobalSequences=GlobalSequences(i,:);
                        d.hdr.CT.GlobalPacketSizes=GlobalPacketSizes(i,:);
                        d.hdr.CT.FirstPacketDateTime = runs{c};
                        
                        d.label=Channel(i);
                        d.trial{1} = raw;
                        
                        d.time{1} = linspace(seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.sss')-hdr.d0),seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.sss')-hdr.d0)+size(d.trial{1},2)/fsample,size(d.trial{1},2));
                        
                        d.fsample = fsample;
                        firstsample = 1+round(fsample*seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.sss')-datetime(FirstPacketDateTime{1})));
                        lastsample = firstsample+size(d.trial{1},2);
                        d.sampleinfo(1,:) = [firstsample lastsample];
                        d.trialinfo(1) = c;
                        d.hdr.label = d.label;
                        d.hdr.Fs = d.fsample;
                        
                        d.fname = [hdr.fname '_run-CT' char(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.sss','format','yyyyMMddhhmmss'))];
                        alldata{length(alldata)+1} = d;
                    end
                case 'SenseChannelTests'
                    
                    FirstPacketDateTime = strrep(strrep({data(:).FirstPacketDateTime},'T',' '),'Z','');
                    runs = unique(FirstPacketDateTime);
                    hdr.scd0=datetime(FirstPacketDateTime{1}(1:10));
                    Pass = {data(:).Pass};
                    tmp =  {data(:).GlobalSequences};
                    for c = 1:length(tmp)
                        GlobalSequences(c,:) = str2double(tmp{c});
                    end
                    tmp =  {data(:).GlobalPacketSizes};
                    for c = 1:length(tmp)
                        GlobalPacketSizes(c,:) = str2double(tmp{c});
                    end
                    raw = [data(:).TimeDomainData]';
                    fsample = data.SampleRateInHz;
                    gain=[data(:).Gain]';
                    [tmp1,tmp2] = strtok(strrep({data(:).Channel}','_AND',''),'_');
                    ch1 = strrep(strrep(strrep(strrep(tmp1,'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3');
                    
                    [tmp1,tmp2] = strtok(tmp2,'_');
                    ch2 = strrep(strrep(strrep(strrep(tmp1,'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3');
                    side = strrep(strrep(strtok(tmp2,'_'),'LEFT','L'),'RIGHT','R');
                    Channel = strcat(hdr.chan,'_',side,'_', ch1, ch2);
                    d=[];
                    for c = 1:length(runs)
                        i=perceive_ci(runs{c},FirstPacketDateTime);
                        d.hdr = hdr;
                        d.datatype = datafields{b};
                        d.hdr.IS.Pass=strrep(strrep(unique(strtok(Pass(i),'_')),'FIRST','1'),'SECOND','2');
                        d.hdr.IS.GlobalSequences=GlobalSequences(i,:);
                        d.hdr.IS.GlobalPacketSizes=GlobalPacketSizes(i,:);
                        d.hdr.IS.FirstPacketDateTime = runs{c};
                        tmp = raw(i,:);
                        d.trial{1} = [tmp];
                        d.label=Channel(i);
                        
                        d.time{1} = linspace(seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.sss')-hdr.scd0),seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.sss')-hdr.scd0)+size(d.trial{1},2)/fsample,size(d.trial{1},2));
                        d.fsample = fsample;
                        firstsample = 1+round(fsample*seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.sss')-datetime(FirstPacketDateTime{1})));
                        lastsample = firstsample+size(d.trial{1},2);
                        d.sampleinfo(1,:) = [firstsample lastsample];
                        d.trialinfo(1) = c;
                        
                        d.hdr.label = d.label;
                        d.hdr.Fs = d.fsample;
                        d.fname = [hdr.fname '_run-SCT' char(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.sss','format','yyyyMMddhhmmss'))];
                        alldata{length(alldata)+1} = d;
                    end
            end
            
            
            
        end
    end
    
    nfile = fullfile(hdr.fpath,[hdr.fname '.json']);
    copyfile(files{a},nfile)
    
    
    
    
    for b = 1:length(alldata)
        fullname = fullfile('.',hdr.fpath,alldata{b}.fname);
        data=alldata{b};
        disp(['WRITING ' fullname '.mat as FieldTrip file.'])
        save([fullname '.mat'],'data');
        if regexp(data.fname,'BSTD')
            fulldata = data;
            fulldata.fname = strrep(data.fname,'BSTD','BrainSense');
            
            bsl=load(strrep(fullname,'BSTD','BSL'));
            fulldata.BSLDateTime = [bsl.data.realtime(1) bsl.data.realtime(end)];
            fulldata.label(3:6) = bsl.data.label;
            fulldata.time{1}=fulldata.time{1}-fulldata.time{1}(1);
            otime = bsl.data.time{1}-bsl.data.time{1}(1);
            for c =1:4
                fulldata.trial{1}(c+2,:) = interp1(otime,bsl.data.trial{1}(c,:),fulldata.time{1},'nearest');
            end
           
            figure('Units','centimeters','PaperUnits','centimeters','Position',[1 1 40 20])
            subplot(2,2,1)
            yyaxis left
            plot(fulldata.time{1},fulldata.trial{1}(1,:))
             ylabel('Raw amplitude')
            pkfreq = bsl.data.hdr.BSL.TherapySnapshot.Left.FrequencyInHertz;
            hold on
            [tf,t,f]=perceive_raw_tf(fulldata.trial{1}(1,:),fulldata.fsample,128,.3);
            mpow=nanmean(tf(perceive_sc(f,pkfreq-4):perceive_sc(f,pkfreq+4),:));
            yyaxis right
            ylabel('LFP and STIM amplitude')
            plot(fulldata.time{1},fulldata.trial{1}(3,:))
            xlim([fulldata.time{1}(1),fulldata.time{1}(end)])
            hold on
            plot(fulldata.time{1},fulldata.trial{1}(5,:).*1000)
            plot(t,mpow.*1000)
            title(strrep({fulldata.fname,fulldata.label{3},fulldata.label{5}},'_',' '))
            axes('Position',[.34 .8 .1 .1])
            box off
            plot(f,nanmean(log(tf),2))
            xlabel('F')
            ylabel('P')
            xlim([3 40])

            axes('Position',[.16 .8 .1 .1])
            box off
            plot(fulldata.time{1},fulldata.trial{1}(1,:))
            xlabel('T'),ylabel('A')
            xlim([0 1.5])
           

            subplot(2,2,3)
            imagesc(t,f,log(tf)),axis xy, 
            xlabel('Time [s]')
            ylabel('Frequency [Hz]')
        
            
            subplot(2,2,2)
            yyaxis left
            plot(fulldata.time{1},fulldata.trial{1}(2,:))
             ylabel('Raw amplitude')
            pkfreq = bsl.data.hdr.BSL.TherapySnapshot.Right.FrequencyInHertz;
            hold on
            [tf,t,f]=perceive_raw_tf(fulldata.trial{1}(2,:),fulldata.fsample,fulldata.fsample,.5);
            mpow=nanmean(tf(perceive_sc(f,pkfreq-4):perceive_sc(f,pkfreq+4),:));
            yyaxis right
            ylabel('LFP and STIM amplitude')
            plot(fulldata.time{1},fulldata.trial{1}(4,:))
            xlim([fulldata.time{1}(1),fulldata.time{1}(end)])
            hold on
            plot(fulldata.time{1},fulldata.trial{1}(6,:).*1000)
            plot(t,mpow.*1000)
            title(strrep({fulldata.label{4},fulldata.label{6}},'_',' '))
            
            axes('Position',[.78 .8 .1 .1])
            box off
            plot(f,nanmean(log(tf),2))
            xlim([3 40])
            xlabel('F')
            ylabel('P')
            
            axes('Position',[.6 .8 .1 .1])
            box off
            plot(fulldata.time{1},fulldata.trial{1}(2,:))
            xlabel('T'),ylabel('A')
            xlim([0 1.5])
            
            subplot(2,2,4)
            imagesc(t,f,log(tf)),axis xy, 
            xlabel('Time [s]')
            ylabel('Frequency [Hz]')


            fullname = fullfile('.',hdr.fpath,fulldata.fname);
            perceive_print(fullname)
            data=fulldata;
            save([fullname '.mat'],'data')
        else
           perceive_plot_raw_signals(data);
           perceive_print(fullname);
           savefig([fullname '.fig'])
        end
        
    end
    close all
    
    
    hdr.DeviceInformation.Final.NeurostimulatorLocation
end



