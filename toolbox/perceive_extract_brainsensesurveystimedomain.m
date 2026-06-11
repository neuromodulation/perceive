function alldata_brainsensesurveystimedomain = perceive_extract_brainsensesurveystimedomain(data, hdr)

% extraction of BrainSenseSurveysTimeDomain data (BSTD) into FieldTrip-like format
%
% inputs:
%   data - input data struct from Percept JSON
%   hdr - header struct with fields like hdr.d0, hdr.chan, hdr.fpath, etc.
%
% output:
%   alldata

alldata_brainsensesurveystimedomain={};
%%%%%%%%%%%%%%%%%%%% IMPROVE WITH AI snippet %%%%%%%%%%%%%%%%%%%%%%%
if length(data)==2
ElectrodeSurvey=data{1};
ElectrodeIdentifier=data{2};
assert(strcmp(ElectrodeSurvey.SurveyMode,'ElectrodeSurvey'))
assert(strcmp(ElectrodeIdentifier.SurveyMode,'ElectrodeIdentifier'))
dataiteration={'ElectrodeSurvey','ElectrodeIdentifier'};
elseif strcmp(data.SurveyMode,'ElectrodeSurvey')
ElectrodeSurvey=data;
dataiteration={'ElectrodeSurvey'};
elseif strcmp(data.SurveyMode,'ElectrodeIdentifier')
ElectrodeIdentifier=data;
dataiteration={'ElectrodeIdentifier'};
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for k = 1:numel(dataiteration)
    currentItem = dataiteration{k};
    switch currentItem

        case 'ElectrodeSurvey'
        data=ElectrodeSurvey.ElectrodeSurvey;
        mod_prefix = 'mod-ES';
        if isfield(hdr.js, 'LfpMontageTimeDomain') %ElectrodeSurvey is the same as LMTD
            continue
        end
        %%%%%%%%%%%% improve with AI %%%%%%%%%%%%%%%%%%%%
         remove = [];
         for n=1:numel(data)
             if ~(data(n).SampleRateInHz)
                 remove=[remove, n]
             end
         end
         if ~isempty(remove)
             data(remove)=[];
         end
        %Data is empty
        if isempty(data)
            continue
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        case 'ElectrodeIdentifier'
        
        data=ElectrodeIdentifier.ElectrodeIdentifier;
        
        mod_prefix = 'mod-EI';
        

        %%%%%%%%%%%% improve with AI %%%%%%%%%%%%%%%%%%%%
         remove = [];
         for n=1:numel(data)
             if ~(data(n).SampleRateInHz)
                 remove=[remove, n]
             end
         end
         if ~isempty(remove)
             data(remove)=[];
         end
        %Data is empty
        if isempty(data)
            continue
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        for c = 1:length(data)
            str=data(c).Channel;
            str=strrep(str, 'ELECTRODE_', '');
            data(c).Channel = [str '_' upper(data(c).Hemisphere) ];
        end
    end


    fsample = data.SampleRateInHz;
    runs_FirstPacketDateTime = strrep(strrep({data(:).FirstPacketDateTime}, 'T', ' '), 'Z', '');

    %%% adapt with AI %%%%%%%%%%%%%%%%%%%%%%%%%
    remove = [];
    for n=1:numel(runs_FirstPacketDateTime)
        if isempty(runs_FirstPacketDateTime{n})
            remove=[remove, n]
        end
    end
    if ~isempty(remove)
        runs_FirstPacketDateTime(remove)=[];
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    runs = unique(runs_FirstPacketDateTime);
    

    %% Do the time thing if TicksInMS is present
    % 
    % try
    % Pass = {data(:).Pass};
    % GlobalSequences = cell(size(data));
    % GlobalPacketSizes = cell(size(data));
    % TicksInS = cell(size(data));
    % time_real = cell(size(data));
    % 
    % % parse meta fields
    % for idxData = 1:length(data)
    %     GlobalSequences{idxData} = str2num(data(idxData).GlobalSequences); %#ok<ST2NM>
    %     try
    %         TicksInMs = str2num(data(idxData).TicksInMses); %#ok<ST2NM>
    %     catch %for ElectrodeSurvey there is only TicksInMs not in TicksInMSes
    %         TicksInMs = str2num(data(idxData).TicksInMs); %#ok<ST2NM>
    %     end
    %     TicksInS{idxData} = (TicksInMs - TicksInMs(1)) / 1000;
    %     GlobalPacketSizes{idxData} = str2num(data(idxData).GlobalPacketSizes); %#ok<ST2NM>
    %     time_real{idxData} = TicksInS{idxData}(1):1/fsample:TicksInS{idxData}(end) + (GlobalPacketSizes{idxData}(end) - 1)/fsample; %time real needs to be updated
    %     time_real{idxData} = round(time_real{idxData}, 3);
    % end
    % 
    % %[tmp1]=split({data(:).Channel}', regexpPattern("(_AND_)|((?<!.*_.*)_(?!.*_AND_.*))"));
    % %ch1 = strrep(strrep(strrep(strrep(strrep(strrep(strrep(tmp1(:,1),'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3'),'_A','A'),'_B','B'),'_C','C'); % ch1 replaces ZERO to int 0 etc of first part before AND (tmp1(:,1))
    % %ch2 = strrep(strrep(strrep(strrep(strrep(strrep(strrep(strrep(strrep(tmp1(:,2),'ZERO','0'),'ONE','1'),'TWO','2'),'THREE','3'),'LEFTS','L'),'RIGHTS','R'),'_A','A'),'_B','B'),'_C','C'); % ch2 replaces ZERO to int 0 etc of second part after AND (tmp1(:,1))
    % 
    % %Channel = strcat(hdr.chan,'_', ch1,'_', ch2); % taken out "side" so RIGHT and LEFT will stay the same, no transformation to R and L
    % catch
    %     warning('No TicksInMs present in BrainSenseSurveysTimeDomain')
    % end
    %% handle the channel naming
    % Split channels on '_AND_' or the single underscore (not part of '_AND_')
    tmp1 = split({data(:).Channel}', regexpPattern("(_AND_)|((?<!.*_.*)_(?!.*_AND_.*))"));

    numReplace = {'ZERO','ONE','TWO','THREE'};
    numReplaceWith = {'0','1','2','3'};

    % ch1 replacements
    ch1 = regexprep(tmp1(:,1), numReplace, numReplaceWith);
    ch1 = strrep(ch1, '_A', 'A');
    ch1 = strrep(ch1, '_B', 'B');
    ch1 = strrep(ch1, '_C', 'C');

    % ch2 replacements
    ch2 = regexprep(tmp1(:,2), numReplace, numReplaceWith);
    ch2 = strrep(ch2, 'LEFTS', 'L');
    ch2 = strrep(ch2, 'RIGHTS', 'R');
    ch2 = strrep(ch2, '_A', 'A');
    ch2 = strrep(ch2, '_B', 'B');
    ch2 = strrep(ch2, '_C', 'C');

    Channel = strcat(hdr.chan, '_', ch1, '_', ch2);



    %% start iterating over the stream elements in js here
    already_processed = datetime.empty;   % store timestamps we've already processed

    for js_element = 1:numel(runs_FirstPacketDateTime)

        % % Convert cell string → datetime
        % t = datetime(runs_FirstPacketDateTime{js_element}, 'InputFormat','yyyy-MM-dd HH:mm:ss.SSS');
        % 
        % % Check if we already processed this timestamp
        % if any(t == already_processed)
        %     continue   % skip duplicates
        % end
        % 
        % % Mark this timestamp as processed
        % already_processed(end+1) = t;
        % 
        % if i > 1
        %     % Collect TimeDomainData for all indices in i into a cell array
        %     tdCells = {data(i).TimeDomainData};   % 1 x n cell
        % 
        %     % Compute lengths of each TimeDomainData entry
        %     tdLengths = cellfun(@numel, tdCells);
        % 
        %     % Check if all lengths are equal
        %     if numel(unique(tdLengths)) == 1
        %         % All equal -> proceed normally
        %         raw1 = [tdCells{:}]';   % concatenate and transpose
        %     else
        %         % Lengths differ -> use fallback
        %         raw1 = NaNfallback(data, i);
        %     end
        % else
        %     %i is 1 or less
        %     raw1 = [data(i).TimeDomainData]';
        % end
        i = perceive_ci(runs_FirstPacketDateTime{js_element}, runs_FirstPacketDateTime); %what does this function do?
        d=struct();
        d.hdr = hdr;
        d.datatype = 'BrainSenseSurveysTimeDomain';
        d.fsample = fsample;
        %%%%%%%%%%%%%%% if TimeDomainDatainMicroVolts have different
        %%%%%%%%%%%%%%% length, allow for  65 empty bits
        longest_TimeDomainDatainMicroVolts=0;
        for ii=i
            current_length=length(data(ii).TimeDomainDatainMicroVolts);
            if current_length>longest_TimeDomainDatainMicroVolts
                longest_TimeDomainDatainMicroVolts=current_length;
            end
        end
        for ii=i
            current_length=length(data(ii).TimeDomainDatainMicroVolts);
            
            if  (current_length+65)<longest_TimeDomainDatainMicroVolts
                error('length of TimeDomaininMicroVolts across different channels differs with more than 65 samples among each other. This needs manual attention.')
            elseif current_length<longest_TimeDomainDatainMicroVolts
                data(ii).TimeDomainDatainMicroVolts=[data(ii).TimeDomainDatainMicroVolts; zeros(longest_TimeDomainDatainMicroVolts-current_length,1)]
            end
        end
        %%%%
        tmp = [data(i).TimeDomainDatainMicroVolts]';
        d.trial{1} = [tmp];
        d.label=Channel(i);
        d.hdr.label = d.label;
        d.hdr.Fs = d.fsample;
        %% this is no longer correct, because we do not have hdrd0
        %d.time=linspace(seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')-hdr.d0),seconds(datetime(runs{c},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS')-hdr.d0)+size(d.trial{1},2)/fsample,size(d.trial{1},2));
        %d.time={d.time};
        %% crucial part here, replace the time
        t0 = datetime(runs_FirstPacketDateTime{js_element}, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
        rel_start = seconds(timeofday(t0));
        d.time{1} = linspace(rel_start, rel_start + size(d.trial{1}, 2)/fsample, size(d.trial{1}, 2)); %update the time! This cannot be correct

        % %% insert time check here, see code in perceive_extract_bstd.m
        % 
        % t0 = datetime(runs_FirstPacketDateTime{js_element}, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
        % 
        % % OLD
        % %rel_start = seconds(t0 - hdr.d0);
        % %d.timeInSecDerivedFromIdealSampleRate{1} = linspace(rel_start, rel_start + size(d.trial{1}, 2)/fsample, size(d.trial{1}, 2));
        % 
        % % NEW 1 (drop the d0 time, and replace it with the timeofday of the current run)
        % rel_start = seconds(timeofday(t0));
        % d.time{1} = linspace(rel_start, rel_start + size(d.trial{1}, 2)/fsample, size(d.trial{1}, 2)); %update the time! This cannot be correct
        % d.time_real = time_real{i(1)};
        % 
        % % NEW 2 (replace the linspace time with the times in milliseconds
        % % derived from Ticks
        % 
        % % Compute timestamps
        % [d.timeInSecDerivedFromTicks, d.timerealDerivedFromTicks] = computePerceptTimestamps(TicksInS{i(1)}, GlobalPacketSizes{i(1)}, fsample, runs_FirstPacketDateTime{i(1)});
        % 
        % % NEW 3: keep a linear time, starting at t0 = 0;
        % d.timeInSecDerivedFromIdealSampleRate{1} = linspace(0, size(d.trial{1}, 2)/fsample, size(d.trial{1}, 2));
        % 
        % %% now do assertions:
        % %% 1. Basic length checks
        % assert(length(d.trial{1}) == length(d.timeInSecDerivedFromTicks), ...
        %     'Tick-derived timeline length does not match number of samples')
        % 
        % assert(length(d.trial{1}) == length(d.timeInSecDerivedFromIdealSampleRate{1}), ...
        %     'Old synthetic timeline length does not match number of samples')
        % 
        % %% 2. Packet size consistency
        % assert(sum(GlobalPacketSizes{i(1)}) == length(d.trial{1}), ...
        %     'Sum of packet sizes does not match number of samples')
        % 
        % %% 3. Monotonicity of tick timestamps
        % assert(all(diff(TicksInS{i(1)}) >= 0), ...
        %     'TicksInS is not monotonic — packet timestamp disorder detected')
        % 
        % %% 4. Check sampling rate from tick-derived timeline
        % dt_tick = diff(d.timeInSecDerivedFromTicks);
        % fs_tick = 1/median(dt_tick);
        % 
        % assert(abs(fs_tick - fsample) < 0.5, ...
        %     sprintf('Tick-derived sampling rate deviates from expected: %.3f Hz', fs_tick))
        % 
        % %% 5. Check sampling rate from old timeline
        % dt_old = diff(d.timeInSecDerivedFromIdealSampleRate{1});
        % fs_old = 1/median(dt_old);
        % 
        % if abs(fs_old - fsample) < 1, ...
        %         warning('Old synthetic sampling rate deviates from expected: %.3f Hz', fs_old)
        % end
        % 
        % %% 6. Packet gap detection (corrected to use TicksInS{i(1)})
        % packetStartSec = TicksInS{i(1)};
        % expectedPacketEnd = packetStartSec + (GlobalPacketSizes{i(1)} - 1)/fsample;
        % 
        % gaps = packetStartSec(2:end) - expectedPacketEnd(1:end-1);
        % 
        % if any(gaps > 1/fsample)
        %     warning('Detected gaps between packets — tick-derived timeline is more accurate')
        % end
        % 
        % %% 7. Jitter detection
        % jitter = std(dt_tick);
        % if jitter > 0.0005
        %     warning('High jitter detected in tick-derived timestamps')
        % end
        % 
        % %% 8. Drift between old and new timelines
        % drift = d.timeInSecDerivedFromIdealSampleRate{1} - d.timeInSecDerivedFromTicks;
        % maxDrift = max(abs(drift));
        % 
        % if maxDrift > 0.002
        %     warning('Old timeline drifts from tick-derived timeline by %.4f seconds', maxDrift)
        % end
        % 
        % 
        % assert(length(d.trial{1}) == length(d.timeInSecDerivedFromTicks))
        % assert(length(d.trial{1}) == length(d.timerealDerivedFromTicks))
        % 
        % %%% fix the position of the time
        % timeInSecDerivedFromTicks=d.timeInSecDerivedFromTicks;
        % d.timeInSecDerivedFromTicks={};
        % d.timeInSecDerivedFromTicks{1}=timeInSecDerivedFromTicks; % just like d.timeInSecDerivedFromIdealSampleRate{1} = linspace(rel_start, rel_start + size(d.trial{1}, 2)/fsample, size(d.trial{1}, 2)); %update the time!
        % 
        % %%%%%%%%%%%%%%%%%%%%%%% Either way, remove time_real
        % 
        % d.time_real_old  = d.time_real;
        % d.time_real = [];
        % d.time = [];
        % d.time_fsample = fsample;
        % 
        % d.timeInSecDerivedFromIdealSampleRate;
        % d.timeInSecDerivedFromTicks;
        % d.timerealDerivedFromTicks;
        % d.timeInfo = "There are time differences between timeInSecDerivedFromIdealSampleRate and timeInSecDerivedFromTicks, as documented in timeEvents. The ideal sample rate is through package lost usually lower. In timeEvents is the cumulative time difference in seconds of timeInSecDerivedFromIdealSampleRate minus timeInSecDerivedFromTicks documented for each sample that a difference is change as in Samplenumber:timeInSec E.g. 1000:-0.25 3050: -1.75 i.e. There is no time difference, then the timeInSecDerivedFromTicks lags 0.25 seconds behind timeInSecDerivedFromIdealSampleRate from sample 1000 onward, and jumps to 1.75 delay from sample 3050 onward";
        % d.timeEvents = {};
        % 
        % 
        % %% Add explanation text
        % d.timeInfo = [
        %     "There are time differences between timeInSecDerivedFromIdealSampleRate and timeInSecDerivedFromTicks, as documented in timeEvents. " + ...
        %     "The ideal sample rate is usually lower due to packet loss. " + ...
        %     "In timeEvents, the cumulative time difference in seconds of ideal minus ticks is listed at each sample where the difference changes. " + ...
        %     "Example: 1000:-0.25  3050:-1.75 means: no difference initially, then from sample 1000 onward the tick-derived time lags by 0.25 seconds, " + ...
        %     "and from sample 3050 onward it lags by 1.75 seconds."
        %     ];
        % 
        % % compute Time Events
        % ideal = d.timeInSecDerivedFromIdealSampleRate{1};
        % ticks = d.timeInSecDerivedFromTicks{1};
        % 
        % % Ensure equal length
        % N = length(ideal);
        % assert(isequal(length(ticks), N), 'Ideal and tick vectors must match in length');
        % 
        % threshold = 0.01;   % ±10 ms
        % 
        % eventIdx    = 1;
        % eventValues = ideal(1) - ticks(1);
        % lastLag     = eventValues;
        % 
        % for n = 2:N
        %     lag = ideal(n) - ticks(n);
        % 
        %     % Register event if lag changes by more than ±10 ms
        %     if abs(lag - lastLag) > threshold
        %         eventIdx(end+1,1)    = n;      %#ok<AGROW>
        %         eventValues(end+1,1) = lag;    %#ok<AGROW>
        %         lastLag              = lag;
        %         warning('Time lag change, event created at sample %d (%.3f -> %.3f).', n, lastLag, lag);
        % 
        %     end
        % end
        % % Now finalize: Build d.timeEvents with 3 decimals from eventValues
        % d.timeEvents = cell(length(eventIdx), 1);
        % for k = 1:length(eventIdx)
        %     d.timeEvents{k} = sprintf('%d:%.3f', eventIdx(k), eventValues(k));
        % end


        %% continue after time check with original code

        mod_ext=perceive_check_mod_ext(d.label);
        mod = [mod_prefix mod_ext];
        d.fname = [hdr.fname '_' mod];
        d.fnamedate = [char(datetime(runs_FirstPacketDateTime{js_element},'Inputformat','yyyy-MM-dd HH:mm:ss.SSS','format','yyyyMMddhhmmss')), '_',num2str(js_element)];
        % TODO: set if needed:
        %d.keepfig = false; % do not keep figure with this signal open
        %d=call_ecg_cleaning(d,hdr,d.trial{1});
        perceive_plot_raw_signals(d);
        perceive_print(fullfile(hdr.fpath,d.fname));
        alldata_brainsensesurveystimedomain{length(alldata_brainsensesurveystimedomain)+1} = d;
    end
    %% end of the iteration over the js streams
end
end