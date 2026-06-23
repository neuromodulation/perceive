function perceive(files, sub, sesMedOffOn01, extended, gui, localsettings_name)
%#function set_firstsample check_fullname check_stim onAppClose perceive_check_stim perceive_init_logging_if_deployed perceive_mcc_dependency_touch perceive_exe_directory_for_logging perceive_localsettings_apply_builtin_default
% MCC: pragma + perceive_mcc_dependency_touch() force packaging; string-based checks are not traced.
% Toolbox by Wolf-Julian Neumann
% Contributors Wolf-Julian Neumann, Tomas Sieger, Gerd Tinkhauser, Jennifer Behnke, Mansoureh Fahimi, Jonathan Kaplan, Jojo Vanhoecke (contact to Jojo Vanhoecke)
% This is an open research tool that is not intended for clinical purposes.

%% INPUT arguments overview
arguments
    files {mustBeA(files,["char","cell"])} = '';
    % files:
    % files e.g. ["", 'Report_Json_Session_Report_20200115T123657.json', {'Report_Json_Session_Report_20200115T123657.json','Report_Json_Session_Report_20200115T123658.json'}]
    % use e.g. perceive('Report_Json_Session_Report_20200115T123657.json')
    %
    % All input is optional, you can specify files as cell or character array
    % if files isn't specified or remains empty, it will automatically include all files in the current working directory
    % if no files in the current working directory are found, a you can choose files via the MATLAB uigetdir window.

    sub {mustBeA(sub,["char","cell","numeric"])} = '';
    % subject:
    % input e.g. ["", 7, 21 , "021", ... ]
    % use  e.g. perceive('Report_Json_Session_Report_20200115T123657.json','Charite_sub-001')
    % you can specify a subject ID for each file in case you want to follow an IRB approved naming scheme for file export
    %
    % if unspecified or left empy, the subjectID will be created from:
    % ImplantDate, first letter of disease type and target (e.g. sub-2020110DGpi)

    sesMedOffOn01 {mustBeMember(sesMedOffOn01,["","MedOff","MedOn","MedDaily","MedOff01","MedOn01","MedOff02","MedOn02","MedOff03","MedOn03","MedOffOn01","MedOffOn02","MedOffOn03","MedOnPostOpIPG","MedOffPostOpIPG","Unknown", "PostOp"])} = '';
    % session:
    % input e.g. ['','MedOff','MedOn','MedDaily','MedOff01','MedOn01','MedOff02','MedOn02','MedOff03','MedOn03','MedOffOn01','MedOffOn02','MedOffOn03','MedOnPostOpIPG','MedOffPostOpIPG','Unknown', 'PostOp']
    %

    extended {mustBeMember(extended,["","yes"])} = '';
    % '' means not extended, 'yes' means extended (default no)
    % gives an extensive output of chronic (=diagnosticdata.LFPTrendlogs), calibration, lastsignalcheck, diagnostic, impedance and snapshot data

    gui {mustBeMember(gui,["","yes"])} = '';
    % '' means no gui, 'yes' means gui (default no)

    localsettings_name  ='';
    % default is '', which is default
    % alternative: Charite Duesseldorf Wuerzburg or custom naming
    % names refer to the perceive\toolbox\config or any other file in your matlab folder which contains
    % perceive_localsettings_default.json
    % perceive_localsettings_charite.json
    % perceive_localsettings_duesseldorf.json
    % perceive_localsettings_wuerzburg.json
    % perceive_localsettings_"custom name".json with custom name to be
    % filled in, together with custom settings. Needs to be in matlab path, needs start with perceive_localsettings_*json, but does not need to be in the perceive\toolbox\config folder
    % possible datafields from Medtronic Percept are  ["","BrainSenseLfp","BrainSenseSurvey","BrainSenseTimeDomain","CalibrationTests","DiagnosticData","EventSummary","Impedance","IndefiniteStreaming","LfpMontageTimeDomain","MostRecentInSessionSignalCheck","PatientEvents"])} ='';

