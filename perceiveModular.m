function perceiveModular(files, sub, sesMedOffOn01, extended, gui, localsettings)
% HACKATHON
% https://github.com/neuromodulation/perceive
% Toolbox by Wolf-Julian Neumann
% v1.0 update by J Vanhoecke
% Merge requests from Jennifer Behnke and Mansoureh Fahimi
% Contributors Wolf-Julian Neumann, Tomas Sieger, Gerd Tinkhauser
% This is an open research tool that is not intended for clinical purposes.
%F
% INPUT:
% file          ["", 'Report_Json_Session_Report_20200115T123657.json', {'Report_Json_Session_Report_20200115T123657.json','Report_Json_Session_Report_20200115T123658.json'}, ...]
% sub           ["", 7, 21 , "021", ... ]
% sesMedOffOn01 ["","MedOff01","MedOn01","MedOff02","MedOn02","MedOff03","MedOn03","MedOffOn01"]
% extended      ["","yes"] %% gives an extensive output of chronic, calibration, lastsignalcheck, diagnostic, impedance and snapshot data
% gui           ["","yes"] %% gives option to skip gui by default settings
%% INPUT
    % files:
    % All input is optional, you can specify files as cell or character array
    % (e.g. files = 'Report_Json_Session_Report_20200115T123657.json')
    % if files isn't specified or remains empty, it will automatically include
    % all files in the current working directory
    % if no files in the current working directory are found, a you can choose
    % files via the MATLAB uigetdir window.

    % sub:
    % you can specify a subject ID for each file in case you want to follow an
    % IRB approved naming scheme for file export
    % (e.g. run perceive('Report_Json_Session_Report_20200115T123657.json','Charite_sub-001')
    % if unspecified or left empy, the subjectID will be created from:
    % ImplantDate, first letter of disease type and target (e.g. sub-2020110DGpi)
    
    %task = 'TASK'; %All types of tasks: Rest, RestTap, FingerTapL, FingerTapR, UPDRS, MovArtArms,MovArtStand,MovArtHead,MovArtWalk
    %acq = ''; %StimOff, StimOnL, StimOnR, StimOnB, Burst
    %mod = ''; %BrainSense, IS, LMTD, Chronic + Bip Ring RingL RingR SegmIntraL SegmInterL SegmIntraR SegmInterR
    %run = ''; %numeric
    
    % '' means not extended, 'yes' means extended (default no)

    % '' means no gui, 'yes' means gui (default yes)

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

% for modalities see white paper: https://www.medtronic.com/content/dam/medtronic-wide/public/western-europe/products/neurological/percept-pc-neurostimulator-whitepaper.pdf
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

%ubersichtzeit = table('Size',[1 8],'VariableNames',{'fname','FirstPackagetime','TicksMSecStart','TicksMSecEnd','TDTimeStart','TDTimeEnd','SumGlobalPackages','Triallength'},'VariableTypes',{'string','string','double','double','double','double','double','double'}) 
%% perceive input

% creates a config struct that contains all files, subjectIDs and further settings
config = perceive_parse_args(files, sub, sesMedOffOn01, extended, gui, localsettings);

% to avoid changing rest of the code, let us define files etc. (change later)
files         = config.files;
sub           = config.subject;
sesMedOffOn01 = config.session;
extended      = config.extended;
gui           = config.gui;
localsettings = config.localsettings;
task          = config.task;
acq           = config.acq;
mod           = config.mod;
run           = config.run;

%% set local settings
localsettings=perceive_localsettings(localsettings);
datafields=localsettings.datafields;

%% iterate over files
for idxFile = 1:length(files)
    filename = files{idxFile};
    disp(['RUNNING ' filename])

    % load and pseudonymize json
    js = perceive_load_json(config.files{idxFile});

    % build hdr struct containing relevant patient data
    hdr = perceive_extract_hdr(js, filename, config);

    % create metatable %determine
    MetaT = cell2table(cell(0,10),'VariableNames', {'report','perceiveFilename','session','condition','task','contacts','run','part','acq','remove'});
    
    alldata = {};
    disp(['SUBJECT ' hdr.subject])

    for idxDatafield = 1:length(datafields)

        if isfield(js,datafields{idxDatafield})

            data = js.(datafields{idxDatafield});

            if isempty(data)
                continue
            end

            mod='';
            run=1;
            counterBSL=0;

            % go through different datafields; extract and plot data
            switch datafields{idxDatafield}

                % add csv files by default

                case 'Impedance'

                    if config.extended
                        T = perceive_extract_impedance(data, hdr);
                        perceive_plot_impedance(T,hdr);
                        clear T
                    end

                case 'PatientEvents'

                    disp(fieldnames(data));

                case 'MostRecentInSessionSignalCheck'

                    if config.extended && ~isempty(data)
                        mod = 'mod-MostRecentSignalCheck';
                        signalcheck = perceive_extract_signalcheck(data, hdr, mod);
                        perceive_plot_signalcheck(signalcheck);
                        perceive_export_signalcheck(signalcheck);
                    end

                case 'DiagnosticData'

                    if config.extended
                        hdr.fname = strrep(hdr.fname,'StimOff','StimX');

                        % handle LFPTrendLogs
                        if isfield(data, 'LFPTrendLogs')
                            alldata_diag = perceive_extract_diagnostic_lfptrend(data, hdr);
                            alldata = [alldata, alldata_diag];

                            % plot combined LFP trend (L/R stim and LFP)
                            for idxTrendLog = 1:length(alldata_diag)
                                if strcmp(alldata_diag{idxTrendLog}.datatype, 'DiagnosticData.LFPTrends') && ...
                                        isfield(alldata_diag{idxTrendLog}, 'label') && numel(alldata_diag{idxTrendLog}.label) == 4
                                    perceive_plot_diagnostic_lfptrend(alldata_diag{idxTrendLog});
                                    break; % plot only once
                                end
                            end
                        end

                        % handle LfpFrequencySnapshotEvents
                        if isfield(data, 'LfpFrequencySnapshotEvents')

                            alldata_diag_lfpsnap = perceive_extract_diagnostic_lfpsnapshot(data.LfpFrequencySnapshotEvents, hdr);
                            
                            % nothing is appended to alldata in current version
                            % maybe for future: append to alldata container
                            % alldata = [alldata, alldata_diag_lfpsnap];

                            % plot every snapshot
                            for idxSnapshot = 1:length(alldata_diag_lfpsnap)
                                perceive_plot_diagnostic_lfpsnapshot(alldata_diag_lfpsnap{idxSnapshot});
                            end

                        end
                      
                    end

                case 'BrainSenseTimeDomain'

                    alldata_bstd = perceive_extract_bstd(data, hdr, config);
                    alldata = [alldata, alldata_bstd];

                case 'BrainSenseLfp'
                    
                    [alldata_bsl, ~] = perceive_extract_bsl(data, hdr);
                    alldata = [alldata, alldata_bsl];

                    % loop over bsl files
                    for idxBSL = 1:numel(alldata_bsl)
                        perceive_plot_bsl_bipolar(alldata_bsl{idxBSL})
                        perceive_export_bsl_csv(alldata_bsl{idxBSL})
                    end

                case 'LfpMontageTimeDomain'

                    alldata_lmtd = perceive_extract_lfp_montage_time_domain(data, hdr, config, idxDatafield);
                    alldata = [alldata, alldata_lmtd];

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

                case 'BrainSenseSurveys'
                    %continue
                    %
                    % I suppose this is now handled in'BrainSenseSurveysTimeDomain' and can be removed?

                case 'BrainSenseSurveysTimeDomain'

                    ElectrodeSurvey=data{1};
                    ElectrodeIdentifier=data{2};
                    assert(strcmp(ElectrodeSurvey.SurveyMode,'ElectrodeSurvey'))
                    assert(strcmp(ElectrodeIdentifier.SurveyMode,'ElectrodeIdentifier'))
                    
                    if ~isfield(js, 'LfpMontageTimeDomain') %ElectrodeSurvey is the same as LMTD
                        data=ElectrodeSurvey.ElectrodeSurvey;
    
                        FirstPacketDateTime = strrep(strrep({data(:).FirstPacketDateTime},'T',' '),'Z','');
                        runs = unique(FirstPacketDateTime);
    
                        [tmp1]=split({data(:).Channel}', regexpPattern("(_AND_)|((?<!.*_.*)_(?!.*_AND_.*))"));
                        ch1 = strrep(strrep(strrep(strrep(strrep(strrep(strrep(tmp1(:,1),'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3'),'_A','A'),'_B','B'),'_C','C'); % ch1 replaces ZERO to int 0 etc of first part before AND (tmp1(:,1))
                        ch2 = strrep(strrep(strrep(strrep(strrep(strrep(strrep(strrep(strrep(tmp1(:,2),'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3'),'LEFTS','L'),'RIGHTS','R'),'_A','A'),'_B','B'),'_C','C'); % ch2 replaces ZERO to int 0 etc of second part after AND (tmp1(:,1))
    
                        % side = strrep(strrep(strtok(tmp2,'_'),'LEFT','L'),'RIGHT','R');
                        % Channel = strcat(hdr.chan,'_',side,'_', ch1, ch2);
                        Channel = strcat(hdr.chan,'_', ch1,'_', ch2); % taken out "side" so RIGHT and LEFT will stay the same, no transformation to R and L
    
                        fsample = data.SampleRateInHz;
    
                        if length(runs)>1 %assert that data is not empty
                            for c = 1:length(runs)
                                i=perceive_ci(runs{c},FirstPacketDateTime);
                                d=[];
                                d.hdr = hdr;
                                d.datatype = datafields{idxDatafield};
                                d.fsample = fsample;
                                tmp = [data(i).TimeDomainDatainMicroVolts]';
                                d.trial{1} = [tmp];
                                d.label=Channel(i);
                                d.hdr.label = d.label;
                                d.hdr.Fs = d.fsample;
                                d.time=linspace(seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')-hdr.d0),seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')-hdr.d0)+size(d.trial{1},2)/fsample,size(d.trial{1},2));
                                d.time={d.time};
                                mod = 'mod-ES';
                                mod_ext=perceive_check_mod_ext(d.label);
                                mod = [mod mod_ext];
                                d.fname = [hdr.fname '_' mod];
                                d.fnamedate = [char(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS','format','yyyyMMddhhmmss')), '_',num2str(c)];
                                % TODO: set if needed:
                                %d.keepfig = false; % do not keep figure with this signal open
                                %d=call_ecg_cleaning(d,hdr,d.trial{1});
                                perceive_plot_raw_signals(d);
                                perceive_print(fullfile(hdr.fpath,d.fname));
                                alldata{length(alldata)+1} = d;
                            end
                        end
                    end
                    data=ElectrodeIdentifier.ElectrodeIdentifier;
                    for c = 1:length(data)
                        str=data(c).Channel;
                        str=strrep(str, 'ELECTRODE_', '');
                        data(c).Channel = [str '_' upper(data(c).Hemisphere) ];
                    end

                    FirstPacketDateTime = strrep(strrep({data(:).FirstPacketDateTime},'T',' '),'Z','');
                    runs = unique(FirstPacketDateTime);

                    [tmp1]=split({data(:).Channel}', regexpPattern("(_AND_)|((?<!.*_.*)_(?!.*_AND_.*))"));
                    ch1 = strrep(strrep(strrep(strrep(strrep(strrep(strrep(tmp1(:,1),'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3'),'_A','A'),'_B','B'),'_C','C'); % ch1 replaces ZERO to int 0 etc of first part before AND (tmp1(:,1))
                    ch2 = strrep(strrep(strrep(strrep(strrep(strrep(strrep(strrep(strrep(tmp1(:,2),'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3'),'LEFTS','L'),'RIGHTS','R'),'_A','A'),'_B','B'),'_C','C'); % ch2 replaces ZERO to int 0 etc of second part after AND (tmp1(:,1))

                    % side = strrep(strrep(strtok(tmp2,'_'),'LEFT','L'),'RIGHT','R');
                    % Channel = strcat(hdr.chan,'_',side,'_', ch1, ch2);
                    Channel = strcat(hdr.chan,'_', ch1,'_', ch2); % taken out "side" so RIGHT and LEFT will stay the same, no transformation to R and L

                    fsample = data.SampleRateInHz;
                    if length(runs)>1 %assert that data is not empty
                        for c = 1:length(runs)
                            i=perceive_ci(runs{c},FirstPacketDateTime);
                            d=[];
                            d.hdr = hdr;
                            d.datatype = datafields{idxDatafield};
                            d.fsample = fsample;
                            tmp = [data(i).TimeDomainDatainMicroVolts]';
                            d.trial{1} = [tmp];
                            d.label=Channel(i);
                            d.hdr.label = d.label;
                            d.hdr.Fs = d.fsample;
                            d.time=linspace(seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')-hdr.d0),seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')-hdr.d0)+size(d.trial{1},2)/fsample,size(d.trial{1},2));
                            d.time={d.time};
                            mod = 'mod-EI';
                            mod_ext=perceive_check_mod_ext(d.label);
                            mod = [mod mod_ext];
                            d.fname = [hdr.fname '_' mod];
                            d.fnamedate = [char(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS','format','yyyyMMddhhmmss')), '_',num2str(c)];
                            % TODO: set if needed:
                            %d.keepfig = false; % do not keep figure with this signal open
                            %d=perceive_call_ecg_cleaning(d,hdr,d.trial{1});
                            perceive_plot_raw_signals(d);
                            perceive_print(fullfile(hdr.fpath,d.fname));
                            alldata{length(alldata)+1} = d;
                        end
                    end

                case 'IndefiniteStreaming'

                    clear TicksInMses
                    FirstPacketDateTime = strrep(strrep({data(:).FirstPacketDateTime},'T',' '),'Z','');
                    runs = unique(FirstPacketDateTime);
                    fsample = data.SampleRateInHz;

                    Pass = {data(:).Pass};
                    tmp =  {data(:).GlobalSequences};
                    for c = 1:length(tmp) %missing
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
                    for c = 1:length(tmp) %missing
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
                        d.datatype = datafields{idxDatafield};
                        d.hdr.IS.Pass=strrep(strrep(unique(strtok(Pass(i),'_')),'FIRST','1'),'SECOND','2');
                        d.hdr.IS.GlobalSequences=GlobalSequences(i,:);
                        d.hdr.IS.GlobalPacketSizes=GlobalPacketSizes(i,:);
                        d.hdr.IS.FirstPacketDateTime = runs{c};
                        x=find(ismember(i, find(isDataMissing)));
                        if ~isempty(x)
                            warning('missing packages detected, will interpolate to replace missing data') %missing
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
                                warning('The missing packages could not be computed. Interpolation failed.') %missing
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
                        %firstsample = 1+round(fsample*seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')-datetime(FirstPacketDateTime{1},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')));
                        firstsample = set_firstsample(data(c).TicksInMses);
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
                        if config.ecg_cleaning
                            d=call_ecg_cleaning(d,hdr,d.trial{1});
                        end
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
                            d.datatype = datafields{idxDatafield};
                            d.hdr.CT.Pass=strrep(strrep(unique(strtok(Pass(i),'_')),'FIRST','1'),'SECOND','2');
                            d.hdr.CT.GlobalSequences=GlobalSequences(i,:);
                            d.hdr.CT.GlobalPacketSizes=GlobalPacketSizes(i,:);
                            d.hdr.CT.FirstPacketDateTime = runs{c};

                            d.label=Channel(i);
                            d.trial{1} = raw;

                            d.time{1} = linspace(seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')-hdr.d0),seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')-hdr.d0)+size(d.trial{1},2)/fsample,size(d.trial{1},2));

                            d.fsample = fsample;
                            %firstsample = 1+round(fsample*seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')-datetime(FirstPacketDateTime{1},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')));
                            firstsample = set_firstsample(data(c).TicksInMses);
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
                            d.datatype = datafields{idxDatafield};
                            d.hdr.IS.Pass=strrep(strrep(unique(strtok(Pass(i),'_')),'FIRST','1'),'SECOND','2');
                            d.hdr.IS.GlobalSequences=GlobalSequences(i,:);
                            d.hdr.IS.GlobalPacketSizes=GlobalPacketSizes(i,:);
                            d.hdr.IS.FirstPacketDateTime = runs{c};
                            tmp = raw(i,:);
                            d.trial{1} = [tmp];
                            d.label=Channel(i);

                            d.time{1} = linspace(seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')-hdr.scd0),seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')-hdr.scd0)+size(d.trial{1},2)/fsample,size(d.trial{1},2));
                            d.fsample = fsample;
                            %firstsample = 1+round(fsample*seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')-datetime(FirstPacketDateTime{1},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')));
                            firstsample = set_firstsample(data(c).TicksInMses);
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

    %% count BrainSense files
    counterBrainSense=0;
    % check counterBSL
    counterBSL=0;
    for idxDatafield = 1:length(alldata)
        if(contains(alldata{idxDatafield}.fname,'BSL'))
            counterBSL=counterBSL+1;
        end
    end
    %% save all data
    for idxDatafield = 1:length(alldata)
        fullname = fullfile('.',hdr.fpath,alldata{idxDatafield}.fname);
        data=alldata{idxDatafield};
        % remove the optional 'keepfig' field (not to mess up the saved data)
        if isfield(data,'keepfig')
            data=rmfield(data,'keepfig');
        end

        % restore the data (incl. the optional 'keepfig' field)
        data=alldata{idxDatafield};

        %% handle BSTD and BSL files to BrainSenseBip
        if any(regexp(data.fname,'BSTD'))
            assert(counterBrainSense<=counterBSL, 'BrainSense could not be matched with BSL')
            counterBrainSense=counterBrainSense+1;

            data.fname = strrep(data.fname,'BSTD','BrainSenseBip');
            data.fname = strrep(data.fname,'task-Rest',['task-TASK' num2str(counterBrainSense)]);
            fulldata = data;

            [folder,~,~] = fileparts(fullname);
            pattern = fullfile(folder, '*BSL*.mat');
            [~,~,list_of_BSLfiles] = perceive_ffind(pattern);

            if ~isempty(list_of_BSLfiles)
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
                    %user = memory; user.MemUsedMATLAB < 9^100 %corresponds with 9MB
                    if extended

                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        if size(fulldata.trial{1},2) > 250*20  %% code edited by Mansoureh Fahimi (changed 250 to 250*20)
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
                            disp('The recording was less than 20 seconds. There is a potential problem: a figure got not created, but the code below would print the current figure (which holds something else than the current ''data'')!');
                            disp('Please, review it when missing.');
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
                        fullname = (regexp(fullname, '.*_run-','match'));
                        fullname = [fullname{1} num2str(run)];
                    end
                    [~,fname,~] = fileparts(fullname);
                    data.fname = [fname '.mat'];
                    disp(['WRITING ' fullname '.mat as FieldTrip file.'])
                    save([fullname '.mat'],'data')
                    if sesMedOffOn01
                        MetaT= perceive_metadata_to_table(MetaT,data);
                    end
                end
            end
            %% no BSTD, so save the data
        else

            %% create plot for LMTD and change name
            if contains(fullname,'LMTD')
                mod_ext=perceive_check_mod_ext(data.label);
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
                fullname = (regexp(fullname, '.*_run-','match'));
                fullname = [fullname{1} num2str(run)];
            end
            [~,fname,~] = fileparts(fullname);
            data.fname = [fname '.mat'];
            disp(['WRITING ' fullname '.mat as FieldTrip file.'])
            save([fullname '.mat'],'data');
            if sesMedOffOn01
                MetaT= perceive_metadata_to_table(MetaT,data);
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

    %% post-labelling
    if ~isempty(sesMedOffOn01) && height(MetaT)>0
        MetaTOld = MetaT;

        if gui
            app=perceive_gui(MetaT);
            waitfor(app.saveandcontinueButton,'UserData')
            MetaT=app.MetaT;
            app.delete;
        else
            %%
            if localsettings.check_gui_tasks
                if height(MetaT)==length(localsettings.mod)
                
                    for i = 1:height(MetaT) %update the task name
                        if contains(MetaT.perceiveFilename{i},'TASK')
                            assert(contains(MetaT.perceiveFilename{i},localsettings.mod{i}))
                            MetaT.perceiveFilename{i}=replace(MetaT.perceiveFilename{i},['TASK' digitsPattern(1) '_'],localsettings.task{i});
                        end
                    end
                elseif all(strcmp(localsettings.task, 'Rest'))
                    for i = 1:height(MetaT) 
                          assert(contains(MetaT.perceiveFilename{i},'Rest'))
                    
                    end
                else
                    assert( height(MetaT)==length(localsettings.mod), 'Tasks and mods not listed the same as in json file')
                end
            end
            if localsettings.check_gui_med %remove the recordings with different medication settings
                if any(localsettings.remove_med)
                    assert( height(MetaT)==length(localsettings.remove_med))
                    for i = 1:height(MetaT)
                        if localsettings.remove_med(i)
                            MetaT.remove{i}=replace('keep','REMOVE');
                        end
                    end
                end
            end
        end

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
                %data = perceive_stitch_interruption_together_TDtime(fullfile(hdr.fpath,recording_basename));

                MetaT = [MetaT(1:i+m,:); MetaT(i+m:end,:)];
                MetaT.part{i+m}='';
                MetaT.perceiveFilename{i+m}= data.fname{1};
                save(fullfile(hdr.fpath,data.fname{1}),'data');
                m=m+1;
            end
        end
%% conversion to BIDS
         
        if localsettings.convert2bids
            for i = 1:height(MetaT)
                cfg=struct();
                load(fullfile(hdr.fpath,MetaT.perceiveFilename{i}),'data')
                entities = splitBIDSfilename(MetaT.perceiveFilename{i});
                cfg.method                  = 'convert';
                cfg.bidsroot                = fullfile(pwd);
                cfg.suffix                  = 'ieeg';
                cfg.sub                     = entities.sub;
                cfg.ses                     = entities.ses;
                cfg.task                    = entities.task;
                cfg.acq                     = entities.acq;
                cfg.mod                     = entities.mod;
                cfg.run                     = entities.run;
        
                cfg.ieeg.ElectricalStimulationParameters = data.hdr.js.Groups;
                cfg.ieeg.ElectricalStimulationParameters = removeField(cfg.ieeg.ElectricalStimulationParameters, 'SignalFrequencies');
                cfg.ieeg.ElectricalStimulationParameters = removeField(cfg.ieeg.ElectricalStimulationParameters, 'SignalPsdValues');
        
                %% save data
                if strcmp(cfg.mod,'BrainSenseBip')
                    data.label=data.label(:,end-1:end);
                    data.trial=data.trial{:}(end-1:end,:)';
                    data.hdr.chantype={'LFP','LFP'};
                end
                data2bids(cfg, data);
            end
        end
    end
    if ~isempty(MetaT)
        % writetable(MetaT,fullfile(hdr.fpath,[ sub(1) '_' ses '_' MetaT.report{1} '.xlsx'])); %throws error JK
        writetable(MetaT,fullfile(hdr.fpath,[ config.subject '_' config.session '_' MetaT.report{1} '.xlsx'])); % works for single subject - think of solution for single and multiple subjects
    end
end
disp('all done!')
%ubersichtzeit
end
