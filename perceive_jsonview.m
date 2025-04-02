function jstable = perceive_jsonview(js)

% filename='Report_Json_Session_Report_20250207T115214.json';
% filename='Report_Json_Session_Report_20250129T124347.json';
% filename='Report_Json_Session_Report_20250124T135228.json';
% filename='Report_Json_Session_Report_20250124T134817.json';
% filename='Report_Json_Session_Report_20250124T134809.json';
% filename='Report_Json_Session_Report_20250123T160500.json';
js = jsondecode(fileread(js));
warning('off', 'MATLAB:table:RowsAddedExistingVars')


% Define the headers
headers = {'session', 'modality', 'FirstPacketDateTime', 'Duration', 'GlobalPacketSize', 'TicksInMsesStart', 'TicksInMsesEnd'};

% Create an empty table with the specified headers and character data type
jstable = table('Size', [0, length(headers)], 'VariableTypes', [ repmat({'string'}, 1, length(headers)-3) , repmat({'double'}, 1, 3)], 'VariableNames', headers);


infofields = {'SessionDate','SessionEndDate','PatientInformation','DeviceInformation','BatteryInformation','LeadConfiguration','Stimulation','Groups','Stimulation','Impedance','PatientEvents','EventSummary','DiagnosticData'};
for b = 1:length(infofields)
if isfield(js,infofields{b})
    hdr.(infofields{b})=js.(infofields{b});
end
end
datafields = sort({'EventSummary','Impedance','MostRecentInSessionSignalCheck','BrainSenseLfp','BrainSenseTimeDomain','LfpMontageTimeDomain','IndefiniteStreaming','BrainSenseSurvey','CalibrationTests','PatientEvents','DiagnosticData','BrainSenseSurveysTimeDomain','BrainSenseSurveys'});

jstable.session(end+1) =js.SessionDate;


