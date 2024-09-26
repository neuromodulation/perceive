function perceive(files, sub, sesMedOffOn01, extended)
% https://github.com/neuromodulation/perceive
% Toolbox by Wolf-Julian Neumann
% v1.0 update by J Vanhoecke
% Merge requests from Jennifer Behnke and Mansoureh Fahimi
% Contributors Wolf-Julian Neumann, Tomas Sieger, Gerd Tinkhauser
% This is an open research tool that is not intended for clinical purposes.
%
% INPUT:
% file          ["", 'Report_Json_Session_Report_20200115T123657.json', {'Report_Json_Session_Report_20200115T123657.json','Report_Json_Session_Report_20200115T123658.json'}, ...]
% sub           ["", 7, 21 , "021", ... ]
% sesMedOffOn01 ["","MedOff01","MedOn01","MedOff02","MedOn02","MedOff03","MedOn03","MedOffOn01"]
% extended      ["","yes"] %% gives an extensive output of chronic, calibration, lastsignalcheck, diagnostic, impedance and snapshot data
%% INPUT
arguments
    files {mustBeA(files,["char","cell"])} = '';
    % files:
    % All input is optional, you can specify files as cell or character array
    % (e.g. files = 'Report_Json_Session_Report_20200115T123657.json')
    % if files isn't specified or remains empty, it will automatically include
    % all files in the current working directory
    % if no files in the current working directory are found, a you can choose
    % files via the MATLAB uigetdir window.
    sub {mustBeA(sub,["char","cell","numeric"])} = '';
    % sub:
    % you can specify a subject ID for each file in case you want to follow an
    % IRB approved naming scheme for file export
    % (e.g. run perceive('Report_Json_Session_Report_20200115T123657.json','Charite_sub-001')
    % if unspecified or left empy, the subjectID will be created from:
    % ImplantDate, first letter of disease type and target (e.g. sub-2020110DGpi)
    sesMedOffOn01 {mustBeMember(sesMedOffOn01,["","MedOff01","MedOn01","MedOff02","MedOn02","MedOff03","MedOn03","MedOffOn01"])} = '';
    %task = 'TASK'; %All types of tasks: Rest, RestTap, FingerTapL, FingerTapR, UPDRS, MovArtArms,MovArtStand,MovArtHead,MovArtWalk
    %acq = ''; %StimOff, StimOnL, StimOnR, StimOnB, Burst
    %mod = ''; %BrainSense, IS, LMTD, Chronic + Bip Ring RingL RingR SegmIntraL SegmInterL SegmIntraR SegmInterR
    %run = ''; %numeric

    extended {mustBeMember(extended,["","yes"])} = '';

end

%% OUTPUT
% The script generates BIDS inspired subject and session folders with the
% ieeg format specifier. All time series data are being exported as
% FieldTrip .mat files, as these require no additional dependencies for creation.
% You can reformat with FieldTrip and SPM to MNE
% python and other formats (e.g. using fieldtrip2fiff([fullname '.fif'],data))

%% Recording type output naming
% Each of the FieldTrip data files correspond to a specific aspect of the Recording session:
% LMTD = LFP Montage Time Domain - BrainSenseSurvey
% IS = Indefinite Streaming - BrainSenseStreaming
% CT = Calibration Testing - Calibration Tests
% BSL = BrainSense LFP (2 Hz power average + stimulation settings)
% BSTD = BrainSense Time Domain (250 Hz raw data corresponding to the BSL file)
% BrainSenseBip = combination of BSL and BSTD into Brainsense with LFP signal/stim settings.

% for modalities see white paper:
% Jimenez-Shahed, J. (2021). Expert Review of Medical Devices, 18(4), 319–332. https://doi.org/10.1080/17434440.2021.1909471
% Yohann Thenaisie et al (2021) J. Neural Eng. 18 042002 DOI https://doi.org/10.1088/1741-2552/ac1d5b

%% TODO:
% ADD DEIDENTIFICATION OF COPIED JSON -> remove copied json, OK
% BUG FIX UTC? -> yes
% ADD BATTERY DRAIN
% ADD BSL data to BSTD ephys file
% ADD PATIENT SNAPSHOT EVENT READINGS
% IMPROVE CHRONIC DIAGNOSTIC READINGS
% ADD Lead DBS Integration for electrode location

if exist('datafields') && ischar(datafields)
    datafields = {datafields};
end

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

%% create subject
if exist('sub','var')
    if isnumeric(sub)
        sub=num2str(sub);
    end
    if ischar(sub) && ~isempty(sub)
        if length(sub) == sum(isstrprop(sub,'digit'))
            sub=pad(sub,3,'left','0');
            sub=['sub-' sub];
        end
        sub={sub};
    end
end


%% create task
task = 'task-Rest';
%% create run / mod / acq
run = 0;
mod = '';
acq = 'acq-StimOff';
%% iterate over files
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


    infofields = {'SessionDate','SessionEndDate','PatientInformation','DeviceInformation','BatteryInformation','LeadConfiguration','Stimulation','Groups','Stimulation','Impedance','PatientEvents','EventSummary','DiagnosticData'};
    for b = 1:length(infofields)
        if isfield(js,infofields{b})
            hdr.(infofields{b})=js.(infofields{b});
        end
    end
    
    hdr.SessionEndDate = datetime(strrep(js.SessionEndDate(1:end-1),'T',' ')); %To Do
    hdr.SessionEndDate = datetime(strrep(js.SessionDate(1:end-1),'T',' ')); %To Do
    if ~isempty(js.PatientInformation.Final.Diagnosis)
        hdr.Diagnosis = strsplit(js.PatientInformation.Final.Diagnosis,'.');hdr.Diagnosis=hdr.Diagnosis{2};
    else
        hdr.Diagnosis = '';
    end

    hdr.OriginalFile = filename;
    hdr.ImplantDate = strrep(strrep(js.DeviceInformation.Final.ImplantDate(1:end-1),'T','_'),':','-'); %To Do
    hdr.BatteryPercentage = js.BatteryInformation.BatteryPercentage;
    hdr.LeadLocation = strsplit(hdr.LeadConfiguration.Final(1).LeadLocation,'.');hdr.LeadLocation=hdr.LeadLocation{2};

    %% preset subject

    if isempty(sub)
        if ~isempty(hdr.ImplantDate) &&  ~isnan(str2double(hdr.ImplantDate(1)))
            hdr.subject = ['sub-' strrep(strtok(hdr.ImplantDate,'_'),'-','') hdr.Diagnosis(1) hdr.LeadLocation];
        else
            hdr.subject = ['sub-000' hdr.Diagnosis(1) hdr.LeadLocation];
        end
        sub = {hdr.subject};
    elseif iscell(sub) && length(sub) == length(files)
        hdr.subject = sub{a};
    elseif length(sub) == 1
        hdr.subject = sub{1};
    end


    % determine session
    if isempty(sesMedOffOn01)
        ses = ['ses-' char(datetime(hdr.SessionEndDate,'format','yyyyMMddhhmmss')) num2str(hdr.BatteryPercentage)];
        hdr.session = ses;
    else
        %% preset session
        if ~ischar(sesMedOffOn01)
            sesMedOffOn01=char(sesMedOffOn01);
        end
        diffmonths=between(datetime(hdr.SessionEndDate,'format','yyyyMMdd') , datetime(strrep(strtok(hdr.ImplantDate,'_'),'-',''),'format','yyyyMMdd'));
        diffmonths=abs(calmonths(diffmonths));
        presetmonths=[0,1,2,3,6,12,18,24,30,36,42,48,60,72,84,96,108,120];
        diffmonths = interp1(presetmonths,presetmonths,diffmonths,'nearest');
        diffmonths=num2str(diffmonths);
        %% create session
        ses = ['ses-', 'Fu' pad(diffmonths,2,'left','0'), 'm' , sesMedOffOn01];
        hdr.session = ses;
    end

    %% create metatable %determine
    MetaT = cell2table(cell(0,10),'VariableNames', {'report','perceiveFilename','session','condition','task','contacts','run','part','acq','remove'});

    %% create dirs and path
    if ~exist(fullfile(hdr.subject,hdr.session,'ieeg'),'dir')
        mkdir(fullfile(hdr.subject,hdr.session,'ieeg'));
    end
    hdr.fpath = fullfile(hdr.subject,hdr.session,'ieeg');
    hdr.fname = [hdr.subject '_' hdr.session '_' task '_' acq];
    hdr.chan = ['LFP_' hdr.LeadLocation];
    hdr.d0 = datetime(js.SessionEndDate(1:10));

    hdr.js = js;
    if ~exist('datafields','var')
        datafields = sort({'EventSummary','Impedance','MostRecentInSessionSignalCheck','BrainSenseLfp','BrainSenseTimeDomain','LfpMontageTimeDomain','IndefiniteStreaming','BrainSenseSurvey','CalibrationTests','PatientEvents','DiagnosticData'});
    end
    alldata = {};
    disp(['SUBJECT ' hdr.subject])

    for b = 1:length(datafields)
        if isfield(js,datafields{b})
            data = js.(datafields{b});
            if isempty(data)
                continue
            end
            mod='';
            run=1;
            switch datafields{b}
                %% add csv files by default
                case 'Impedance'
                    if extended
                        mod = 'mod-Impedance';
                        T=table;
                        save_impedance=1;
                        for c = 1:length(data.Hemisphere)
                            tmp=strsplit(data.Hemisphere(c).Hemisphere,'.');
                            side = tmp{2}(1);
                            electrodes = unique([{data.Hemisphere(c).SessionImpedance.Monopolar.Electrode2} {data.Hemisphere(c).SessionImpedance.Monopolar.Electrode1}]);
                            e1 = strrep([{data.Hemisphere(c).SessionImpedance.Monopolar.Electrode1} {data.Hemisphere(c).SessionImpedance.Bipolar.Electrode1}],'ElectrodeDef.','') ;
                            e2 = [{data.Hemisphere(c).SessionImpedance.Monopolar.Electrode2} {data.Hemisphere(c).SessionImpedance.Bipolar.Electrode2}];
                            if ~ischar([data.Hemisphere(c).SessionImpedance.Monopolar.ResultValue]) && ~ischar([data.Hemisphere(c).SessionImpedance.Bipolar.ResultValue])
                                imp = [[data.Hemisphere(c).SessionImpedance.Monopolar.ResultValue] [data.Hemisphere(c).SessionImpedance.Bipolar.ResultValue]];
                                for e = 1:length(imp)
                                    if strcmp(e1{e},'Case')
                                        T.([hdr.chan '_' side e2{e}(end)]) = imp(e);
                                    else
                                        T.([hdr.chan '_' side e2{e}(end) e1{e}(end)]) = imp(e);
                                    end
                                end
                            else
                                warning('impedance values too high, not being saved...')
                                save_impedance=0;
                            end

                        end
                        if save_impedance
                            figure
                            barh(table2array(T(1,:))')
                            set(gca,'YTick',1:length(T.Properties.VariableNames),'YTickLabel',strrep(T.Properties.VariableNames,'_',' '))
                            xlabel('Impedance')
                            title(strrep({hdr.subject, hdr.session,'Impedances'},'_',' '))
                            perceive_print(fullfile(hdr.fpath,[hdr.fname '_' mod]))
                            writetable(T,fullfile(hdr.fpath,[hdr.fname '_' mod '.csv']));
                        end
                    end

                case 'PatientEvents'
                    disp(fieldnames(data));

                case 'MostRecentInSessionSignalCheck'
                    if extended
                        mod = 'mod-MostRecentSignalCheck';
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
                            title(strrep({'MostRecentSignalCheck',hdr.subject,char(hdr.SessionEndDate),'LEFT'},'_',' '))
                            plot(peaks(il,1),peaks(il,2),'LineStyle','none','Marker','.','MarkerSize',12)
                            xlabel('Frequency [Hz]')
                            ylabel('Power spectral density [uV^2/Hz]')
                            for c = 1:length(il)
                                if peaks(il(c),1)>0
                                    text(peaks(il(c),1),peaks(il(c),2),[' ' num2str(peaks(il(c),1),3) ' Hz'])
                                end
                            end
                            legend(strrep(channels(il),'_',' '))
                            %savefig(fullfile(hdr.fpath,[hdr.fname '_run-MostRecentSignalCheck.fig']))
                            perceive_print(fullfile(hdr.fpath,[hdr.fname '_' mod]))
                        end

                    end
                case 'DiagnosticData'
                    if extended
                        hdr.fname = strrep(hdr.fname,'StimOff','StimX');
                        if isfield(data,'LFPTrendLogs')
                            LFPL=[];STIML=[];DTL=datetime([],[],[]);
                            LFPR=[];STIMR=[];DTR=datetime([],[],[]);
                            if isfield(data.LFPTrendLogs,'HemisphereLocationDef_Left')
                                data.left=data.LFPTrendLogs.HemisphereLocationDef_Left;
                                runs = fieldnames(data.left);
                                for c=1:length(runs)
                                    clfp = [data.left.(runs{c}).LFP];
                                    cstim = [data.left.(runs{c}).AmplitudeInMilliAmps];
                                    cdt = datetime({data.left.(runs{c}).DateTime},'InputFormat','yyyy-MM-dd''T''HH:mm:ss''Z''');
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
                                    if length(d.time{1})>1
                                        d.fsample = abs(1/diff(d.time{1}(1:2)));
                                    else
                                        warning('Only one data point recorded, assuming a sampling frequency of 1 / 10 minutes ~ 0.0017 Hz');
                                        d.fsample = 1/600; % 10*60 sec = 10 minutes
                                    end
                                    d.hdr.Fs = d.fsample; d.hdr.label = d.label;
                                    firstsample = d.time{1}(1); lastsample = d.time{1}(end);d.sampleinfo(1,:) = [firstsample lastsample];
                                    mod= 'mod-ChronicLeft';
                                    d.fname = [hdr.fname '_' mod];
                                    d.fnamedate = [char(datetime(cdt(1),'format','yyyyMMddhhmmss'))];
                                    d.keepfig = false; % do not keep figure with this signal open (the number of LFPTrendLogs can be high)
                                    alldata{length(alldata)+1} = d;
                                end
                            end



                            if isfield(data.LFPTrendLogs,'HemisphereLocationDef_Right')
                                data.right=data.LFPTrendLogs.HemisphereLocationDef_Right;
                                runs = fieldnames(data.right);
                                for c=1:length(runs)
                                    clfp = [data.right.(runs{c}).LFP];
                                    cstim = [data.right.(runs{c}).AmplitudeInMilliAmps];
                                    cdt = datetime({data.right.(runs{c}).DateTime},'InputFormat','yyyy-MM-dd''T''HH:mm:ss''Z''');

                                    [cdt,i] = sort(cdt);
                                    LFPR=[LFPR,clfp(i)];
                                    STIMR=[STIMR,cstim(i)];
                                    DTR=[DTR,cdt];


                                    d=[];
                                    d.hdr = hdr;d.datatype = 'DiagnosticData.LFPTrends';
                                    d.trial{1} = [clfp;cstim];
                                    d.label = {'LFP_RIGHT','STIM_RIGHT'};
                                    d.time{1} = linspace(seconds(cdt(1)-hdr.d0),seconds(cdt(end)-hdr.d0),size(d.trial{1},2));
                                    d.realtime{1} = cdt;
                                    if length(d.time{1})>1
                                        d.fsample = abs(1/diff(d.time{1}(1:2)))
                                    else
                                        warning('Only one data point recorded, assuming a sampling frequency of 1 / 10 minutes ~ 0.0017 Hz');
                                        d.fsample = 1/600; % 10*60 sec = 10 minutes
                                    end
                                    d.hdr.Fs = d.fsample; d.hdr.label = d.label;
                                    firstsample = d.time{1}(1); lastsample = d.time{1}(end);d.sampleinfo(1,:) = [firstsample lastsample];
                                    mod = 'mod-ChronicRight';
                                    d.fname = [hdr.fname '_' mod];
                                    d.fnamedate = [char(datetime(cdt(1),'format','yyyyMMddhhmmss'))];
                                    d.keepfig = false; % do not keep figure with this signal open (the number of LFPTrendLogs can be high)
                                    alldata{length(alldata)+1} = d;
                                end
                            end


                            LFP=[];
                            STIM=[];
                            if isempty(DTL)
                                DT = sort(DTR);
                            elseif isempty(DTR)
                                DT = sort(DTL);
                            else
                                DT=sort([DTL,setdiff(DTR,DTL)]);
                            end
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
                            d.datatype = 'DiagnosticData.LFPTrends';
                            d.trial{1} = [LFP;STIM];
                            d.label = {'LFP_LEFT','LFP_RIGHT','STIM_LEFT','STIM_RIGHT'};
                            d.time{1} = DT;
                            d.fsample = diff(DT);
                            firstsample = d.time{1}(1);
                            lastsample = d.time{1}(end);
                            d.sampleinfo(1,:) = [firstsample lastsample];
                            mod = 'mod-Chronic';
                            d.fname = [hdr.fname '_' mod];
                            d.fnamedate = [char(datetime(DT(1),'format','yyyyMMddhhmmss'))];
                            % TODO: set if needed::
                            %d.keepfig = false; % do not keep figure with this signal open
                            alldata{length(alldata)+1} = d;


                            figure('Units','centimeters','PaperUnits','centimeters','Position',[1 1 40 20])
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
                            %savefig(fullfile(hdr.fpath,[hdr.fname '_CHRONIC.fig']))
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
                                    if isfield(lfp.LfpFrequencySnapshotEvents,'HemisphereLocationDef_Left')
                                        tmp = strsplit(strrep(lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Left.SenseID,'_AND',''),'.');
                                        if isempty(tmp{1}) || length(tmp) == 1
                                            tmp = {'','unknown'};
                                        end
                                        ch1 = strcat(hdr.chan,'_L_',strrep(strrep(strrep(strrep(strrep(tmp{2},'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3'),'_',''));
                                    else
                                        ch1 = 'n/a';
                                    end
                                    if isfield(lfp.LfpFrequencySnapshotEvents,'HemisphereLocationDef_Right')
                                        tmp = strsplit(strrep(lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Right.SenseID,'_AND',''),'.');
                                        if isempty(tmp{1}) || length(tmp) == 1
                                            tmp = {'','unknown'};
                                        end
                                        ch2 = strcat(hdr.chan,'_R_',strrep(strrep(strrep(strrep(strrep(tmp{2},'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3'),'_',''));
                                    else
                                        ch2 = 'n/a';
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


                                    figure
                                    plot(freq,pow,'linewidth',2)
                                    legend(strrep(chanlabels{c},'_',' '))
                                    title({strrep(hdr.fname,'_',' ');char(DT(c));events{c};['STIM GROUP ' stimgroups{c}]})
                                    xlabel('Frequency [Hz]')
                                    ylabel('Power spectral density [uV^2/Hz]')
                                    %savefig(fullfile(hdr.fpath,[hdr.fname '_LFPSnapshot_' events{c} '-' num2str(c) '.fig']))
                                    perceive_print(fullfile(hdr.fpath,[hdr.fname '_LFPSnapshot_' events{c} '-' num2str(c)]))
                                else
                                    % keyboard
                                    warning('LFP Snapshot Event without LFP data present.')
                                end
                            end
                            writetable(Tpow,fullfile(hdr.fpath,[hdr.fname '_LFPSnapshotEvents.csv']))
                        end
                    end
                case 'BrainSenseTimeDomain'

                    FirstPacketDateTime = strrep(strrep({data(:).FirstPacketDateTime},'T',' '),'Z','');
                    runs = unique(FirstPacketDateTime);
                    fsample = data.SampleRateInHz;

                    Pass = {data(:).Pass};
                    tmp =  {data(:).GlobalSequences};
                    for c = 1:length(tmp)
                        GlobalSequences{c,:} = str2num(tmp{c});
                        missingPackages{c,:} = (diff(str2num(tmp{c}))==2);
                        nummissinPackages(c) = numel(find(diff(str2num(tmp{c}))==2));
                    end
                    tmp =  {data(:).TicksInMses};
                    for c = 1:length(tmp)
                        TicksInMses{c,:}= str2num(tmp{c});
                        TicksInS{c,:} = (TicksInMses{c,:} - TicksInMses{c,:}(1))/1000;
                    end

                    tmp =  {data(:).GlobalPacketSizes};
                    for c = 1:length(tmp)
                        GlobalPacketSizes{c,:} = str2num(tmp{c});
                        isDataMissing(c)= logical(TicksInS{c,:}(end) >= sum(GlobalPacketSizes{c,:})/fsample);
                        time_real{c,:} = TicksInS{c,:}(1):1/fsample:TicksInS{c,:}(end)+(GlobalPacketSizes{c,:}(end)-1)/fsample;
                        time_real{c,:} = round(time_real{c,:},3);
                    end




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
                        try
                            x=find(ismember(i, find(isDataMissing)));
                            if ~isempty(x)
                                warning('missing packages detected, will interpolate to replace missing data')
                                for k=1:numel(x)
                                    isReceived = zeros(size(time_real{i(k),:}, 2), 1);
                                    nPackets = numel(GlobalPacketSizes{i(k),:});
                                    for packetId = 1:nPackets
                                        timeTicksDistance = abs(time_real{i(k),:} - TicksInS{i(k),:}(packetId));
                                        [~, packetIdx] = min(timeTicksDistance);
                                        if isReceived(packetIdx) == 1
                                            packetIdx = packetIdx +1;
                                        end
                                        isReceived(packetIdx:packetIdx+GlobalPacketSizes{i(k),:}(packetId)-1) = isReceived(packetIdx:packetIdx+GlobalPacketSizes{i(k),:}(packetId)-1)+1;
                                        %             figure; plot(isReceived, '.'); yticks([0 1]); yticklabels({'not received', 'received'}); ylim([-1 10])
                                    end
                                    data_temp = NaN(size(time_real{i(k),:}, 2), 1);
                                    data_temp(logical(isReceived), :) = data(i(k)).TimeDomainData;
                                    ind_interp=find(diff(isReceived));
                                    if isReceived(ind_interp(1)+1)==1
                                        ind_interp=[1 ind_interp];
                                        data_temp(1)=0;
                                    end
                                    if isReceived(ind_interp(end)+1)==0
                                        ind_interp=[ind_interp size(data_temp,1)-1];
                                        data_temp(end)=0;
                                    end
                                    for mm=1:2:numel(ind_interp/2)
                                        data_temp(ind_interp(mm)+1:ind_interp(mm+1))=...
                                            linspace(data_temp(ind_interp(mm)), data_temp(ind_interp(mm+1)+1), ind_interp(mm+1)-ind_interp(mm));
                                    end
                                    raw_temp(x(k),:)=data_temp';
                                end
                                raw=raw_temp;
                            else
                                raw=[data(i).TimeDomainData]';
                            end
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

                        d.time{1} = linspace(seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')-hdr.d0),seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')-hdr.d0)+size(d.trial{1},2)/fsample,size(d.trial{1},2));

                        d.fsample = fsample;

                        firstsample = 1+round(fsample*seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')-hdr.d0));
                        lastsample = firstsample+size(d.trial{1},2);
                        d.sampleinfo(1,:) = [firstsample lastsample];
                        if firstsample<0
                            keyboard
                        end

                        d.BrainSenseDateTime = [datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS','Format','yyyy-MM-dd HH:mm:ss.SSS'), datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS','Format','yyyy-MM-dd HH:mm:ss.SSS') + seconds(size(d.trial{1},2)/fsample)];

                        d.trialinfo(1) = c;
                        mod = 'mod-BSTD';
                        d.fname = [hdr.fname '_' mod];
                        d.fnamedate = [char(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS','format','yyyyMMddhhmmss'))];
                        d.hdr.Fs = d.fsample;
                        d.hdr.label = d.label;

                        d.ecg=[];
                        d.ecg_cleaned=[];
                        for e = 1:size(raw,1)
                            d.ecg{e} = perceive_ecg(raw(e,:));
                            title(strrep(d.label{e},'_',' '))
                            xlabel(strrep(d.fname,'_',' '))
                            %savefig(fullfile(hdr.fpath,[d.fname '_ECG_' d.label{e} '.fig']))
                            perceive_print(fullfile(hdr.fpath,[d.fname '_ECG_' d.label{e}]))
                            d.ecg_cleaned(e,:) = d.ecg{e}.cleandata;
                        end
                        % TODO: set if needed:
                        %d.keepfig = false; % do not keep figure with this signal open
                        alldata{length(alldata)+1} = d;
                    end


                case 'BrainSenseLfp'
                    counterBSL=  0;
                    FirstPacketDateTime = strrep(strrep({data(:).FirstPacketDateTime},'T',' '),'Z','');
                    runs = unique(FirstPacketDateTime);
                    bsldata=[];bsltime=[];bslchannels=[];
                    figure('Units','centimeters','PaperUnits','centimeters','Position',[1 1 40 20])
                    for c=1:length(runs)
                        cdata = data(c);
                        tmp = strrep(cdata.Channel,'_AND','');
                        tmp = strsplit(strrep(strrep(strrep(strrep(strrep(tmp,'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3'),'_',''),',');
                        if length(tmp)==2
                            lfpchannels = {[hdr.chan '_' tmp{1}(3) '_' tmp{1}(1:2) ], ...
                                [hdr.chan '_' tmp{2}(3) '_' tmp{2}(1:2)]};
                        else
                            if length(tmp)==1
                                lfpchannels = {[hdr.chan '_' tmp{1}(3) '_' tmp{1}(1:2) ]};
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

                        %% set the name for BSL and STIM
                        counterBSL=  counterBSL+1;
                        mod = 'mod-BSL';
                        d.fname = [hdr.fname '_' mod ];
                        d.fname = strrep(d.fname,'task-Rest',['task-TASK' num2str(counterBSL)]);
                        if contains(d.label(3),'STIM_L')
                            LAmp=d.trial{1}(3,:);
                        elseif contains(d.label(4),'STIM_L')
                            LAmp=d.trial{1}(4,:);
                        end
                        if contains(d.label(3),'STIM_R')
                            RAmp=d.trial{1}(3,:);
                        elseif contains(d.label(4),'STIM_R')
                            RAmp=d.trial{1}(4,:);
                        end
                        
                        % d.hdr.SessionDate
                        % d.hdr.Groups
                        % d.hdr.Groups.Initial(1).GroupSettings.Cycling
                        % d.hdr.Groups.Initial(2).GroupSettings.Cycling
                        % d.hdr.Groups.Initial(3).GroupSettings.Cycling
                        % d.hdr.Groups.Initial(4).GroupSettings.Cycling
                        % %d.hdr.Groups.Initial(5).GroupSettings.Cycling
                        acq=check_stim(LAmp, RAmp, d.hdr);
                        d.fname = strrep(d.fname,'StimOff',acq);

                        d.fnamedate = [char(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS','format','yyyyMMddhhmmss'))];
                        %% plot integrated BSL plot
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
                        % TODO: set if needed:
                        %d.keepfig = false; % do not keep figure with this signal open
                        alldata{length(alldata)+1} = d;

                        %savefig(fullfile(hdr.fpath,[d.fname '.fig']))
                        perceive_print(fullfile(hdr.fpath,[d.fname]))


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

                    mod = 'mod-BrainsenseLFP';
                    writetable(T,fullfile(hdr.fpath,[hdr.fname '_' mod '.csv']))

                case 'LfpMontageTimeDomain'
                    %% add perceive ecg add figures cleaning

                    FirstPacketDateTime = strrep(strrep({data(:).FirstPacketDateTime},'T',' '),'Z','');
                    runs = unique(FirstPacketDateTime);

                    Pass = {data(:).Pass};
                    tmp =  {data(:).GlobalSequences};
                    for c = 1:length(tmp)
                        GlobalSequences{c,:} = str2num(tmp{c});
                    end
                    tmp =  {data(:).GlobalPacketSizes};
                    for c = 1:length(tmp)
                        GlobalPacketSizes{c,:} = str2num(tmp{c});
                    end

                    fsample = data.SampleRateInHz;
                    gain=[data(:).Gain]';

                    %if contains()
                    [tmp1]=split({data(:).Channel}', regexpPattern("(_AND_)|(?<!.*_.*)_"));
                    %[tmp1,tmp2] = strtok(strrep({data(:).Channel}','_AND',''),'_');
                    %[tmp1] = split({data(:).Channel}','_AND_'); % tmp1 is a tuple of first str part before AND and second str part after AND
                    % ch1 = strrep(strrep(strrep(strrep(tmp1,'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3');
                    ch1 = strrep(strrep(strrep(strrep(tmp1(:,1),'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3'); % ch1 replaces ZERO to int 0 etc of first part before AND (tmp1(:,1))

                    % [tmp1,tmp2] = strtok(tmp2,'_');
                    % ch2 = strrep(strrep(strrep(strrep(tmp1,'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3');
                    ch2 = strrep(strrep(strrep(strrep(tmp1(:,2),'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3'); % ch2 replaces ZERO to int 0 etc of second part after AND (tmp1(:,1))

                    % side = strrep(strrep(strtok(tmp2,'_'),'LEFT','L'),'RIGHT','R');
                    % Channel = strcat(hdr.chan,'_',side,'_', ch1, ch2);
                    Channel = strcat(hdr.chan,'_', ch1,'_', ch2); % taken out "side" so RIGHT and LEFT will stay the same, no transformation to R and L

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

                        d.time{1} = linspace(seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')-hdr.d0),seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')-hdr.d0)+size(d.trial{1},2)/fsample,size(d.trial{1},2));
                        d.fsample = fsample;
                        firstsample = 1+round(fsample*seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')-datetime(FirstPacketDateTime{1},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')));
                        lastsample = firstsample+size(d.trial{1},2);
                        d.sampleinfo(1,:) = [firstsample lastsample];
                        d.trialinfo(1) = c;

                        d.hdr.label = d.label;
                        d.hdr.Fs = d.fsample;
                        mod = 'mod-LMTD';
                        d.fname = [hdr.fname '_' mod];
                        d.fnamedate = [char(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS','format','yyyyMMddhhmmss')), '_',num2str(c)];
                        % TODO: set if needed:
                        %d.keepfig = false; % do not keep figure with this signal open
                        alldata{length(alldata)+1} = d;
                    end
                case 'BrainSenseSurvey'

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


                case 'IndefiniteStreaming'
                    %% add ecg-cleaning perceive
                    %% add figures ecg cleaning
                    FirstPacketDateTime = strrep(strrep({data(:).FirstPacketDateTime},'T',' '),'Z','');
                    runs = unique(FirstPacketDateTime);
                    fsample = data.SampleRateInHz;

                    Pass = {data(:).Pass};
                    tmp =  {data(:).GlobalSequences};
                    for c = 1:length(tmp)
                        GlobalSequences{c,:} = str2num(tmp{c});
                        missingPackages{c,:} = (diff(str2num(tmp{c}))==2);
                        nummissinPackages(c) = numel(find(diff(str2num(tmp{c}))==2));
                    end
                    tmp =  {data(:).TicksInMses};
                    for c = 1:length(tmp)
                        TicksInMses{c,:}          = str2num(tmp{c});
                        TicksInS_temp             = (TicksInMses{c,:} - TicksInMses{c,:}(1))/1000;
                        [TicksInS_temp,~,ci_temp] = unique(TicksInS_temp);
                        TicksInS{c,:}             = TicksInS_temp;
                        ci{c,:}                   = ci_temp;
                    end

                    tmp =  {data(:).GlobalPacketSizes};
                    for c = 1:length(tmp)
                        GlobalPacketSizes_temp = str2num(tmp{c});
                        for kk=1:max(ci{c,:})
                            GPS_temp(kk)=sum(GlobalPacketSizes_temp(find(ci{c,:}==kk)));
                        end
                        GlobalPacketSizes{c,:} = GPS_temp;
                        isDataMissing(c)       = logical(TicksInS{c,:}(end) >= sum(GlobalPacketSizes{c,:})/fsample);
                        time_real{c,:}         = TicksInS{c,:}(1):1/fsample:TicksInS{c,:}(end)+(GlobalPacketSizes{c,:}(end)-1)/fsample;
                        time_real{c,:}         = round(time_real{c,:},3);
                    end

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
                        d=[];
                        d.hdr = hdr;
                        d.datatype = datafields{b};
                        d.hdr.IS.Pass=strrep(strrep(unique(strtok(Pass(i),'_')),'FIRST','1'),'SECOND','2');
                        d.hdr.IS.GlobalSequences=GlobalSequences(i,:);
                        d.hdr.IS.GlobalPacketSizes=GlobalPacketSizes(i,:);
                        d.hdr.IS.FirstPacketDateTime = runs{c};
                        x=find(ismember(i, find(isDataMissing)));
                        if ~isempty(x)
                            warning('missing packages detected, will interpolate to replace missing data')
                            try
                            for k=1:numel(x)
                                isReceived = zeros(size(time_real{i(k),:}, 2), 1);
                                nPackets = numel(GlobalPacketSizes{i(k),:});
                                for packetId = 1:nPackets
                                    timeTicksDistance = abs(time_real{i(k),:} - TicksInS{i(k),:}(packetId));
                                    [~, packetIdx] = min(timeTicksDistance);
                                    if isReceived(packetIdx) == 1
                                        packetIdx = packetIdx +1;
                                    end
                                    %                                     if packetIdx+GlobalPacketSizes{i(k),:}(packetId)-1>size(isReceived,1)
                                    %                                         cut_sampl=size(isReceived,1)-packetIdx+GlobalPacketSizes{i(k),:}(packetId);
                                    %                                         isReceived(packetIdx:packetIdx+GlobalPacketSizes{i(k),:}(packetId)-cut_sampl) = isReceived(packetIdx:packetIdx+GlobalPacketSizes{i(k),:}(packetId)-cut_sampl)+1;
                                    %                                     else
                                    isReceived(packetIdx:packetIdx+GlobalPacketSizes{i(k),:}(packetId)-1) = isReceived(packetIdx:packetIdx+GlobalPacketSizes{i(k),:}(packetId)-1)+1;
                                    %             figure; plot(isReceived, '.'); yticks([0 1]); yticklabels({'not received', 'received'}); ylim([-1 10])
                                    %                                     end
                                end

                                %If there are pseudo double-received samples, compensate non-received samples
                                %                                 numel(find(logical(isReceived)))+nDoubles
                                doublesIdx = find(isReceived == 2);
                                nDoubles = numel(doublesIdx);
                                for doubleId = 1:nDoubles
                                    missingIdx = find(isReceived == 0);
                                    [~, idxOfidx] = min(abs(missingIdx - doublesIdx(doubleId)));
                                    isReceived(missingIdx(idxOfidx)) = 1;
                                    isReceived(doublesIdx(doubleId)) = 1;
                                end

                                data_temp = NaN(size(time_real{i(k),:}, 2), 1);
                                data_temp(logical(isReceived), :) = data(i(k)).TimeDomainData;
                                ind_interp=find(diff(isReceived));
                                if isReceived(ind_interp(1)+1)==1
                                    ind_interp=[1 ind_interp];
                                    data_temp(1)=0;
                                end
                                if isReceived(ind_interp(end)+1)==0
                                    ind_interp=[ind_interp size(data_temp,1)-1];
                                    data_temp(end)=0;
                                end
                                for mm=1:2:numel(ind_interp/2)
                                    data_temp(ind_interp(mm)+1:ind_interp(mm+1))=...
                                        linspace(data_temp(ind_interp(mm)), data_temp(ind_interp(mm+1)+1), ind_interp(mm+1)-ind_interp(mm));
                                end
                                raw_temp(x(k),:)=data_temp';
                            end
                            tmp=raw_temp;
                            catch
                                warning('The missing packages could not be computed. Interpolation failed.')
                            end
                        else
                            tmp=[data(i).TimeDomainData]';
                        end
                        
                        try
                        xchans = perceive_ci({'L_03','L_13','L_02','R_03','R_13','R_02'},Channel(i));
                        nchans = {'L_01','L_12','L_23','R_01','R_12','R_23'};
                        refraw = [tmp(xchans(1),:)-tmp(xchans(2),:);(tmp(xchans(1),:)-tmp(xchans(2),:))-tmp(xchans(3),:);tmp(xchans(3),:)-tmp(xchans(1),:);
                            tmp(xchans(4),:)-tmp(xchans(5),:);(tmp(xchans(4),:)-tmp(xchans(5),:))-tmp(xchans(6),:);tmp(xchans(6),:)-tmp(xchans(4),:)];
                        d.trial{1} = [tmp;-refraw;];
                        catch
                            d.trial{1} = [tmp];
                            warning('The calculated packages could not be added. Data for Indefinite Streaming failed.')
                        end

                        d.label=[Channel(i);strcat(hdr.chan,'_',nchans')];

                        d.time{1} = linspace(seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')-hdr.d0),seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')-hdr.d0)+size(d.trial{1},2)/fsample,size(d.trial{1},2));
                        d.fsample = fsample;
                        firstsample = 1+round(fsample*seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')-datetime(FirstPacketDateTime{1},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')));
                        lastsample = firstsample+size(d.trial{1},2);
                        d.sampleinfo(1,:) = [firstsample lastsample];
                        d.trialinfo(1) = c;
                        d.hdr.label=d.label;
                        d.hdr.Fs = d.fsample;
                        mod = 'mod-ISRing';
                        d.fname = [hdr.fname '_' mod];
                        d.fnamedate = [char(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS','format','yyyyMMddhhmmss'))];
                        % TODO: set if needed:
                        %d.keepfig = false; % do not keep figure with this signal open
                        alldata{length(alldata)+1} = d;
                    end



                case 'CalibrationTests'
                    if extended
                        FirstPacketDateTime = strrep(strrep({data(:).FirstPacketDateTime},'T',' '),'Z','');
                        runs = unique(FirstPacketDateTime);
                        Pass = {data(:).Pass};
                        tmp =  {data(:).GlobalSequences};
                        for c = 1:length(tmp)
                            GlobalSequences{c,:} = str2num(tmp{c});
                        end
                        tmp =  {data(:).GlobalPacketSizes};
                        for c = 1:length(tmp)
                            GlobalPacketSizes{c,:} = str2num(tmp{c});
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
                        title(strrep({hdr.subject,hdr.session,'All CalibrationTests'},'_',' '))
                        %savefig(fullfile(hdr.fpath,[hdr.fname '_run-AllCalibrationTests.fig']))
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

                            d.time{1} = linspace(seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')-hdr.d0),seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')-hdr.d0)+size(d.trial{1},2)/fsample,size(d.trial{1},2));

                            d.fsample = fsample;
                            firstsample = 1+round(fsample*seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')-datetime(FirstPacketDateTime{1},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')));
                            lastsample = firstsample+size(d.trial{1},2);
                            d.sampleinfo(1,:) = [firstsample lastsample];
                            d.trialinfo(1) = c;
                            d.hdr.label = d.label;
                            d.hdr.Fs = d.fsample;

                            d.fname = [hdr.fname '_run-CT' char(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS','format','yyyyMMddhhmmss')) '_' num2str(c)];
                            % TODO: set if needed:
                            %d.keepfig = false; % do not keep figure with this signal open
                            alldata{length(alldata)+1} = d;
                        end
                    end
                case 'SenseChannelTests'
                    if extended
                        FirstPacketDateTime = strrep(strrep({data(:).FirstPacketDateTime},'T',' '),'Z','');
                        runs = unique(FirstPacketDateTime);
                        hdr.scd0=datetime(FirstPacketDateTime{1}(1:10));
                        Pass = {data(:).Pass};
                        tmp =  {data(:).GlobalSequences};
                        for c = 1:length(tmp)
                            GlobalSequences{c,:} = str2num(tmp{c});
                        end
                        tmp =  {data(:).GlobalPacketSizes};
                        for c = 1:length(tmp)
                            GlobalPacketSizes{c,:} = str2num(tmp{c});
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

                            d.time{1} = linspace(seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')-hdr.scd0),seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')-hdr.scd0)+size(d.trial{1},2)/fsample,size(d.trial{1},2));
                            d.fsample = fsample;
                            firstsample = 1+round(fsample*seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')-datetime(FirstPacketDateTime{1},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')));
                            lastsample = firstsample+size(d.trial{1},2);
                            d.sampleinfo(1,:) = [firstsample lastsample];
                            d.trialinfo(1) = c;

                            d.hdr.label = d.label;
                            d.hdr.Fs = d.fsample;
                            d.fname = [hdr.fname '_run-SCT' char(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS','format','yyyyMMddhhmmss'))];
                            % TODO: set if needed:
                            %d.keepfig = false; % do not keep figure with this signal open
                            alldata{length(alldata)+1} = d;
                        end
                    end
            end
        end
    end

    %nfile = fullfile(hdr.fpath,[hdr.fname '.jsoncopy']);
    %copyfile(files{a},nfile)

    counterBrainSense=0;
    %% save all data
    for b = 1:length(alldata)
        fullname = fullfile('.',hdr.fpath,alldata{b}.fname);
        data=alldata{b};
        % remove the optional 'keepfig' field (not to mess up the saved data)
        if isfield(data,'keepfig')
            data=rmfield(data,'keepfig');
        end

        % restore the data (incl. the optional 'keepfig' field)
        data=alldata{b};

        %% handle BSTD and BSL files to BrainSenseBip
        if regexp(data.fname,'BSTD')
            counterBrainSense=counterBrainSense+1;

            data.fname = strrep(data.fname,'BSTD','BrainSenseBip');
            data.fname = strrep(data.fname,'task-Rest',['task-TASK' num2str(counterBrainSense)]);
            fulldata = data;

            [folder,~,~]=fileparts(fullname);
            [~,~,list_of_BSLfiles]=perceive_ffind([folder, filesep, '*BSL','*.mat']);

            bsl=load(list_of_BSLfiles{counterBrainSense});

            if ~isequal(bsl.data.hdr.SessionEndDate, data.hdr.SessionEndDate)
                warning('BSL file could not be matched BSTD data to create BrainSense.')
            else
                fulldata.BSLDateTime = [bsl.data.realtime(1) bsl.data.realtime(end)];

                fulldata.label(3:6) = bsl.data.label;
                fulldata.time{1}=fulldata.time{1};
                otime = bsl.data.time{1};
                for c =1:4
                    fulldata.trial{1}(c+2,:) = interp1(otime-otime(1),bsl.data.trial{1}(c,:),fulldata.time{1}-fulldata.time{1}(1),'nearest');
                end
                %% determine StimOff or StimOn

                acq=regexp(bsl.data.fname,'Stim.*(?=_mod)','match'); %Search for StimOff StimOn
                if ~isempty(acq)
                    acq=acq{1};
                else
                    acq=regexp(bsl.data.fname,'Burst.*(?=_mod)','match'); %Search for burst name
                    acq=acq{1};
                end
                fulldata.fname = strrep(fulldata.fname,'StimOff',acq);
                user = memory;
                if user.MemUsedMATLAB < 9^10 %corresponds with 9MB

                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    if size(fulldata.trial{1},2) > 250*2  %% code edited by Mansoureh Fahimi (changed 250 to 250*2)
                        figure('Units','centimeters','PaperUnits','centimeters','Position',[1 1 40 20])
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
                        %LAmp = fulldata.trial{1}(3,:);
                        xlim([fulldata.time{1}(1),fulldata.time{1}(end)])
                        hold on
                        plot(fulldata.time{1},fulldata.trial{1}(5,:).*1000)
                        plot(t,mpow.*1000)
                        title(strrep({fulldata.label{3},fulldata.label{5}},'_',' '))
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
                        %RAmp = fulldata.trial{1}(4,:);
                        xlim([fulldata.time{1}(1),fulldata.time{1}(end)])
                        hold on
                        plot(fulldata.time{1},fulldata.trial{1}(6,:).*1000)
                        plot(t,mpow.*1000)

                        title(strrep({fulldata.fname,fulldata.label{4},fulldata.label{6}},'_',' '))
                        %%
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

                        perceive_print(fullfile('.',hdr.fpath, fulldata.fname))
                    else
                        disp('There is a potential problem: a figure got not created, but the code below would print the current figure (which holds something else than the current ''data'')!');
                        disp('Perhaps, the code printing the figure should be placed inside the ''size(fulldata.trial{1},2) > 250'' branch?');
                        disp('Please, review it.');
                    end
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                end
                %% save data of BSTD
                fullname = fullfile('.',hdr.fpath,fulldata.fname);
                %perceive_print(fullname) %% no useful information
                % close the figure if should not be kept open
                if isfield(fulldata,'keepfig')
                    if ~fulldata.keepfig
                        close();
                    end
                    fulldata=rmfield(fulldata,'keepfig');
                end
                data=fulldata;
                run = 1;
                fullname = [fullname '_run-' num2str(run)];
                while isfile([fullname '.mat'])
                    run = run+1;
                    fullname = (regexp(fulname, '.*_run-','match'));
                    fullname = [fullname{1} num2str(run)];
                end
                [~,fname,~] = fileparts(fullname);
                data.fname = [fname '.mat'];
                disp(['WRITING ' fullname '.mat as FieldTrip file.'])
                save([fullname '.mat'],'data')
                if sesMedOffOn01
                    MetaT= metadata_to_table(MetaT,data);
                end
            end
            %% no BSTD, so save the data
        else

            %% create plot for LMTD and change name
            if contains(fullname,'LMTD') 
                mod_ext=check_mod_ext(data.label);
                fullname = strrep(fullname,'mod-LMTD',['mod-LMTD' mod_ext]);
                data.fname = strrep(data.fname,'mod-LMTD',['mod-LMTD' mod_ext]);
                perceive_plot_raw_signals(data); % for LMTD
                perceive_print(fullname);
            elseif any(extended)
                perceive_plot_raw_signals(data); % for LMTD
                perceive_print(fullname);
            end

            run = 1;
            fullname = [fullname '_run-' num2str(run)];
            while isfile([fullname '.mat'])
                run = run+1;
                fullname = [fullname(1:end-1) num2str(run)];
            end
            [~,fname,~] = fileparts(fullname);
            data.fname = [fname '.mat'];
            disp(['WRITING ' fullname '.mat as FieldTrip file.'])
            save([fullname '.mat'],'data');
            if sesMedOffOn01
                MetaT= metadata_to_table(MetaT,data);
            end
            %savefig([fullname '.fig'])
            % close the figure if should not be kept open
            if isfield(data,'keepfig')
                if ~data.keepfig
                    close();
                end
            end
        end

    end
    close all

    if ~isempty(sesMedOffOn01) && height(MetaT)>1
        MetaTOld = MetaT;
        app=perceive_gui(MetaT);
        waitfor(app.saveandcontinueButton,'UserData')
        MetaT=app.MetaT;
        app.delete;
        %do the file renaming according to the interface metatable
        
        rows_to_remove = [];
        for i = 1:height(MetaT)
            if strcmp(MetaT.remove{i},'REMOVE')
            % do nothing OR %%% when necessary we need to remove the old file
                delete(fullfile(hdr.fpath,MetaTOld.perceiveFilename{i}))
                rows_to_remove = [rows_to_remove, i];
            elseif strcmp(MetaT.remove{i},'keep')
                if ~isequal(fullfile(hdr.fpath,MetaTOld.perceiveFilename{i}), fullfile(hdr.fpath,MetaT.perceiveFilename{i}))
                    load(fullfile(hdr.fpath,MetaTOld.perceiveFilename{i}), 'data');
                    data.fname = MetaT.perceiveFilename{i};
                    save(fullfile(hdr.fpath,MetaTOld.perceiveFilename{i}), 'data')
                    movefile(fullfile(hdr.fpath,MetaTOld.perceiveFilename{i}), fullfile(hdr.fpath,MetaT.perceiveFilename{i}));
                    warning('updating filename part')
                end
            end
        end
        MetaT(rows_to_remove,:) = [];
        m=0;
        MetaTcopy=MetaT;
        for i = 1:height(MetaTcopy)
            if strcmp(MetaTcopy.part{i},'1') % search only if the part is 1 to stich the other parts

                %recording1 = MetaTcopy.perceiveFilename{i};
                %recording2 = strrep(MetaTcopy.perceiveFilename{i},'part-1','part-2');
                recording_basename = strrep(MetaTcopy.perceiveFilename{i},'part-1.mat','part-');
                %data = perceive_stitch_interruption_together(fullfile(hdr.fpath,recording1),fullfile(hdr.fpath,recording2));
                data = perceive_stitch_interruption_together(fullfile(hdr.fpath,recording_basename));

                MetaT = [MetaT(1:i+m,:); MetaT(i+m:end,:)];
                MetaT.part{i+m}='';
                MetaT.perceiveFilename{i+m}= data.fname{1};
                save(fullfile(hdr.fpath,data.fname{1}),'data');
                m=m+1;
            end
        end
    end
    if ~isempty(MetaT)
        writetable(MetaT,fullfile(hdr.fpath,[ sub{1} '_' ses '_metadata_' MetaT.report{1} '.xlsx']));
    end
end
disp('all done!')
end


function acq=check_stim(LAmp, RAmp, hdr)
% check stim whether the recording was stim OFF or stim ON based on the amplitude
% expand the acquisition to Burst

% check Burst settings
Cycling_mode = false;
if isfield(hdr.Groups, 'Initial')
    for i=1:length(hdr.Groups.Initial)
        if hdr.Groups.Initial(i).GroupSettings.Cycling.Enabled
            if Cycling_mode
                error('Two different cycling modes not in 1 json file implemented, contact Jojo Vanhoecke')
            else
                Cycling_mode = true;
                Cycling_OnDuration = hdr.Groups.Initial(i).GroupSettings.Cycling.OnDurationInMilliSeconds;
                Cycling_OffDuration = hdr.Groups.Initial(i).GroupSettings.Cycling.OffDurationInMilliSeconds;
                Cycling_Rate = hdr.Groups.Initial(i).ProgramSettings.RateInHertz;
            end
        end
    end
end
if isfield(hdr.Groups, 'Final')
    for i=1:length(hdr.Groups.Final)
        if hdr.Groups.Final(i).GroupSettings.Cycling.Enabled
            if Cycling_mode
                error('Two different cycling modes in 1 json file not implemented, contact Jojo Vanhoecke')
            else
                Cycling_mode = true;
                Cycling_OnDuration = hdr.Groups.Final(i).GroupSettings.Cycling.OnDurationInMilliSeconds;
                Cycling_OffDuration = hdr.Groups.Final(i).GroupSettings.Cycling.OffDurationInMilliSeconds;
                Cycling_Rate = hdr.Groups.Final(i).ProgramSettings.RateInHertz;
            end
        end
    end
end


LAmp(isnan(LAmp))=0;
RAmp(isnan(RAmp))=0;
LAmp=abs(LAmp);
RAmp=abs(RAmp);
if Cycling_mode
    if (sum(LAmp>0.1)) > (0.1*sum(LAmp==0)) && (sum(RAmp>0.1)) > (0.5*sum(RAmp==0))
        acq=['BurstB' 'DurOn' num2str(Cycling_OnDuration) 'DurOff' num2str(Cycling_OffDuration) 'Freq' num2str(Cycling_Rate) ];
    elseif (sum(LAmp>0.1)) > (0.1*sum(LAmp==0))
        acq=['BurstL' 'DurOn' num2str(Cycling_OnDuration) 'DurOff' num2str(Cycling_OffDuration) 'Freq' num2str(Cycling_Rate) ];
    elseif (sum(RAmp>0.1)) > (0.1*sum(RAmp==0))
        acq=['BurstR' 'DurOn' num2str(Cycling_OnDuration) 'DurOff' num2str(Cycling_OffDuration) 'Freq' num2str(Cycling_Rate) ];
    end
end
if ~exist('acq','var')
    if (mean(LAmp) > 0.5) && (mean(RAmp) > 0.5)
        acq='StimOnB';
    elseif (mean(LAmp) > 1)
        acq='StimOnL';
    elseif (mean(RAmp) > 1)
        acq='StimOnR';
    else
        acq='StimOff';
    end
end
end

function mod_ext=check_mod_ext(labels)
 %03, 13, 02, 12 are Ring contacts
 %1A_2A, 1B_2B, 1C_2C LEFT are SegmInter
 %1A_1B, 1A_1C, 1B_1C, 2A_2B, 2B_2C are SegmIntraL
if sum(contains(labels,'LEFT_RING'))>3 %usually 6 or 4
    mod_ext = 'RingL';
elseif sum(contains(labels,'LEFT_SEGMENT'))==6
    mod_ext = 'SegmIntraL';
elseif sum(contains(labels,'LEFT_SEGMENT'))==3
    mod_ext = 'SegmInterL';
elseif sum(contains(labels,'RIGHT_RING'))>3 %usually 6 or 4
    mod_ext = 'RingR';
elseif sum(contains(labels,'RIGHT_SEGMENT'))==6
    mod_ext = 'SegmIntraR';
elseif sum(contains(labels,'RIGHT_SEGMENT'))==3
    mod_ext = 'SegmInterR';
else
    if any(contains(labels,'0'))
        mod_ext = 'Ring';
    elseif sum(contains(labels,'A'))==3
        mod_ext = 'SegmIntra';
    elseif sum(contains(labels,'A'))==1
        mod_ext = 'SegmInter';
    else
        mod_ext = 'notspec';
        warning('the LMTD has no known modus: Bip,RingL,RingR,SegmInterL,SegmInterR,SegmIntraL,SegmIntraR,Ring')
    end
    if any(contains(labels,'LEFT')) && ~contains(mod_ext,'notspec')
        mod_ext = [mod_ext , 'L'];
    else 
        mod_ext = [mod_ext , 'R'];
    end
end
end

function MetaT =  metadata_to_table(MetaT, data)
fname=data.fname;
if contains(fname, ["LMTD","BrainSense","ISRing"])
    splitted_fname=split(fname,'_');
    ses = lower(splitted_fname{2}(5:9));
    if contains(splitted_fname{2}, 'MedOnOff')
        med = 'm9';
    elseif contains(splitted_fname{2}, 'MedOn')
        med = 'm1';
    elseif contains(splitted_fname{2}, 'MedOff')
        med = 'm0';
    end
    if contains(splitted_fname{4}, ["StimOn","Burst"])
        stim = 's1';
    elseif contains(splitted_fname{4}, 'StimOff')
        stim = 's0';
    else
        stim = 's9';
    end
    cond = [med stim];
    acq = splitted_fname{4}(5:end);
    task = splitted_fname{3}(6:end);
    nomatch = true;
    i=0;
    tobefound = ["Bip","RingL","RingR","SegmInterL","SegmInterR","SegmIntraL","SegmIntraR", "Ring", "notspec"];
    while nomatch
        i=i+1;
        if contains(fname, tobefound(i))
            contacts = tobefound(i);
            nomatch = false;
        end
    end
    [~, ori, ~] = fileparts(data.hdr.OriginalFile);
    cellarr = {[ori '.json'], fname,  ses, cond, task, contacts, fname(end-4), '', acq, 'keep'}; %add parts and stim settings
    MetaT = [MetaT; cellarr];
end
end