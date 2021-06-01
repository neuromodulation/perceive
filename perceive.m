function perceive(files,subjectIDs,datafields)
% https://github.com/neuromodulation/perceive
% v0.1 Contributors Wolf-Julian Neumann, Tomas Sieger, Gerd Tinkhauser
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
%
% datafields:
% you can limit the output for each file to specific data fields in the
% json to only create the output that you need for your specific analysis.
% Currently supported datafields are:
% 'BrainSenseLfp',
% 'BrainSenseTimeDomain',
% 'CalibrationTests',
% 'DiagnosticData'
% 'EventSummary',
% 'Impedance',
% 'IndefiniteStreaming',
% 'LfpMontageTimeDomain',
% 'LFPMontage',
% 'MostRecentInSessionSignalCheck'
% 'PatientEvents'


%% OUTPUT
% The script generates BIDS inspired subject and session folders with the
% ieeg format specifier. All time series data are being exported as
% FieldTrip .mat files, as these require no additional dependencies for creation.
% You can reformat with FieldTrip and SPM to MNE
% python and other formats (e.g. using fieldtrip2fiff([fullname '.fif'],data))

%% Recording type output naming
% Each of the FieldTrip data files correspond to a specific aspect of the
% Recording session:
% LMTD = LFP Montage Time Domain - (BrainSenseSurvey on tablet)
% IS = Indefinite Streaming - BrainSenseStreaming
% CT = Calibration Testing - Calibration Tests
% BSL = BrainSense LFP (2 Hz power average + stimulation settings)
% BSTD = BrainSense Time Domain (250 Hz raw data corresponding to the BSL
% file)

%% TODO
% Add channel and stimulation information for chronic recordings


% shared options (and runtime settings)
% global popt;

% configure options
% popt = perceive_options();

if exist('datafields') && ischar(datafields)
    datafields = {datafields};
elseif exist('datafields','var') && isempty(datafields)
    clear datafields
end