end
perceive_init_logging_if_deployed();
perceive_mcc_dependency_touch();
% % %% INPUT use examples:
% perceiveModular() % run all files in current directory or if none open explorer to select file
% perceiveModular('Report_Json_Session_Report_20200115T123657.json') % run this file
% perceiveModular({'Report_Json_Session_Report_20200115T123657.json','Report_Json_Session_Report_20200115T123658.json'}) % run these files
% perceiveModular('',5) % name subject sub-005
% perceiveModular('','23') % name subject sub-023
% perceiveModular('','') % automatic name subject based on ImplantDate, first letter of disease type and target (e.g. sub-2020110DGpi)
% perceiveModular('','','MedOff') % name session ses-MedOff
% perceiveModular('','','PostOp') % name session ses-PostOp input e.g. ['','MedOff','MedOn','MedDaily','MedOff01','MedOn01','MedOff02','MedOn02','MedOff03','MedOn03','MedOffOn01','MedOffOn02','MedOffOn03','MedOnPostOpIPG','MedOffPostOpIPG','Unknown', 'PostOp']
% perceiveModular('','','') % automatic name session based on the session date
% perceiveModular('','','','yes') % gives an extensive output of chronic, calibration, lastsignalcheck, diagnostic, impedance and snapshot data
% perceiveModular('','','','') % regular output (default)
% perceiveModular('','','','', 'yes') %use gui for renaming and concatenation at end of perceive output
% perceiveModular('','','','', '') % no gui (default)
% perceiveModular('','','','', '', '') % localsettings (default)
% % default is '', which is default
% alternative: Charite Duesseldorf Wuerzburg or custom naming
% names refer to the perceive\toolbox\config or any other file in your matlab folder which contains
% perceive_localsettings_default.json
% perceive_localsettings_charite.json
% perceive_localsettings_duesseldorf.json
% perceive_localsettings_wuerzburg.json
% perceive_localsettings_"custom name".json with custom name to be
% filled in, together with custom settings. Needs to be in matlab path, needs start with perceive_localsettings_*json, but does not need to be in the perceive\toolbox\config folder
% possible datafields from Medtronic Percept are  ["","BrainSenseLfp","BrainSenseSurvey","BrainSenseTimeDomain","CalibrationTests","DiagnosticData","EventSummary","Impedance","IndefiniteStreaming","LfpMontageTimeDomain","MostRecentInSessionSignalCheck","PatientEvents"])} ='';

%% OUTPUT Overview
% The script generates BIDS inspired subject and session folders with the
% ieeg format specifier. All time series data are being exported as
% FieldTrip .mat files, as these require no additional dependencies for creation.
% You can reformat with FieldTrip and SPM to MNE
% python and other formats (e.g. using fieldtrip2fiff([fullname '.fif'],data))

%% OUTPUT Recording type output naming
% Each of the FieldTrip data files correspond to a specific aspect of the Recording session:
% LMTD = LFP Montage Time Domain - BrainSenseSurvey
% IS = Indefinite Streaming - BrainSenseStreaming
% CT = Calibration Testing - Calibration Tests
% BSL = BrainSense LFP (2 Hz power average + stimulation settings)
% BSTD = BrainSense Time Domain (250 Hz raw data corresponding to the BSL file)
% BrainSenseBip = combination of BSL and BSTD into Brainsense with LFP signal/stim settings.

% %task = 'TASK'; %All types of tasks: Rest, RestTap, FingerTapL, FingerTapR, UPDRS, MovArtArms,MovArtStand,MovArtHead,MovArtWalk or any tasks added over the GUI or over the \toolbox\config\perceive_localsettings_"custom name".json
%acq = ''; %StimOff, StimOnL, StimOnR, StimOnB, Burst
%mod = ''; %BrainSense, IS, LMTD, Chronic + Bip Ring RingL RingR SegmIntraL SegmInterL SegmIntraR SegmInterR
%run = ''; %numeric

%% references
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

%% check dependencies
 % Call the function to handle the function availability
    perceive_set_dependencies();
%% perceive input

% creates a config struct that contains all files, subjectIDs and further settings
config = perceive_parse_args(files, sub, sesMedOffOn01, extended, gui);