for b = 1:length(datafields)
    if isfield(js, datafields{b})
        data = js.(datafields{b});
        if isempty(data)
            continue
        end
        mod = '';
        run = 1;
        counterBSL = 0;
        switch datafields{b}
            case 'Impedance'
                % Insert your code for handling 'Impedance' data here
                disp('Processing Impedance data...');
            case 'EventSummary'
                % Insert your code for handling 'EventSummary' data here
                disp('Processing EventSummary data...');
            case 'MostRecentInSessionSignalCheck'
                % Insert your code for handling 'MostRecentInSessionSignalCheck' data here
                disp('Processing MostRecentInSessionSignalCheck data...');
            case 'BrainSenseLfp'
                % Insert your code for handling 'BrainSenseLfp' data here
                disp('Processing BrainSenseLfp data...');
                jstable.modality(end+1) ='BrainSenseLfp';
                for i=1:length(js.BrainSenseLfp)
                    if ~strcmp(jstable.FirstPacketDateTime(end),js.BrainSenseLfp(i).FirstPacketDateTime)
                    jstable.FirstPacketDateTime(end+1)=js.BrainSenseLfp(i).FirstPacketDateTime;
                    jstable.Duration(end)=ms_to_time(js.BrainSenseLfp(i).LfpData(end).TicksInMs-js.BrainSenseLfp(i).LfpData(1).TicksInMs);
                    end
                end
            case 'BrainSenseTimeDomain'
                % Insert your code for handling 'BrainSenseTimeDomain' data here
                disp('Processing BrainSenseTimeDomain data...');

                jstable.modality(end+1) ='BrainSenseTimeDomain';
                for i=1:length(js.BrainSenseTimeDomain)
                    if ~strcmp(jstable.FirstPacketDateTime(end),js.BrainSenseTimeDomain(i).FirstPacketDateTime)
                    jstable.FirstPacketDateTime(end+1)=js.BrainSenseTimeDomain(i).FirstPacketDateTime;
                    [first_num, last_num] = extract_numbers(js.BrainSenseTimeDomain(i).TicksInMses);
                    jstable.Duration(end)=ms_to_time(last_num-first_num);
                    jstable.GlobalPacketSize(end)=size(js.BrainSenseTimeDomain(i).TimeDomainData,1);
                    jstable.TicksInMsesStart(end)=first_num;
                    jstable.TicksInMsesEnd(end)=last_num;
                    end
                    
                    % ubersichtzeit.fname(end+1)=d.fname;
                    % ubersichtzeit.FirstPackagetime(end)=FirstPacketDateTime(i(1));
                    % ubersichtzeit.TicksMSecStart(end)     =TicksInMses(1);
                    % ubersichtzeit.TicksMSecEnd(end)     = TicksInMses(end);
                    % ubersichtzeit.SumGlobalPackages(end)     =sum(GlobalPacketSize);
                    % ubersichtzeit.Triallength(end)     = length(d.trial{1});
                end

            case 'LfpMontageTimeDomain'
                % Insert your code for handling 'LfpMontageTimeDomain' data here
                disp('Processing LfpMontageTimeDomain data...');
                jstable.modality(end+1) ='LfpMontageTimeDomain';
                for i=1:length(js.LfpMontageTimeDomain)
                    if ~strcmp(jstable.FirstPacketDateTime(end),js.LfpMontageTimeDomain(i).FirstPacketDateTime)
                    jstable.FirstPacketDateTime(end+1)=js.LfpMontageTimeDomain(i).FirstPacketDateTime;
                    jstable.Duration(end)=ms_to_time(length(js.LfpMontageTimeDomain(i).TimeDomainData)*4);
                    end
                end
            case 'IndefiniteStreaming'
                % Insert your code for handling 'IndefiniteStreaming' data here
                disp('Processing IndefiniteStreaming data...');
                jstable.modality(end+1) ='IndefiniteStreaming';
                for i=1:length(js.IndefiniteStreaming)
                    if ~strcmp(jstable.FirstPacketDateTime(end),js.IndefiniteStreaming(i).FirstPacketDateTime)
                    jstable.FirstPacketDateTime(end+1)=js.IndefiniteStreaming(i).FirstPacketDateTime;
                    [first_num, last_num] = extract_numbers(js.IndefiniteStreaming(i).TicksInMses);
                    jstable.Duration(end)=ms_to_time(last_num-first_num);
                    end
                end
            case 'BrainSenseSurvey'
                % Insert your code for handling 'BrainSenseSurvey' data here
                disp('Processing BrainSenseSurvey data...');
                jstable.modality(end+1) ='BrainSenseSurvey';
                for i=1:length(js.BrainSenseSurvey)
                    jstable.FirstPacketDateTime(end+1)=js.BrainSenseSurvey(i).FirstPacketDateTime;
                    [first_num, last_num] = extract_numbers(js.BrainSenseSurvey(i).TicksInMses);
                    jstable.Duration(end)=ms_to_time(last_num-first_num);
                end
            case 'CalibrationTests'
                % Insert your code for handling 'CalibrationTests' data here
                disp('Processing CalibrationTests data...');
            case 'PatientEvents'
                % Insert your code for handling 'PatientEvents' data here
                disp('Processing PatientEvents data...');
            case 'DiagnosticData'
                % Insert your code for handling 'DiagnosticData' data here
                disp('Processing DiagnosticData...');
                %this is chronic data

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
                            %d.time{1} = linspace(seconds(cdt(1)-hdr.d0),seconds(cdt(end)-hdr.d0),size(d.trial{1},2));
                            d.realtime{1} = cdt;
                            % if length(d.time{1})>1
                            %     d.fsample = abs(1/diff(d.time{1}(1:2)));
                            % else
                            %     warning('Only one data point recorded, assuming a sampling frequency of 1 / 10 minutes ~ 0.0017 Hz');
                            %     d.fsample = 1/600; % 10*60 sec = 10 minutes
                            % end
                            d.hdr.Fs = d.fsample; d.hdr.label = d.label;
                            % firstsample = d.time{1}(1); warning('firstsample is not exactly computed for chronic recordings')
                            % lastsample = d.time{1}(end);d.sampleinfo(1,:) = [firstsample lastsample];
                            mod= 'mod-ChronicLeft';
                            % hdr.fname = strrep(hdr.fname, 'task-Rest', 'task-None');
                            % d.fname = [hdr.fname '_' mod];
                            % d.fnamedate = [char(datetime(cdt(1),'format','yyyyMMddhhmmss'))];
                            % d.keepfig = false; % do not keep figure with this signal open (the number of LFPTrendLogs can be high)
                            %alldata{length(alldata)+1} = d;
                        end
                    %%
                    % add to table
                    jstable.modality(end+1) ='LFPTrendLogsChronicLeft';
                    jstable.FirstPacketDateTime(end)= datestr(cdt(1), 'yyyy-mm-ddTHH:MM:SS.FFFZ');
                    jstable.Duration(end)= datestr(cdt(end), 'yyyy-mm-ddTHH:MM:SS.FFFZ');
                    %%
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
                            %d.time{1} = linspace(seconds(cdt(1)-hdr.d0),seconds(cdt(end)-hdr.d0),size(d.trial{1},2));
                            d.realtime{1} = cdt;
                            % if length(d.time{1})>1
                            %     d.fsample = abs(1/diff(d.time{1}(1:2)))
                            % else
                            %     warning('Only one data point recorded, assuming a sampling frequency of 1 / 10 minutes ~ 0.0017 Hz');
                            %     d.fsample = 1/600; % 10*60 sec = 10 minutes
                            % end
                            % d.hdr.Fs = d.fsample; d.hdr.label = d.label;
                            % firstsample = d.time{1}(1); warning('firstsample is not exactly computed for chronic recordings')
                            % lastsample = d.time{1}(end);d.sampleinfo(1,:) = [firstsample lastsample];
                            mod = 'mod-ChronicRight';
                            % hdr.fname = strrep(hdr.fname, 'task-Rest', 'task-None');
                            % d.fname = [hdr.fname '_' mod];
                            % d.fnamedate = [char(datetime(cdt(1),'format','yyyyMMddhhmmss'))];
                            % d.keepfig = false; % do not keep figure with this signal open (the number of LFPTrendLogs can be high)
                            %alldata{length(alldata)+1} = d;
                        end
                    %%
                    % add to table
                    jstable.modality(end+1) ='LFPTrendLogsChronicRight';
                    jstable.FirstPacketDateTime(end)= datestr(cdt(1), 'yyyy-mm-ddTHH:MM:SS.FFFZ');
                    jstable.Duration(end)= datestr(cdt(end), 'yyyy-mm-ddTHH:MM:SS.FFFZ');
                    %%
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
                    firstsample = d.time{1}(1); warning('firstsample is not exactly computed for chronic recordings')
                    lastsample = d.time{1}(end);
                    d.sampleinfo(1,:) = [firstsample lastsample];
                    mod = 'mod-Chronic';
                    % hdr.fname = strrep(hdr.fname, 'task-Rest', 'task-None');
                    % d.fname = [hdr.fname '_' mod];
                    % d.fnamedate = [char(datetime(DT(1),'format','yyyyMMddhhmmss'))];
                    % % TODO: set if needed::
                    % %d.keepfig = false; % do not keep figure with this signal open
                    % alldata{length(alldata)+1} = d;
                    % 
                    % 
                    % figure('Units','centimeters','PaperUnits','centimeters','Position',[1 1 40 20])
                    % subplot(2,1,1)
                    % title({strrep(hdr.fname,'_',' '),'CHRONIC LEFT'})
                    % yyaxis left
                    % 
                    % scatter(DT,LFP(1,:),20,'filled','Marker','o')
                    % ylabel('LFP Amplitude')
                    % yyaxis right
                    % scatter(DT,STIM(1,:),20,'filled','Marker','s')
                    % ylabel('STIM Amplitude')
                    % xlabel('Time')
                    % subplot(2,1,2)
                    % yyaxis left
                    % scatter(DT,LFP(2,:),20,'filled','Marker','o')
                    % ylabel('LFP Amplitude')
                    % yyaxis right
                    % scatter(DT,STIM(2,:),20,'filled','Marker','s')
                    % title('RIGHT')
                    % xlabel('Time')
                    % ylabel('STIM Amplitude')
                    % %savefig(fullfile(hdr.fpath,[hdr.fname '_CHRONIC.fig']))
                    % perceive_print(fullfile(hdr.fpath,[hdr.fname '_CHRONIC']))

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
                        DTtable(c) = datetime(lfp.DateTime(1:end-1),'InputFormat','yyyy-MM-dd''T''HH:mm:ss');
                        if lfp.LFP && isfield(lfp,'LfpFrequencySnapshotEvents')
                            ids(c) = lfp.EventID;
                            DT(c) = datetime(lfp.DateTime(1:end-1),'InputFormat','yyyy-MM-dd''T''HH:mm:ss');
                            events{c} = lfp.EventName;
                            % if isfield(lfp.LfpFrequencySnapshotEvents,'HemisphereLocationDef_Left')
                            %     tmp = strsplit(strrep(lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Left.SenseID,'_AND',''),'.');
                            %     if isempty(tmp{1}) || isscalar(tmp)
                            %         tmp = {'','unknown'};
                            %     end
                            %     ch1 = strcat(hdr.chan,'_L_',strrep(strrep(strrep(strrep(strrep(tmp{2},'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3'),'_',''));
                            % else
                            %     ch1 = 'n/a';
                            % end
                            % if isfield(lfp.LfpFrequencySnapshotEvents,'HemisphereLocationDef_Right')
                            %     tmp = strsplit(strrep(lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Right.SenseID,'_AND',''),'.');
                            %     if isempty(tmp{1}) || isscalar(tmp)
                            %         tmp = {'','unknown'};
                            %     end
                            %     ch2 = strcat(hdr.chan,'_R_',strrep(strrep(strrep(strrep(strrep(tmp{2},'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3'),'_',''));
                            % else
                            %     ch2 = 'n/a';
                            % end
                            % chanlabels{c} = {ch1 ch2};
                            % if ~isfield(lfp.LfpFrequencySnapshotEvents,'HemisphereLocationDef_Left') && ~isfield(lfp.LfpFrequencySnapshotEvents,'HemisphereLocationDef_Right')
                            %     error('none of HemisphereLocationDef_Left / HemisphereLocationDef_Right appear in LfpFrequencySnapshotEvents');
                            % end
                            % if isfield(lfp.LfpFrequencySnapshotEvents,'HemisphereLocationDef_Left')
                            %     stimgroups{c} = lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Left.GroupId(end);
                            %     freq = lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Left.Frequency;
                            % else
                            %     stimgroups{c} = lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Right.GroupId(end);
                            %     freq = lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Right.Frequency;
                            % end
                            % if isfield(lfp.LfpFrequencySnapshotEvents,'HemisphereLocationDef_Left') && isfield(lfp.LfpFrequencySnapshotEvents,'HemisphereLocationDef_Right')
                            %     pow(:,1) = lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Left.FFTBinData;
                            %     pow(:,2) = lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Right.FFTBinData;
                            % else
                            %     if isfield(lfp.LfpFrequencySnapshotEvents,'HemisphereLocationDef_Left')
                            %         pow(:,1) = lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Left.FFTBinData;
                            %         pow(:,2) = 0*pow(:,1);
                            %     else
                            %         pow(:,2) = lfp.LfpFrequencySnapshotEvents.HemisphereLocationDef_Right.FFTBinData;
                            %         pow(:,1) = 0*pow(:,2);
                            %     end
                            % end
                            % Tpow.Frequency = freq;
                            % Tpow.(strrep([events{c} '_' num2str(c) '_' ch1 '_' char(datetime(DT(c),'Format','yyyMMddHHmmss'))],' ','')) = pow(:,1);
                            % Tpow.(strrep([events{c} '_' num2str(c) '_' ch2 '_' char(datetime(DT(c),'Format','yyyMMddHHmmss'))],' ','')) = pow(:,2);
                            % 
                            % 
                            % figure
                            % plot(freq,pow,'linewidth',2)
                            % legend(strrep(chanlabels{c},'_',' '))
                            % title({strrep(hdr.fname,'_',' ');char(DT(c));events{c};['STIM GROUP ' stimgroups{c}]})
                            % xlabel('Frequency [Hz]')
                            % ylabel('Power spectral density [uV^2/Hz]')
                            % %savefig(fullfile(hdr.fpath,[hdr.fname '_LFPSnapshot_' events{c} '-' num2str(c) '.fig']))
                            % perceive_print(fullfile(hdr.fpath,[hdr.fname '_LFPSnapshot_' events{c} '-' num2str(c)]))
                        else
                            % keyboard
                            warning('LFP Snapshot Event without LFP data present.')
                        end
                    end
                    % writetable(Tpow,fullfile(hdr.fpath,[hdr.fname '_LFPSnapshotEvents.csv']))
                
                %%
                % add to table
                jstable.modality(end+1) ='LfpFrequencySnapshotEvents';
                jstable.FirstPacketDateTime(end)= datestr(DTtable(1), 'yyyy-mm-ddTHH:MM:SS.FFFZ');
                jstable.Duration(end)= datestr(DTtable(end), 'yyyy-mm-ddTHH:MM:SS.FFFZ');
                %%
                end

        
            case 'BrainSenseSurveysTimeDomain'
                % Insert your code for handling 'BrainSenseSurveysTimeDomain' data here
                disp('Processing BrainSenseSurveysTimeDomain data...');
                jstable.modality(end+1) ='BrainSenseSurveysTimeDomain';
                for i=1:length(js.BrainSenseSurveysTimeDomain{2,1}.ElectrodeIdentifier)
                    fpdt=js.BrainSenseSurveysTimeDomain{2,1}.ElectrodeIdentifier(i).FirstPacketDateTime;
                    if ~isempty(fpdt)
                        jstable.FirstPacketDateTime(end+1)=fpdt;
                        [first_num, last_num] = extract_numbers(js.BrainSenseSurveysTimeDomain{2,1}.ElectrodeIdentifier(i).TicksInMses);
                        jstable.Duration(end)=ms_to_time(last_num-first_num);
                    end
                end


            case 'BrainSenseSurveys'
                % Insert your code for handling 'BrainSenseSurveys' data here
                disp('Processing BrainSenseSurveys data...');
                disp('Processing BrainSenseSurveysTimeDomain data...');
                jstable.modality(end+1) ='BrainSenseSurveysTimeDomain';
                for i=1:length(js.BrainSenseSurveysTimeDomain{2,1}.ElectrodeIdentifier)
                    fpdt=js.BrainSenseSurveysTimeDomain{2,1}.ElectrodeIdentifier(i).FirstPacketDateTime;
                    if ~isempty(fpdt)
                        jstable.FirstPacketDateTime(end+1)=fpdt;
                        [first_num, last_num] = extract_numbers(js.BrainSenseSurveysTimeDomain{2,1}.ElectrodeIdentifier(i).TicksInMses);
                        jstable.Duration(end)=ms_to_time(last_num-first_num);
                    end
                end
        end
    end
end

jstable.session(end+1) =js.SessionEndDate;
end

function time_str = ms_to_time(ms)
    % Convert milliseconds to total seconds
    total_seconds = ms / 1000;

    % Calculate hours, minutes, seconds, and milliseconds
    hours = floor(total_seconds / 3600);
    minutes = floor(mod(total_seconds, 3600) / 60);
    seconds = floor(mod(total_seconds, 60));
    milliseconds = round(mod(ms, 1000));

    % Format as hh:mm:ss.SSS
    time_str = sprintf('%02d:%02d:%02d.%03d', hours, minutes, seconds, milliseconds);
end

% Example usage
% ms = 1234567;
% time_str = ms_to_time(ms);
% disp(time_str);

function [first_num, last_num] = extract_numbers(str)
    % Split the string by commas
    num_strings = strsplit(str, ',');
    
    % Remove any empty cells
    num_strings = num_strings(~cellfun('isempty', num_strings));
    
    % Convert the first and last numbers to numeric values
    first_num = str2double(num_strings{1});
    last_num = str2double(num_strings{end});
end

% Example usage
% str = '718000,718250,718500,718750,719000,';
% [first_num, last_num] = extract_numbers(str);
% disp(['First number: ', num2str(first_num)]);
% disp(['Last number: ', num2str(last_num)]);