if ~exist('files','var') || isempty(files)
    try
        files=perceive_ffind('*.json');
    catch
        files = [];
    end
    if isempty(files)
        [files,fpath] = uigetfile('*.json','Select .json file','MultiSelect','on');
        if isempty(files)
            return
        end
        files = strcat(fpath,files);
        
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
    try
        js.PatientInformation.Initial.PatientFirstName ='';
        js.PatientInformation.Initial.PatientLastName ='';
        js.PatientInformation.Initial.PatientDateOfBirth ='';
        js.PatientInformation.Final.PatientFirstName ='';
        js.PatientInformation.Final.PatientLastName ='';
        js.PatientInformation.Final.PatientDateOfBirth ='';
    catch
        js = rmfield(js,'PatientInformation');
        js.PatientInformation.Initial.PatientFirstName ='';
        js.PatientInformation.Initial.PatientLastName ='';
        js.PatientInformation.Initial.PatientDateOfBirth ='';
        js.PatientInformation.Initial.Diagnosis ='';
        js.PatientInformation.Final.PatientFirstName ='';
        js.PatientInformation.Final.PatientLastName ='';
        js.PatientInformation.Final.PatientDateOfBirth ='';
        js.PatientInformation.Final.Diagnosis = '';
    end
    
    
    infofields = perceive_data_fields('info');
    for b = 1:length(infofields)
        if isfield(js,infofields{b})
            hdr.(infofields{b})=js.(infofields{b});
        end
    end
    disp(js.DeviceInformation.Final.NeurostimulatorLocation)
    
    hdr.SessionEndDate = datetime(strrep(js.SessionEndDate(1:end-1),'T',' '));
    hdr.SessionDate = datetime(strrep(js.SessionDate(1:end-1),'T',' '));
    if ~isempty(js.PatientInformation.Final.Diagnosis)
        hdr.Diagnosis = strsplit(js.PatientInformation.Final.Diagnosis,'.');hdr.Diagnosis=hdr.Diagnosis{2};
    else
        hdr.Diagnosis = '';
    end
    
    hdr.OriginalFile = filename;
    hdr.ImplantDate = strrep(strrep(js.DeviceInformation.Final.ImplantDate(1:end-1),'T','_'),':','-');
    hdr.BatteryPercentage = js.BatteryInformation.BatteryPercentage;
    hdr.LeadLocation = strsplit(hdr.LeadConfiguration.Final(1).LeadLocation,'.');hdr.LeadLocation=upper(hdr.LeadLocation{2});
    hdr.ElectrodeModel = strrep({hdr.LeadConfiguration.Final.Model},'LeadModelDef.','');
    
    if ~exist('subjectIDs','var') || isempty(subjectIDs)
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
    
    hdr.chan = ['LFP' ];
    hdr.d0 = datetime(js.SessionDate(1:10));
    hdr.js = js;
    if ~exist('datafields','var')
        datafields = sort({'EventSummary','Impedance','MostRecentInSessionSignalCheck','BrainSenseLfp','BrainSenseTimeDomain','LfpMontageTimeDomain','IndefiniteStreaming','LFPMontage','CalibrationTests','PatientEvents','DiagnosticData'});
    end
    alldata = {};
    disp(['SUBJECT ' hdr.subject])
    LogTable = table({},{},{},{},{},{},{},{},{},{},'VariableNames',{'subjectID','SessionDate','SessionEndDate','DataField','DataDate','DataDuration','FileName','Comments','MetaFiles','SourceFile'});
    
    for b = 1:length(datafields)
        if isfield(js,datafields{b})
            data = js.(datafields{b});
            if isempty(data)
                continue
            end
            switch datafields{b}
                case 'Impedance'
                    %                  keyboard
                    T=table;
                    for c = 1:length(data.Hemisphere)
                        tmp=strsplit(data.Hemisphere(c).Hemisphere,'.');
                        side = tmp{2}(1);
                        %                         electrodes = unique([{data.Hemisphere(c).SessionImpedance.Monopolar.Electrode2} {data.Hemisphere(c).SessionImpedance.Monopolar.Electrode1}]);
                        e1 = strrep([{data.Hemisphere(c).SessionImpedance.Monopolar.Electrode1} {data.Hemisphere(c).SessionImpedance.Bipolar.Electrode1}],'ElectrodeDef.','') ;
                        e2 = [{data.Hemisphere(c).SessionImpedance.Monopolar.Electrode2} {data.Hemisphere(c).SessionImpedance.Bipolar.Electrode2}];
                        imp = [[data.Hemisphere(c).SessionImpedance.Monopolar.ResultValue] [data.Hemisphere(c).SessionImpedance.Bipolar.ResultValue]];
                        
                        for e = 1:length(imp)
                            if strcmp(e1{e},'Case')
                                e2_chan_id = strsplit(e2{e},'_');
                                T.([hdr.chan '_' side '_' e2_chan_id{2} '_' hdr.LeadLocation]) = imp(e);
                            else
                                e1_chan_id = strsplit(e1{e},'_');
                                e2_chan_id = strsplit(e2{e},'_');
                                T.([hdr.chan '_' side '_' e2_chan_id{2} e1_chan_id{2} '_' hdr.LeadLocation]) = imp(e);
                            end
                        end
                    end
                    
                    figure('visible','off')
                    barh(table2array(T(1,:))')
                    set(gca,'YTick',1:length(T.Properties.VariableNames),'YTickLabel',strrep(T.Properties.VariableNames,'_',' '))
                    xlabel('Impedance')
                    title(strrep({hdr.subject, hdr.session,'Impedances'},'_',' '))
                    perceive_print(fullfile(hdr.fpath,[hdr.fname '_run-Impedance']))
                    T = table(T{:,:}.','RowNames',T.Properties.VariableNames,'VariableNames',{'Impedance'});
                    writetable(T,fullfile(hdr.fpath,[hdr.fname '_run-Impedance.csv']));
                    LogTable(size(LogTable,1)+1,:) = {hdr.subject,char(hdr.SessionDate),char(hdr.SessionEndDate),datafields{b},'','',fullfile(hdr.fpath,[hdr.fname '_run-Impedance.csv']),'','',filename}
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
                            channels{c} = [hdr.chan '_' side '_' ch '_' hdr.LeadLocation];
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
                            %                             keyboard
                            LogTable(size(LogTable,1)+1,:) = {hdr.subject,char(hdr.SessionDate),char(hdr.SessionEndDate),'SignalCheck','','',fullfile(hdr.fpath,[hdr.fname '_run-MostRecentSignalCheckPowerSpectra.csv']),'','',filename}
                            
                        end
                        
                        T=array2table([freq';pow;rpow;lfit]','VariableNames',[{'Frequency'};strcat({'POW'},channels');strcat({'RPOW'},channels');strcat({'LFIT'},channels')]);
                        writetable(T,fullfile(hdr.fpath,[hdr.fname '_run-MostRecentSignalCheckPowerSpectra.csv']));
                        T=array2table(peaks','VariableNames',channels,'RowNames',{'PeakFrequency','PeakPower'});
                        writetable(T,fullfile(hdr.fpath,[hdr.fname '_run-MostRecentSignalCheck_Peaks.csv']));
                        
                        figure('Units','centimeters','PaperUnits','centimeters','Position',[1 1 40 20],'visible','off')
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
                        ylabel('Power spectral density [uV�/Hz]')
                        title(strrep({hdr.subject,char(hdr.SessionDate),'RIGHT'},'_',' '))
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
                        ylabel('Power spectral density [uV�/Hz]')
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
                        LFPL=[];STIML=[];DTL=datetime([],[],[]);
                        LFPR=[];STIMR=[];DTR=datetime([],[],[]);
                        if isfield(data.LFPTrendLogs,'HemisphereLocationDef_Left')
                            data.left=data.LFPTrendLogs.HemisphereLocationDef_Left;
                            runs = fieldnames(data.left);
                            for c=1:length(runs)
                                clfp = [data.left.(runs{c}).LFP];
                                if length(clfp)>1
                                    cstim = [data.left.(runs{c}).AmplitudeInMilliAmps];
                                    cdt = datetime({data.left.(runs{c}).DateTime},'InputFormat','yyyy-MM-dd''T''HH:mm:ss''Z''','Format','yyyy-MM-dd hh:mm:ss');
                                    [cdt,i] = sort(cdt);
                                    LFPL=[LFPL,clfp(i)];
                                    STIML=[STIML,cstim(i)];
                                    DTL=[DTL,cdt];
                                    
                                    d=[];
                                    d.hdr = hdr;d.datatype = 'DiagnosticData.LFPTrends';
                                    d.fsample = 0.00166666666;
                                    d.trial{1} = [clfp(i);cstim(i)];
                                    d.label = {'LFP_LEFT','STIM_LEFT'};
                                    d.time{1} = linspace(seconds(cdt(1)-hdr.d0),seconds(cdt(end)-hdr.d0),size(d.trial{1},2));
                                    d.realtime{1} = cdt;
                                    d.fsample = abs(1/diff(d.time{1}(1:2)));d.hdr.Fs = d.fsample; d.hdr.label = d.label;
                                    firstsample = d.time{1}(1); lastsample = d.time{1}(end);d.sampleinfo(1,:) = [firstsample lastsample];
                                    d.fname = [hdr.fname '_run-ChronicLeft' char(datetime(cdt(1),'format','yyyyMMddhhmmss'))];
                                    d.keepfig = false; % do not keep figure with this signal open (the number of LFPTrendLogs can be high)
                                    alldata{length(alldata)+1} = d;
                                    
                                    LogTable(size(LogTable,1)+1,:) = {hdr.subject,char(hdr.SessionDate),char(hdr.SessionEndDate),'ChronicLeft',char(datetime(cdt(1),'Format','yyyy-MM-dd hh:mm:ss')),char(cdt(end)-cdt(1)),[d.fname '.mat'],'','',filename}
                                end
                            end
                        end
                        
                        
                        
                        if isfield(data.LFPTrendLogs,'HemisphereLocationDef_Right')
                            data.right=data.LFPTrendLogs.HemisphereLocationDef_Right;
                            runs = fieldnames(data.right);
                            for c=1:length(runs)
                                clfp = [data.right.(runs{c}).LFP];
                                cstim = [data.right.(runs{c}).AmplitudeInMilliAmps];
                                cdt = datetime({data.right.(runs{c}).DateTime},'InputFormat','yyyy-MM-dd''T''HH:mm:ss''Z''','Format','yyyy-MM-dd hh:mm:ss');
                                
                                [cdt,i] = sort(cdt);
                                LFPR=[LFPR,clfp(i)];
                                STIMR=[STIMR,cstim(i)];
                                DTR=[DTR,cdt];
                                
                                
                                d=[];
                                d.hdr = hdr;d.datatype = 'DiagnosticData_LFPTrends';
                                d.trial{1} = [clfp;cstim];
                                d.label = {'LFP_RIGHT','STIM_RIGHT'};
                                d.time{1} = linspace(seconds(cdt(1)-hdr.d0),seconds(cdt(end)-hdr.d0),size(d.trial{1},2));
                                d.realtime{1} = cdt;
                                d.fsample = abs(1/diff(d.time{1}(1:2)));d.hdr.Fs = d.fsample; d.hdr.label = d.label;
                                firstsample = d.time{1}(1); lastsample = d.time{1}(end);d.sampleinfo(1,:) = [firstsample lastsample];
                                d.fname = [hdr.fname '_run-ChronicRight' char(datetime(cdt(1),'format','yyyyMMddhhmmss'))];
                                alldata{length(alldata)+1} = d;
                                LogTable(size(LogTable,1)+1,:) = {hdr.subject,char(hdr.SessionDate),char(hdr.SessionEndDate),'ChronicRight',char(datetime(cdt(1),'Format','yyyy-MM-dd hh:mm:ss')),char(cdt(end)-cdt(1)),[d.fname '.mat'],'','',filename}
                                
                            end
                        else
                            keyboard % create table with events
                        end
                        
                        
                        LFP=[];
                        STIM=[];
                        DT=sort([DTL,setdiff(DTR,DTL)]);
                        for c = 1:length(DT)
                            if ismember(DT(c),DTL)
                                i = find(DTL==DT(c));
                                LFP(1,c) = LFPL(i);
                                STIM(1,c) = STIML(i);
                            else
                                LFP(1,c) = nan;
                                STIM(1,c) = nan;
                            end
                            if ismember(DT(c),DTR)
                                i = find(DTR==DT(c));
                                LFP(2,c) = LFPR(i);
                                STIM(2,c) = STIMR(i);
                            else
                                LFP(2,c) = nan;
                                STIM(2,c) = nan;
                            end
                        end
                        d=[];
                        d.hdr = hdr;
                        d.datatype = 'DiagnosticData_LFPTrends';
                        d.trial{1} = [LFP;STIM];
                        d.label = {'LFP_LEFT','LFP_RIGHT','STIM_LEFT','STIM_RIGHT'};
                        d.time{1} = DT;
                        d.fsample = diff(DT);
                        firstsample = d.time{1}(1);
                        lastsample = d.time{1}(end);
                        d.sampleinfo(1,:) = [firstsample lastsample];
                        d.fname = [hdr.fname '_run-CHRONIC' char(datetime(DT(1),'format','yyyyMMddhhmmss'))];
                        alldata{length(alldata)+1} = d;
                        
                        
                        figure('Units','centimeters','PaperUnits','centimeters','Position',[1 1 40 20],'visible','off')
                        subplot(2,1,1)
                        title({strrep(hdr.fname,'_',' '),'CHRONIC LEFT'})
                        yyaxis left
                        
                        scatter(DT,LFP(1,:),20,'filled','Marker','o')
                        ylabel('LFP Amplitude')
                        yyaxis right
                        scatter(DT,STIM(1,:),20,'filled','Marker','s')
                        ylabel('STIM Amplitude')
                        xlabel('Time')
                        subplot(2,1,2)
                        yyaxis left
                        scatter(DT,LFP(2,:),20,'filled','Marker','o')
                        ylabel('LFP Amplitude')
                        yyaxis right
                        scatter(DT,STIM(2,:),20,'filled','Marker','s')
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
                                DT(c) = datetime(lfp.DateTime(1:end-1),'InputFormat','yyyy-MM-dd''T''HH:mm:ss','Format','yyyy-MM-dd hh:mm:ss');
                                events{c} = lfp.EventName;
                                if isfield(lfp.LfpFrequencySnapshotEvents,'HemisphereLocationDef_Left') && ~isempty(lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Left.SenseID)
                                    tmp = strsplit(strrep(lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Left.SenseID,'_AND',''),'.');
                                    ch1 = strcat(hdr.chan,'_L_',strrep(strrep(strrep(strrep(strrep(tmp{2},'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3'),'_',''),'_',hdr.LeadLocation);
                                else
                                    ch1 = 'na';
                                end
                                if isfield(lfp.LfpFrequencySnapshotEvents,'HemisphereLocationDef_Right') && ~isempty(lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Right.SenseID)
                                    tmp = strsplit(strrep(lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Right.SenseID,'_AND',''),'.');
                                    ch2 = strcat(hdr.chan,'_R_',strrep(strrep(strrep(strrep(strrep(tmp{2},'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3'),'_',''),'_',hdr.LeadLocation);
                                else
                                    ch2 = 'na';
                                end
                                chanlabels{c} = {ch1 ch2};
                                if ~isfield(lfp.LfpFrequencySnapshotEvents,'HemisphereLocationDef_Left') && ~isfield(lfp.LfpFrequencySnapshotEvents,'HemisphereLocationDef_Right')
                                    error('none of HemisphereLocationDef_Left / HemisphereLocationDef_Right appear in LfpFrequencySnapshotEvents');
                                end
                                if isfield(lfp.LfpFrequencySnapshotEvents,'HemisphereLocationDef_Left')
                                    stimgroups{c} = lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Left.GroupId(end);
                                    freq = lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Left.Frequency;
                                else
                                    stimgroups{c} = lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Right.GroupId(end);
                                    freq = lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Right.Frequency;
                                end
                                if isfield(lfp.LfpFrequencySnapshotEvents,'HemisphereLocationDef_Left') && isfield(lfp.LfpFrequencySnapshotEvents,'HemisphereLocationDef_Right')
                                    pow(:,1) = lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Left.FFTBinData;
                                    pow(:,2) = lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Right.FFTBinData;
                                else
                                    if isfield(lfp.LfpFrequencySnapshotEvents,'HemisphereLocationDef_Left')
                                        pow(:,1) = lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Left.FFTBinData;
                                        pow(:,2) = 0*pow(:,1);
                                    else
                                        pow(:,2) = lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Right.FFTBinData;
                                        pow(:,1) = 0*pow(:,2);
                                    end
                                end
                                Tpow.Frequency = freq;
                                Tpow.(strrep([events{c} '_' num2str(c) '_' ch1 '_' char(datetime(DT(c),'Format','yyyMMddHHmmss'))],' ','')) = pow(:,1);
                                Tpow.(strrep([events{c} '_' num2str(c) '_' ch2 '_' char(datetime(DT(c),'Format','yyyMMddHHmmss'))],' ','')) = pow(:,2);
                                
                                
                                figure('visible','off')
                                plot(freq,pow,'linewidth',2)
                                legend(strrep(chanlabels{c},'_',' '))
                                title({strrep(hdr.fname,'_',' ');char(DT(c));events{c};['STIM GROUP ' stimgroups{c}]})
                                xlabel('Frequency [Hz]')
                                ylabel('Power spectral density [uV^2/Hz]')
                                savefig(fullfile(hdr.fpath,[hdr.fname '_LFPSnapshot_' events{c} '-' num2str(c) '.fig']))
                                perceive_print(fullfile(hdr.fpath,[hdr.fname '_LFPSnapshot_' events{c} '-' num2str(c)]))
                                
                            else
                                % keyboard
                                warning('LFP Snapshot Event without LFP data present.')
                            end
                            
                            if isstruct(cdata(c)) && c <= length(DT)
                                LogTable(size(LogTable,1)+1,:) = {hdr.subject,char(hdr.SessionDate),char(hdr.SessionEndDate),['LFPSnapshot: ' cdata(c).EventName],char(datetime(DT(c),'Format','yyyy-MM-dd hh:mm:ss')),'',fullfile(hdr.fpath,[hdr.fname '_LFPSnapshotEvents.csv']),'','',filename}
                            elseif c <= length(DT)
                                LogTable(size(LogTable,1)+1,:) = {hdr.subject,char(hdr.SessionDate),char(hdr.SessionEndDate),['LFPSnapshot: ' cdata{c}.EventName],char(datetime(DT(c),'Format','yyyy-MM-dd hh:mm:ss')),'',fullfile(hdr.fpath,[hdr.fname '_LFPSnapshotEvents.csv']),'','',filename}
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
                    Channel = strcat(hdr.chan,'_',side,'_', ch1, ch2,'_',hdr.LeadLocation);
                    d=[];
                    for c = 1:length(runs)
                        i=perceive_ci(runs{c},FirstPacketDateTime);
                        try
                            raw=[data(i).TimeDomainData]';
                        catch unmatched_samples
                            for xi=1:length(i)
                                sl(xi)=length(data(i(xi)).TimeDomainData);
                            end
                            smin=min(sl);
                            raw=[];
                            for xi = 1:length(xi)
                                raw(xi,:) = data(i(xi)).TimeDomainData(1:smin);
                            end
                            warning('Sample size differed between channels. Check session affiliation.')
                        end
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
                        
                        d.ecg=[];
                        d.ecg_cleaned=[];
                        for e = 1:size(raw,1)
                            d.ecg{e} = perceive_ecg(raw(e,:));
                            title(strrep(d.label{e},'_',' '))
                            xlabel(strrep(d.fname,'_',' '))
                            savefig(fullfile(hdr.fpath,[d.fname '_ECG_' d.label{e} '.fig']))
                            perceive_print(fullfile(hdr.fpath,[d.fname '_ECG_' d.label{e}]))
                            d.ecg_cleaned(e,:) = d.ecg{e}.cleandata;
                        end
                        alldata{length(alldata)+1} = d;
                        %                         keyboard
                        LogTable(size(LogTable,1)+1,:) = {hdr.subject,char(hdr.SessionDate),char(hdr.SessionEndDate),datafields{b},char(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.sss','Format','yyyy-MM-dd HH:mm:ss')),char(duration(seconds(d.time{1}(end)-d.time{1}(1)),'Format','hh:mm:ss')),[d.fname '.mat'],'','',filename}
                        
                    end
                case 'BrainSenseLfp'
                    
                    FirstPacketDateTime = strrep(strrep({data(:).FirstPacketDateTime},'T',' '),'Z','');
                    runs = unique(FirstPacketDateTime);
                    bsldata=[];bsltime=[];bslchannels=[];
                    figure('Units','centimeters','PaperUnits','centimeters','Position',[1 1 40 20],'visible','off')
                    for c=1:length(runs)
                        cdata = data(c);
                        tmp = strrep(cdata.Channel,'_AND','');
                        tmp = strsplit(strrep(strrep(strrep(strrep(strrep(tmp,'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3'),'_',''),',');
                        %                         keyboard
                        if length(tmp)==2
                            lfpchannels = {[hdr.chan '_' tmp{1}(3) '_' tmp{1}(1:2) '_' hdr.LeadLocation], ...
                                [hdr.chan '_' tmp{2}(3) '_' tmp{2}(1:2)]};
                        else
                            if length(tmp)==1
                                lfpchannels = {[hdr.chan '_' tmp{1}(3) '_' tmp{1}(1:2) '_' hdr.LeadLocation ]};
                            else
                                error(['unsupported number of ' num2str(length(tmp)) 'sides in BrainSenseLfp']);
                            end
                        end
                        d=[];
                        d.hdr = hdr;
                        d.hdr.BSL.TherapySnapshot = cdata.TherapySnapshot;
                        if isfield(d.hdr.BSL.TherapySnapshot,'Left')
                            tmp = d.hdr.BSL.TherapySnapshot.Left;
                            lfpsettings{1,1} = ['PEAK' num2str(round(tmp.FrequencyInHertz)) 'Hz_THR' num2str(tmp.LowerLfpThreshold) '-' num2str(tmp.UpperLfpThreshold) '_AVG' num2str(round(tmp.AveragingDurationInMilliSeconds)) 'ms'];
                            stimchannels = ['STIM_L_' num2str(tmp.RateInHertz) 'Hz_' num2str(tmp.PulseWidthInMicroSecond) 'us'];
                        else
                            lfpsettings{1,1}='LFP n/a';
                            stimchannels = 'STIM n/a';
                        end
                        if isfield(d.hdr.BSL.TherapySnapshot,'Right')
                            tmp = d.hdr.BSL.TherapySnapshot.Right;
                            lfpsettings{2,1} = ['PEAK' num2str(round(tmp.FrequencyInHertz)) 'Hz_THR' num2str(tmp.LowerLfpThreshold) '-' num2str(tmp.UpperLfpThreshold) '_AVG' num2str(round(tmp.AveragingDurationInMilliSeconds)) 'ms'];
                            stimchannels = {stimchannels,['STIM_R_' num2str(tmp.RateInHertz) 'Hz_' num2str(tmp.PulseWidthInMicroSecond) 'us']};
                        else
                            lfpsettings{2,1} = 'LFP n/a';
                            stimchannels = {stimchannels,'STIM n/a'};
                        end
                        
                        d.label = [strcat(lfpchannels','_',lfpsettings)' stimchannels];
                        d.hdr.label = d.label;
                        
                        d.fsample = cdata.SampleRateInHz;
                        d.hdr.Fs = d.fsample;
                        tstart = cdata.LfpData(1).TicksInMs/1000;
                        for e =1:length(cdata.LfpData)
                            d.trial{1}(1:2,e) = [cdata.LfpData(e).Left.LFP;cdata.LfpData(e).Right.LFP];
                            d.trial{1}(3:4,e) = [cdata.LfpData(e).Left.mA;cdata.LfpData(e).Right.mA];
                            d.time{1}(e) = seconds(datetime(runs{c},'InputFormat','yyyy-MM-dd HH:mm:ss.SSS')-hdr.d0)+((cdata.LfpData(e).TicksInMs/1000)-tstart);
                            d.realtime(e) = datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS','Format','yyyy-MM-dd HH:mm:ss.SSS')+seconds((d.time{1}(e)-d.time{1}(1)));
                            d.hdr.BSL.seq(e)= cdata.LfpData(e).Seq;
                        end
                        
                        d.trialinfo(1) = c;
                        d.hdr.realtime = d.realtime;
                        
                        
                        d.fname = [hdr.fname '_run-BSL' char(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.sss','format','yyyyMMddhhmmss'))];
                        figure('visible','off')
                        subplot(2,1,1)
                        yyaxis left
                        lp=plot(d.realtime,d.trial{1}(1,:),'linewidth',2);
                        ylabel('LFP Amplitude')
                        yyaxis right
                        sp=plot(d.realtime,d.trial{1}(3,:),'linewidth',2,'linestyle','--');
                        title(strrep(strrep(d.fname,'_','-'),'_',' '))
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
                        legend([lp sp],strrep(d.label([2 4]),'_',' '),'location','northoutside')
                        xlabel('Time')
                        xlim([d.realtime(1) d.realtime(end)])
                        
                        
                        bsldata = [bsldata,d.trial{1}];
                        bsltime = [bsltime,d.realtime];
                        bslchannels = d.label;
                        alldata{length(alldata)+1} = d;
                        
                        savefig(fullfile(hdr.fpath,[d.fname '.fig']))
                        perceive_print(fullfile(hdr.fpath,[d.fname]))
                        LogTable(size(LogTable,1)+1,:) = {hdr.subject,char(hdr.SessionDate),char(hdr.SessionEndDate),datafields{b},char(datetime(d.realtime(1),'Format','yyyy-MM-dd hh:mm:ss')),char(d.realtime(end)-d.realtime(1)),fullfile(hdr.fpath,[hdr.fname '_run-BrainSenseLFP.csv']),'','',filename}
                        
                        
                    end
                    T=table;
                    T.Time = bsltime';
                    for c = 1:length(bslchannels)
                        try
                            T.(bslchannels{c}) = bsldata(c,:)';
                        catch
                            T.(strrep(bslchannels{c},'-','_')) = bsldata(c,:)';
                        end
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
                    %                     [tmp1,tmp2] = strtok(strrep({data(:).Channel}','_AND',''),'_');
                    tmp = {data(:).Channel};
                    for c = 1:length(tmp)
                        
                        if sum(ismember('_LEFT_',tmp{c}))==6
                            side = 'L';
                            iside = 1;
                            tmp1 = strsplit(tmp{c},'_LEFT')
                        else
                            side = 'R';
                            tmp1=strsplit(tmp{c},'_RIGHT')
                            iside=2;
                        end
                        
                        tmp1=strsplit(tmp1{1},'_AND_');
                        
                        if numel(tmp1)==1
                            tmp1 = strsplit(tmp1{1},'_');
                        end
                        ch1 = strrep(strrep(strrep(strrep(strrep(tmp1{1},'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3'),'_','');
                        ch2 = strrep(strrep(strrep(strrep(strrep(tmp1{2},'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3'),'_','');
                        
                        
                        
                        %                         keyboard
                        Channel{c} = strcat(hdr.chan,'_', side, '_', ch1,ch2, '_', hdr.LeadLocation);
                    end
                    d=[];
                    for c = 1:length(runs)
                        i=perceive_ci(runs{c},FirstPacketDateTime);
                        d=[];
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
                        firstsample = 1+round(fsample*seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.sss')-datetime(FirstPacketDateTime{1},'Inputformat','yyyy-MM-dd HH:mm:ss.sss')));
                        lastsample = firstsample+size(d.trial{1},2);
                        d.sampleinfo(1,:) = [firstsample lastsample];
                        d.trialinfo(1) = c;
                        
                        d.hdr.label = d.label;
                        d.hdr.Fs = d.fsample;
                        d.fname = [hdr.fname '_run-LMTD' char(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.sss','format','yyyyMMddhhmmss'))];
                        alldata{length(alldata)+1} = d;
                        LogTable(size(LogTable,1)+1,:) = {hdr.subject,char(hdr.SessionDate),char(hdr.SessionEndDate),datafields{b},char(datetime(runs{c},'format','yyyy-MM-dd hh:mm:ss')),char(duration(seconds(d.time{1}(end)-d.time{1}(1)),'Format','hh:mm:ss')),[d.fname '.mat'],'','',filename}
                        %                         keyboard
                    end
                case 'LFPMontage'
                    
                    channels={};
                    pow=[];rpow=[];lfit=[];bad=[];peaks=[];
                    for c = 1:length(data)
                        cdata = data(c);
                        if iscell(cdata)
                            cdata=cdata{1};
                        end
                        tmp=strsplit(cdata.Hemisphere,'.');
                        side=tmp{2}(1);
                        tmp=strsplit(cdata.SensingElectrodes,'.');tmp=strrep(strrep(tmp{2},'_AND_',''),'_','');
                        ch = strrep(strrep(strrep(strrep(tmp,'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3');
                        channels{c} = [hdr.chan '_' side '_' ch '_' hdr.LeadLocation];
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
                    
                    figure('Units','centimeters','PaperUnits','centimeters','Position',[1 1 40 20],'visible','off')
                    
                    ir = perceive_ci([hdr.chan '_R'],channels);
                    subplot(1,2,2)
                    if ~isempty(ir)
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
                        title(strrep({hdr.subject,char(hdr.SessionDate),'RIGHT'},'_',' '))
                        legend(strrep(channels(ir),'_',' '))
                    else
                        title('RIGHT HEMISPHERE MISSING')
                        axis off
                    end
                    il = perceive_ci([hdr.chan '_L'],channels);
                    
                    subplot(1,2,1)
                    if ~isempty(il)
                        p=plot(freq,pow(il,:));
                        set(p(find(bad(il))),'linestyle','--')
                        hold on
                        plot(freq,nanmean(pow(il,:)),'color','k','linewidth',2)
                        
                        xlim([1 35])
                        title(strrep({hdr.subject,char(hdr.SessionDate),'LEFT'},'_',' '))
                        plot(peaks(il,1),peaks(il,2),'LineStyle','none','Marker','.','MarkerSize',12)
                        xlabel('Frequency [Hz]')
                        ylabel('Power spectral density [uV^2/Hz]')
                        for c = 1:length(il)
                            if peaks(il(c),1)>0
                                text(peaks(il(c),1),peaks(il(c),2),[' ' num2str(peaks(il(c),1),3) ' Hz'])
                            end
                        end
                        legend(strrep(channels(il),'_',' '))
                    else
                        title('LEFT HEMISPHERE MISSING')
                        axis off
                    end
                    set(gcf,'visible','on')
                    savefig(fullfile(hdr.fpath,[hdr.fname '_run-LFPMontage.fig']))
                    pause(2)
                    perceive_print(fullfile(hdr.fpath,[hdr.fname '_run-LFPMontage']))
                    close
                    LogTable(size(LogTable,1)+1,:) = {hdr.subject,char(hdr.SessionDate),char(hdr.SessionEndDate),datafields{b},'','',fullfile(hdr.fpath,[hdr.fname '_run-LFPMontagePowerSpectra.csv']),'','',filename}
                    
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
                    Channel = strcat(hdr.chan,'_',side,'_', ch1, ch2,'_',hdr.LeadLocation);
                    d=[];
                    for c = 1:length(runs)
                        i=perceive_ci(runs{c},FirstPacketDateTime);
                        d=[];
                        d.hdr = hdr;
                        d.datatype = datafields{b};
                        d.hdr.IS.Pass=strrep(strrep(unique(strtok(Pass(i),'_')),'FIRST','1'),'SECOND','2');
                        d.hdr.IS.GlobalSequences=GlobalSequences(i,:);
                        d.hdr.IS.GlobalPacketSizes=GlobalPacketSizes(i,:);
                        d.hdr.IS.FirstPacketDateTime = runs{c};
                        tmp =  [data(i).TimeDomainData]';
                        xchans = perceive_ci({'L_03','L_13','L_02','R_03','R_13','R_02'},Channel(i));
                        nchans = {'L_01','L_12','L_23','R_01','R_12','R_23'};
                        refraw = [tmp(xchans(1),:)-tmp(xchans(2),:);(tmp(xchans(1),:)-tmp(xchans(2),:))-tmp(xchans(3),:);tmp(xchans(3),:)-tmp(xchans(1),:);
                            tmp(xchans(4),:)-tmp(xchans(5),:);(tmp(xchans(4),:)-tmp(xchans(5),:))-tmp(xchans(6),:);tmp(xchans(6),:)-tmp(xchans(4),:)];
                        d.trial{1} = [refraw;tmp];
                        d.label=[Channel(i);strcat(hdr.chan,'_',nchans','_',hdr.LeadLocation)];
                        
                        d.time{1} = linspace(seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.sss')-hdr.d0),seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.sss')-hdr.d0)+size(d.trial{1},2)/fsample,size(d.trial{1},2));
                        d.fsample = fsample;
                        firstsample = 1+round(fsample*seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.sss')-datetime(FirstPacketDateTime{1},'Inputformat','yyyy-MM-dd HH:mm:ss.sss')));
                        lastsample = firstsample+size(d.trial{1},2);
                        d.sampleinfo(1,:) = [firstsample lastsample];
                        d.trialinfo(1) = c;
                        d.hdr.label=d.label;
                        d.hdr.Fs = d.fsample;
                        
                        d.fname = [hdr.fname '_run-IS' char(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.sss','format','yyyyMMddhhmmss'))];
                        alldata{length(alldata)+1} = d;
                        LogTable(size(LogTable,1)+1,:) = {hdr.subject,char(hdr.SessionDate),char(hdr.SessionEndDate),datafields{b},char(datetime(FirstPacketDateTime{1},'Inputformat','yyyy-MM-dd HH:mm:ss.sss','format','yyyy-MM-dd hh:mm:ss')),char(duration(seconds(d.time{1}(end)-d.time{1}(1)),'Format','hh:mm:ss')),[d.fname '.mat'],'','',filename}
                        
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
                    
                    figure('visible','off')
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
                    title(strrep({hdr.subject,hdr.session,'All CalibrationTests'},'_',' '))
                    savefig(fullfile(hdr.fpath,[hdr.fname '_run-AllCalibrationTests.fig']))
                    perceive_print(fullfile(hdr.fpath,[hdr.fname '_run-AllCalibrationTests']))
                    
                    
                    for c = 1:length(runs)
                        d=[];
                        
                        i=perceive_ci(runs{c},FirstPacketDateTime);
                        raw=[data(i).TimeDomainData]';
                        d=[];
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
                        firstsample = 1+round(fsample*seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.sss')-datetime(FirstPacketDateTime{1},'Inputformat','yyyy-MM-dd HH:mm:ss.sss')));
                        lastsample = firstsample+size(d.trial{1},2);
                        d.sampleinfo(1,:) = [firstsample lastsample];
                        d.trialinfo(1) = c;
                        d.hdr.label = d.label;
                        d.hdr.Fs = d.fsample;
                        
                        d.fname = [hdr.fname '_run-CT' num2str(c) char(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.sss','format','yyyyMMddhhmmss'))];
                        alldata{length(alldata)+1} = d;
                        LogTable(size(LogTable,1)+1,:) = {hdr.subject,char(hdr.SessionDate),char(hdr.SessionEndDate),datafields{b},char(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.sss','format','yyyy-MM-dd hh:mm:ss')),char(duration(seconds(d.time{1}(end)-d.time{1}(1)),'Format','hh:mm:ss')),[d.fname '.mat'],'','',filename}
                        
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
                    for c = 1:length(runs)
                        i=perceive_ci(runs{c},FirstPacketDateTime);
                        d=[];
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
                        firstsample = 1+round(fsample*seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.sss')-datetime(FirstPacketDateTime{1},'Inputformat','yyyy-MM-dd HH:mm:ss.sss')));
                        lastsample = firstsample+size(d.trial{1},2);
                        d.sampleinfo(1,:) = [firstsample lastsample];
                        d.trialinfo(1) = c;
                        
                        d.hdr.label = d.label;
                        d.hdr.Fs = d.fsample;
                        d.fname = [hdr.fname '_run-SCT' char(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.sss','format','yyyyMMddhhmmss'))];
                        alldata{length(alldata)+1} = d;
                        keyboard % LOG missing    LogTable(size(LogTable,1)+1,:) = {hdr.subject,char(hdr.SessionDate),char(hdr.SessionEndDate),datafields{b},'','',fullfile(hdr.fpath,[hdr.fname '_run-Impedance.csv']),'','',filename}
                        
                    end
            end
            
            
            
        end
    end
    
    nfile = fullfile(hdr.fpath,[hdr.fname '.jsoncopy']);
    copyfile(files{a},nfile)
    
    
    
    
    for b = 1:length(alldata)
        fullname = fullfile('.',hdr.fpath,alldata{b}.fname);
        data=alldata{b};
        disp(['WRITING ' fullname '.mat as FieldTrip file.'])
        save([fullname '.mat'],'data');
        if regexp(data.fname,'BSTD')
            fulldata = data;
            fulldata.fname = strrep(data.fname,'BSTD','BrainSense');
            bslfile = strrep(fullname,'BSTD','BSL');
            
            try
                bsl=load(bslfile);
            catch
                [x,x,bslfile] = perceive_ffind([bslfile(1:end-3) '*.mat']);
                bslfile = bslfile{1};
                bsl=load(bslfile);
            end
            fulldata.BSLDateTime = [bsl.data.realtime(1) bsl.data.realtime(end)];
            fulldata.label(3:6) = bsl.data.label;
            fulldata.time{1}=fulldata.time{1};
            otime = bsl.data.time{1};
            for c =1:4
                fulldata.trial{1}(c+2,:) = interp1(otime-otime(1),bsl.data.trial{1}(c,:),fulldata.time{1}-fulldata.time{1}(1),'nearest');
            end
            if size(fulldata.trial{1},2) > 1000
                figure('Units','centimeters','PaperUnits','centimeters','Position',[1 1 40 20],'visible','off')
                subplot(2,2,1)
                yyaxis left
                plot(fulldata.time{1},fulldata.trial{1}(1,:))
                ylabel('Raw amplitude')
                if isfield(bsl.data.hdr.BSL.TherapySnapshot,'Left')
                    pkfreq = bsl.data.hdr.BSL.TherapySnapshot.Left.FrequencyInHertz;
                    pkfreq = bsl.data.hdr.BSL.TherapySnapshot.Left.FrequencyInHertz;
                elseif isfield(bsl.data.hdr.BSL.TherapySnapshot,'Right')
                    pkfreq = bsl.data.hdr.BSL.TherapySnapshot.Right.FrequencyInHertz;
                else
                    error('neither Left nor Right TherapySnapshot present');
                end
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
                xx = randi(round([fulldata.time{1}(1),fulldata.time{1}(end)]),1);
                xlim([xx xx+1.5])
                
                
                subplot(2,2,3)
                imagesc(t,f,log(tf)),axis xy,
                xlabel('Time [s]')
                ylabel('Frequency [Hz]')
                
                
                subplot(2,2,2)
                yyaxis left
                plot(fulldata.time{1},fulldata.trial{1}(2,:))
                ylabel('Raw amplitude')
                if isfield(bsl.data.hdr.BSL.TherapySnapshot,'Right')
                    pkfreq = bsl.data.hdr.BSL.TherapySnapshot.Right.FrequencyInHertz;
                elseif isfield(bsl.data.hdr.BSL.TherapySnapshot,'Left')
                    pkfreq = bsl.data.hdr.BSL.TherapySnapshot.Left.FrequencyInHertz;
                else
                    error('neither Left nor Right TherapySnapshot present');
                end
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
                xlim([xx xx+1.5])
                
                
                subplot(2,2,4)
                imagesc(t,f,log(tf)),axis xy,
                xlabel('Time [s]')
                ylabel('Frequency [Hz]')
                fullname = fullfile('.',hdr.fpath,fulldata.fname);
                perceive_print(fullname)
                
                
                
                % close the figure if should not be kept open
                if isfield(fulldata,'keepfig')
                    if ~fulldata.keepfig
                        close();
                    end
                    fulldata=rmfield(fulldata,'keepfig');
                end
                data=fulldata;
                save([fullname '.mat'],'data')
            else
                warning('Data shorter than 4 sec are ignored by perceive.')
            end
        else
            figure('visible','off')
            perceive_plot_raw_signals(data);
            perceive_print(fullname);
            savefig([fullname '.fig'])
            close
            % close the figure if should not be kept open
            if isfield(data,'keepfig')
                if ~data.keepfig
                    close();
                end
            end
        end
        
    end
    close all
    [~,i] = sort(LogTable.DataDate);
    writetable(LogTable(i,:),fullfile(hdr.fpath(1:end-5),[hdr.subject '_' hdr.session '_LogTable.csv']))
    if a==1
        MasterTable = LogTable(i,:);
    else
        MasterTable = [MasterTable;LogTable(i,:)];
    end
    
end
disp(MasterTable)
writetable(MasterTable,fullfile(hdr.subject,['Perceive_MasterTable_' char(datetime(now,'ConvertFrom','datenum','Format','yyyy-MM-dd_hh-mm-ss')) '.csv']))