% to avoid changing rest of the code, let us define files etc. (change later)
files         = config.files;
sub           = config.subject;
sesMedOffOn01 = config.session;
extended      = config.extended;
gui           = config.gui;
task          = config.task;
acq           = config.acq;
mod           = config.mod;
mod_elementnr = '';             %for this modality, which element number according to JavaScript in the js does current recording have?
run           = config.run;

%% set local settings
config=perceive_localsettings(localsettings_name, config);
datafields=config.datafields;
plotfields=config.plotfields;
%% set global settings
set(0,'DefaultFigureWindowStyle','normal') %prevents that figures are "docked" or "modal" as in live scripts
app.saveandexitButton.UserData = true; %prevents that the previous perceive GUI freezes

%% iterate over files
for idxFile = 1:length(files)
    filename = files{idxFile};
    disp(['RUNNING ' filename])

    % load and pseudonymize json + check whether is Percept Medtronic json
    js = perceive_load_json(config.files{idxFile});

    % check whether js file needs to be skipped (if not Percept Medtronic)
    if isempty(js)
        warning('Skipping file %s because it is not compatible with Percept Medtronic JSON format', filename)
        continue
    end

    % check dataversion
    config = perceive_check_dataversion(js,config);
    
    % build hdr struct containing relevant patient data
    hdr = perceive_extract_hdr(js, filename, config);

    % create metatable %determine
    MetaT = cell2table(cell(0,10),'VariableNames', {'report','perceiveFilename','session','condition','task','contacts','run','part','acq','remove'});

    alldata = {};
    disp(['SUBJECT ' hdr.subject])

    % rest some variables each for loop iterating over different json files
    % need to check which

    for idxDatafield = 1:length(datafields)

        if isfield(js,datafields{idxDatafield})

            data = js.(datafields{idxDatafield});

            if isempty(data)
                continue
            end

            %reset each loop the mod and the run nr
            mod='';
            run=1;

            % go through different datafields; extract and plot data
            switch datafields{idxDatafield}

                % add csv files by default

                case 'Impedance'

                    if config.extended
                        T = perceive_extract_impedance(data, hdr);
                        if any(strcmp(plotfields, 'Impedance'))
                            perceive_plot_impedance(T,hdr);
                        end
                        clear T
                    end

                case 'PatientEvents'

                    disp(fieldnames(data));

                case 'MostRecentInSessionSignalCheck'

                    if config.extended && ~isempty(data)
                        mod = 'mod-MostRecentSignalCheck';
                        signalcheck = perceive_extract_signalcheck(data, hdr, mod);
                        if any(strcmp(plotfields, 'MostRecentInSessionSignalCheck'))
                            perceive_plot_signalcheck(signalcheck);
                        end
                        perceive_export_signalcheck(signalcheck);
                    end

                case 'DiagnosticData'

                    if config.extended
                        hdr.fname = strrep(hdr.fname,'StimOff','StimX');

                        % handle LFPTrendLogs
                        if isfield(data, 'LFPTrendLogs')
                            alldata_diag = perceive_extract_diagnostic_lfptrend(data, hdr); %individual chronic data
                            alldata = [alldata, alldata_diag];

                            % plot combined LFP trend (L/R stim and LFP)
                            if config.extended && any(strcmp(plotfields, 'DiagnosticData')) %Plot total Chronic data
                                for idxTrendLog = 1:length(alldata_diag)
                                    if strcmp(alldata_diag{idxTrendLog}.datatype, 'DiagnosticData.LFPTrends') && ...
                                            isfield(alldata_diag{idxTrendLog}, 'label') && numel(alldata_diag{idxTrendLog}.label) == 4
                                        perceive_plot_diagnostic_lfptrend(alldata_diag{idxTrendLog});
                                        break; % plot only once
                                    end
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
                            if config.extended && any(strcmp(plotfields, 'DiagnosticData'))
                                for idxSnapshot = 1:length(alldata_diag_lfpsnap)
                                    perceive_plot_diagnostic_lfpsnapshot(alldata_diag_lfpsnap{idxSnapshot});
                                end
                            end

                        end

                    end

                case 'BrainSenseTimeDomain'

                    alldata_bstd = perceive_extract_bstd(data, hdr, config);
                    alldata = [alldata, alldata_bstd];

                case 'BrainSenseLfp'

                    [alldata_bsl, list_of_BSL] = perceive_extract_bsl(data, hdr);
                    alldata = [alldata, alldata_bsl];

                    % loop over bsl files
                    for idxBSL = 1:numel(alldata_bsl)
                        if any(strcmp(plotfields, 'BrainSenseLfp'))
                            perceive_plot_bsl_bipolar(alldata_bsl{idxBSL})
                        end
                        perceive_export_bsl_csv(alldata_bsl{idxBSL})
                    end

                case 'LfpMontageTimeDomain'

                    alldata_lmtd = perceive_extract_lfp_montage_time_domain(data, hdr, config);
                    alldata = [alldata, alldata_lmtd];

                case 'BrainSenseSurvey'

                    perceive_extract_brainsensesurvey(data, hdr); %this does not save any data

                case 'BrainSenseSurveys'
                    if config.DataVersion ~= 1.2 && config.DataVersion ~= 1.3
                        warning('For "BrainSenseSurveys": DataVersion: %.1f. Expected 1.2 or 1.3.', config.DataVersion);
                    else
                        warning('For "BrainSenseSurveys": DataVersion 1.2 or 1.3. data should be exact copy of "BrainSenseSurvey", and is only be processed under "BrainSenseSurvey"');
                    end
                    %continue, no processing here

                case 'BrainSenseSurveysTimeDomain'
                    alldata_bstd = perceive_extract_brainsensesurveystimedomain(data, hdr, plotfields);
                    alldata = [alldata, alldata_bstd];

                case 'IndefiniteStreaming'

                    alldata_is = perceive_extract_indefinitestreaming(data, hdr, config);
                    alldata = [alldata, alldata_is];



                case 'CalibrationTests'

                    if extended
                        alldata_ct = perceive_extract_calibrationtests(data, hdr);
                        alldata = [alldata, alldata_ct];
                    end

                case 'SenseChannelTests'

                    if extended
                        alldata_sct = perceive_extract_sensechanneltests(data, hdr, config);
                        alldata = [alldata, alldata_sct];
                    end
            end
        end
    end


    %nfile = fullfile(hdr.fpath,[hdr.fname '.jsoncopy']);
    %copyfile(files{a},nfile)

    %% count BrainSense files
    %counterBrainSense=0;
    % check counterBSL
    % counterBSL=0;
    % for idxDatafield = 1:length(alldata)
    %     if(contains(alldata{idxDatafield}.fname,'BSL'))
    %         counterBSL=counterBSL+1;
    %     end
    % end
    %% save all data
    for idxDatafield = 1:length(alldata)
        data=alldata{idxDatafield};
        fprintf('Currently processing: %s\n', data.fname);
        fullname = fullfile('.',hdr.fpath,data.fname);
        % create assertions about fullname
        check_fullname(fullname)
        % remove the optional 'keepfig' field (not to mess up the saved data)
        if isfield(data,'keepfig')
            data=rmfield(data,'keepfig');
        end

        % restore the data (incl. the optional 'keepfig' field)
        %data=alldata{idxDatafield};

        %% handle BSTD and BSL files to BrainSenseBip
        if any(regexp(data.fname,'BSTD'))
            %assert(counterBrainSense<=counterBSL, 'BrainSense could not be matched with BSL')
            %counterBrainSense=counterBrainSense+1;

            % save BSTD file separately
            run = 1;

            % Split fullname into folder + base + ext
            [folder, base, ext] = fileparts(fullname);

            % Construct first candidate: base_run-1.mat
            candidate = fullfile(folder, sprintf('%s_run-%d', base, run));

            % Increase run number until filename is unused
            while isfile([candidate '.mat'])
                run = run + 1;
                candidate = fullfile(folder, sprintf('%s_run-%d', base, run));
            end

            % Update fullname to the final chosen name
            fullname = candidate;

            % Update data.fname to match
            [~, fname] = fileparts(fullname);
            data.fname = [fname '.mat'];

            disp(['WRITING ' fullname '.mat as FieldTrip file.'])
            save([fullname '.mat'], 'data');

            %
            data.fname = strrep(data.fname,'BSTD','BrainSenseBip');
            data.fname = strrep(data.fname,'task-Rest','task-TASK');
            %data.fname = strrep(data.fname,'task-Rest',['task-TASK' num2str(counterBrainSense)]);
            fulldata = data; %need to replace fulldata to just data, in separate function

            %[folder,~,~] = fileparts(fullname);
            %pattern = fullfile(folder, '*BSL*.mat');
            %[~,~,list_of_BSLfiles] = perceive_ffind(pattern); %this needs to change, it should not search for the BSL, but know which one were written. Risk on taking to many BSL files from previous runs.

            if ~isempty(list_of_BSL)

                %% search for the matching BSL file
                found = false;
               
                for i = 1:length(alldata)
                    
                    % --- Check if it is a BSL file ---
                    if any(contains(alldata{i}.fname, list_of_BSL))
                        bsl = alldata{i};
                    else
                        continue %no BSL file
                    end
                    % --- Check SessionEndDate match ---
                    if ~isequal(bsl.hdr.OriginalFile, fulldata.hdr.OriginalFile)
                        continue
                    end

                    % --- Check FirstPackageDateTime within 1.501 seconds ---
                    t1 = datetime(bsl.FirstPacketDateTime, 'InputFormat','yyyy-MM-dd HH:mm:ss.SSS');
                    t2 = datetime(fulldata.FirstPacketDateTime, 'InputFormat','yyyy-MM-dd HH:mm:ss.SSS');

                    if abs(seconds(t1 - t2)) <= 1.501
                        % Bingo!
                        found = true;
                        break
                    end

                end

                % --- If no match found, throw error ---
                if ~found
                    warning('BSL file could not be matched BSTD data to create BrainSense.')
                    warning('No matching BSL could be found: same json file name but no FirstPackageDateTime within 1.5 seconds.');
                else
                    bsl.data = bsl; %change this later

                    %bsl=load(list_of_BSLfiles{counterBrainSense});

                    %if ~isequal(bsl.data.hdr.SessionEndDate, data.hdr.SessionEndDate)

                    %else
                    fulldata.BSLDateTime = [bsl.data.realtime(1) bsl.data.realtime(end)];

                    fulldata.label(3:6) = bsl.data.label;
                    fulldata.time{1}=fulldata.timeInSecDerivedFromTicks{1}; %the fulldate.time comes from perceive_extract_bstd d.time{1} = linspace(rel_start, rel_start + size(d.trial{1}, 2)/fsample, size(d.trial{1}, 2));
                    otime = bsl.data.time{1};
                    %% CRUCIAL PART where BSL is being added to fulldata of BSTD
                    % this snippet streches the BSL stream and put them
                    % over the BSTD stream, which is typically longer in
                    % the sense that is starts earlier and ends later.                                    
                    % It aligns the TicksInMSes
                    % to the same time point, and then crops the trials
                    % The first TicksInMSes is stored in sampleinfo [1]
                    
                    BSTD_first_TickInMSes = fulldata.sampleinfo(1);
                    BSL_first_TickInMSes = bsl.TicksInMs(1);
                    if (BSTD_first_TickInMSes < BSL_first_TickInMSes) && (BSTD_first_TickInMSes - BSL_first_TickInMSes) < 2500
                                            starttimedifference_sec = (BSL_first_TickInMSes - BSTD_first_TickInMSes)/1000;
                    elseif (BSTD_first_TickInMSes < BSL_first_TickInMSes)
                         warning('BSL recording started more than 2 seconds after BSTD.\n BSTD FirstPacketDateTime: %s\n BSL: %s', ...
                                fulldata.FirstPacketDateTime, bsl.FirstPacketDateTime);
                        error('BSDT_first_TickInMSes < BSL_first_TickInMSes is larger than 2.5 seconds, which should not be possible, please contact Jojo Vanhoecke (Prof Julian Neumann, julian.neumann@charite.de)')
                    else
                         warning(['BSL MTicks started before matched BSTD MTicks, which indicates unexpected json outcomes...' newline ...
                            'BSL FirstPacketDateTime: %s with TicksInMs: %d' newline ...
                            'BSTD FirstPacketDateTime: %s with TicksInMs: %d'], ...
                            bsl.FirstPacketDateTime, BSL_first_TickInMSes, fulldata.FirstPacketDateTime, BSTD_first_TickInMSes)
                        t1 = datetime(fulldata.FirstPacketDateTime, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
                        t2 = datetime(bsl.FirstPacketDateTime, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
                        diffSeconds = seconds(t2 - t1);
                        if diffSeconds >= 0
                            starttimedifference_sec = diffSeconds; % Store the time difference for alignment
                        else
                            warning('BSL recording started before BSTD, which should be impossible.\nfulldata.FirstPacketDateTime: %s\nbsl.FirstPacketDateTime: %s', ...
                                fulldata.FirstPacketDateTime, bsl.FirstPacketDateTime);
                            starttimedifference_sec = 0;
                        end
                    end
                    
                    % Find the indices of all numbers greater or equal to
                    % num, in order to let BSL start afer the time
                    % difference to BSTD
                    indices = find(fulldata.time{1} >= starttimedifference_sec);

                    if isempty(indices)
                        % If no number is greater or equal, return empty or handle accordingly
                        nextIndex = 1;
                    else
                        % Take the first index from those candidates (the next closest)
                        nextIndex = indices(1);
                    end
                    fulldata.timeAlignedTicks =fulldata.trial;
                    for c =1:4
                        fulldata.timeAlignedTicks{1}(c+2,:) = interp1(otime-otime(1),bsl.data.trial{1}(c,:),fulldata.time{1}-fulldata.time{1}(nextIndex),'nearest');
                    end
                    fulldata.trial=fulldata.timeAlignedTicks; %this is here in order to be able to checke fulldata time vs the interpolation in debugging mode
                    fulldata = rmfield(fulldata, 'timeAlignedTicks'); % clean up here
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
                    if extended && any(strcmp(plotfields, 'BrainSenseTimeDomain'))
                        perceive_plot_brainsensebip(fulldata, bsl, hdr)
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        % if size(fulldata.trial{1},2) > 250*20  %% code edited by Mansoureh Fahimi (changed 250 to 250*20)
                        %     figure('Units','centimeters','PaperUnits','centimeters','Position',[1 1 40 20])
                        %     subplot(2,2,1)
                        %     yyaxis left
                        %     plot(fulldata.time{1},fulldata.trial{1}(1,:))
                        %     ylabel('Raw amplitude')
                        %     if isfield(bsl.data.hdr.BSL.TherapySnapshot,'Left')
                        %         pkfreq = bsl.data.hdr.BSL.TherapySnapshot.Left.FrequencyInHertz;
                        %         pkfreq = bsl.data.hdr.BSL.TherapySnapshot.Left.FrequencyInHertz;
                        %     elseif isfield(bsl.data.hdr.BSL.TherapySnapshot,'Right')
                        %         pkfreq = bsl.data.hdr.BSL.TherapySnapshot.Right.FrequencyInHertz;
                        %     else
                        %         error('neither Left nor Right TherapySnapshot present');
                        %     end
                        %     hold on
                        % 
                        %     [tf,t,f]=perceive_raw_tf(fulldata.trial{1}(1,:),fulldata.fsample,128,.3);
                        %     mpow=nanmean(tf(perceive_sc(f,pkfreq-4):perceive_sc(f,pkfreq+4),:));
                        %     yyaxis right
                        %     ylabel('LFP and STIM amplitude')
                        %     plot(fulldata.time{1},fulldata.trial{1}(3,:))
                        %     %LAmp = fulldata.trial{1}(3,:);
                        %     xlim([fulldata.time{1}(1),fulldata.time{1}(end)])
                        %     hold on
                        %     plot(fulldata.time{1},fulldata.trial{1}(5,:).*1000)
                        %     plot(t,mpow.*1000)
                        %     title(strrep({fulldata.label{3},fulldata.label{5}},'_',' '))
                        %     axes('Position',[.34 .8 .1 .1])
                        %     box off
                        %     plot(f,nanmean(log(tf),2))
                        %     xlabel('F')
                        %     ylabel('P')
                        %     xlim([3 40])
                        % 
                        %     axes('Position',[.16 .8 .1 .1])
                        %     box off
                        %     plot(fulldata.time{1},fulldata.trial{1}(1,:))
                        %     xlabel('T'),ylabel('A')
                        %     xx = randi(round([fulldata.time{1}(1),fulldata.time{1}(end)]),1);
                        %     xlim([xx xx+1.5])
                        % 
                        %     subplot(2,2,3)
                        %     imagesc(t,f,log(tf)),axis xy,
                        %     xlabel('Time [s]')
                        %     ylabel('Frequency [Hz]')
                        % 
                        %     subplot(2,2,2)
                        %     yyaxis left
                        %     plot(fulldata.time{1},fulldata.trial{1}(2,:))
                        %     ylabel('Raw amplitude')
                        %     if isfield(bsl.data.hdr.BSL.TherapySnapshot,'Right')
                        %         pkfreq = bsl.data.hdr.BSL.TherapySnapshot.Right.FrequencyInHertz;
                        %     elseif isfield(bsl.data.hdr.BSL.TherapySnapshot,'Left')
                        %         pkfreq = bsl.data.hdr.BSL.TherapySnapshot.Left.FrequencyInHertz;
                        %     else
                        %         error('neither Left nor Right TherapySnapshot present');
                        %     end
                        %     hold on
                        %     [tf,t,f]=perceive_raw_tf(fulldata.trial{1}(2,:),fulldata.fsample,fulldata.fsample,.5);
                        %     mpow=nanmean(tf(perceive_sc(f,pkfreq-4):perceive_sc(f,pkfreq+4),:));
                        %     yyaxis right
                        %     ylabel('LFP and STIM amplitude')
                        %     plot(fulldata.time{1},fulldata.trial{1}(4,:))
                        %     %RAmp = fulldata.trial{1}(4,:);
                        %     xlim([fulldata.time{1}(1),fulldata.time{1}(end)])
                        %     hold on
                        %     plot(fulldata.time{1},fulldata.trial{1}(6,:).*1000)
                        %     plot(t,mpow.*1000)
                        % 
                        %     title(strrep({fulldata.fname,fulldata.label{4},fulldata.label{6}},'_',' '))
                        %     %%
                        %     axes('Position',[.78 .8 .1 .1])
                        %     box off
                        %     plot(f,nanmean(log(tf),2))
                        %     xlim([3 40])
                        %     xlabel('F')
                        %     ylabel('P')
                        % 
                        %     axes('Position',[.6 .8 .1 .1])
                        %     box off
                        %     plot(fulldata.time{1},fulldata.trial{1}(2,:))
                        %     xlabel('T'),ylabel('A')
                        %     xlim([xx xx+1.5])
                        % 
                        %     subplot(2,2,4)
                        %     imagesc(t,f,log(tf)),axis xy,
                        %     xlabel('Time [s]')
                        %     ylabel('Frequency [Hz]')
                        % 
                        %     perceive_print(fullfile('.',hdr.fpath, fulldata.fname))
                        % else
                        %     disp('The recording was less than 20 seconds. There is a potential problem: a figure got not created, but the code below would print the current figure (which holds something else than the current ''data'')!');
                        %     disp('Please, review it when missing.');
                        % end
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
                    %fullname = [fullname '_run-' num2str(run)];
                    while isfile([fullname '.mat'])
                        run = run+1;
                        fullname = (regexp(fullname, '.*_run-','match'));
                        fullname = [fullname{1} num2str(run)];
                    end
                    [~,fname,~] = fileparts(fullname);
                    data.fname = [fname '.mat'];
                    disp(['WRITING ' fullname ' as FieldTrip file.'])
                    save([fullname],'data')
                    if sesMedOffOn01
                        MetaT= perceive_metadata_to_table(MetaT,data);
                    end
                end
            end
            % future to be implemented: removed current BSL from
            % list_of_BSL. Then at the end: check whether any BSL are
            % remaining
            %% no BSTD, so save the data
        else

            %% create plot for LMTD and change name
            if contains(fullname,'LMTD')
                mod_ext=perceive_check_mod_ext(data.label);
                fullname = strrep(fullname,'mod-LMTD',['mod-LMTD' mod_ext]);
                data.fname = strrep(data.fname,'mod-LMTD',['mod-LMTD' mod_ext]);
                if any(strcmp(plotfields, 'LfpMontageTimeDomain'))
                    perceive_plot_raw_signals(data); % for LMTD
                    perceive_print(fullname);
                end
            elseif any(extended) && ~isempty(plotfields)
                if any(strcmp(plotfields, data.datatype))
                    perceive_plot_raw_signals(data); % for all data
                    perceive_print(fullname);
                end
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
            %%% add the new tasks names
            for i = 1:height(MetaT) %update the task name
                % Concatenate existing taskItems with MetaT.task
                mergedTasks = [config.taskItems(:); MetaT.task(:)];

                %  remove duplicates, preserve order
                [~,idx] = unique(mergedTasks,'stable');
                config.taskItems = mergedTasks(idx);
            end

            disp(['OPENING GUI' newline 'now confirm or adapt file naming through the GUI'])

            % Launch the App Designer GUI
            app = perceive_gui(MetaT, config);

            % Ensure orderly shutdown if the user closes the window
            app.UIFigure.CloseRequestFcn = @(src,event) onAppClose(app);

            try
                % Block until Save & Exit button or CloseRequestFcn changes UserData
                waitfor(app.saveandexitButton,'UserData');

                % Retrieve updated MetaT from the app
                MetaT = app.MetaT;

            catch ME
                % Handle unexpected errors or closure
                disp('App closed or an error occurred.');
                if isvalid(app)
                    delete(app);
                end
                rethrow(ME); % optional: rethrow to see the error in MATLAB
            end

            % Reset UserData so next run won't hang
            if isvalid(app) && isprop(app.saveandexitButton,'UserData')
                app.saveandexitButton.UserData = [];
            end

            % Delete the app object cleanly
            if isvalid(app)
                delete(app);
            end

            %else
            %    error('I need to check the config localsettings by JV')
            %%
            % if localsettings.check_gui_tasks
            %     if height(MetaT)==length(localsettings.mod)
            %
            %         for i = 1:height(MetaT) %update the task name
            %             if contains(MetaT.perceiveFilename{i},'TASK')
            %                 assert(contains(MetaT.perceiveFilename{i},localsettings.mod{i}))
            %                 MetaT.perceiveFilename{i}=replace(MetaT.perceiveFilename{i},['TASK' digitsPattern(1) '_'],localsettings.task{i});
            %             end
            %         end
            %     elseif all(strcmp(localsettings.task, 'Rest'))
            %         for i = 1:height(MetaT)
            %             assert(contains(MetaT.perceiveFilename{i},'Rest'))
            %
            %         end
            %     else
            %         assert( height(MetaT)==length(localsettings.mod), 'Tasks and mods not listed the same as in json file')
            %     end
            % end
            % if localsettings.check_gui_med %remove the recordings with different medication settings
            %     if any(localsettings.remove_med)
            %         assert( height(MetaT)==length(localsettings.remove_med))
            %         for i = 1:height(MetaT)
            %             if localsettings.remove_med(i)
            %                 MetaT.remove{i}=replace('keep','REMOVE');
            %             end
            %         end
            %     end
            % end
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
                    warning('updating filename part\nOld filename: %s\nNew filename: %s', ...
                        MetaTOld.perceiveFilename{i}, MetaT.perceiveFilename{i});
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

        if config.convert2bids
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
end

