function new_lfp_arr = perceive_check_and_correct_lfp_missingData_in_json(data,select, hdr)

    % from Jeroen Habets
    % https://github.com/jgvhabets/PyPerceive/blob/dev/code/PerceiveImport/methods/load_rawfile.py
    disp('check_and_correct_lfp_missingData by Jeroen Habets')
    % Function checks missing packets based on start and endtime
    % of first and last received packets, and the time-differences
    % between consecutive packets. In case of a missing packet,
    % the missing time window is filled with NaNs.
    % 
    % TODO: debug for BRAINSENSELFP OR SURVEY, STREAMING?
    % BRAINSENSETIMEDOMAIN DATA STRUCTURE works?
   
    try
   
    Fs= data(select).SampleRateInHz; %Fs = data.hdr.Fs;
    GlobalPacketSizes=str2num(hdr.js.BrainSenseTimeDomain(select).GlobalPacketSizes);
    ticksMsec=str2num(hdr.js.BrainSenseTimeDomain(select).TicksInMses);
    TicksInS = (ticksMsec - ticksMsec(1))/1000;
    ticksDiffs = -(ticksMsec(1:end-1)-ticksMsec(2:end));
    data_is_missing = logical(1);
    packetSizes = GlobalPacketSizes;
    lfp_data = data(select).TimeDomainData; %data.trial{:,:}(1,:);

    if data_is_missing
        disp('LFP Data is missing!! perform function to fill NaNs in')
    else
        disp('No LFP data missing based on timestamp differences between data-packets')
    end

    data_length_ms = ticksMsec(end) + 250 - ticksMsec(1);  % length of a pakcet in milliseconds is always 250
    data_length_samples = round(data_length_ms / 1000 * Fs) + 1 ; % add one to calculate for 63 packet at end
    new_lfp_arr = nan(data_length_samples,1);

    % fill nan array with real LFP values, use tickDiffs to decide start-points (and where to leave NaN)

    % Add first packet (data always starts with present packet)
    current_packetSize = round(packetSizes(1));
    if current_packetSize > 63
        disp('UNKNOWN TOO LARGE DATAPACKET IS CUTDOWN BY {current_packetSize - 63} samples')
        current_packetSize = 63 ; % if there is UNKNOWN TOO MANY DATA, only the first 63 samples of the too large packets are included
    end
    new_lfp_arr(1:current_packetSize) = lfp_data(1:current_packetSize);
    % loop over every distance (index for packetsize is + 1 because first difference corresponds to seconds packet)
    i_lfp = current_packetSize;  % index to track which lfp values are already used
    i_arr = current_packetSize;  % index to track of new array index
    
    i_packet = 1;

    for diff = ticksDiffs
        if diff == 250
            % only lfp values, no nans if distance was 250 ms
            current_packetSize = round(packetSizes(i_packet));

            % in case of very rare TOO LARGE packetsize (there is MORE DATA than expected based on the first and last timestamps)
            if current_packetSize > 63
                disp('UNKNOWN TOO LARGE DATAPACKET IS CUTDOWN BY {current_packetSize - 63} samples')
                current_packetSize = 63;
            end
            new_lfp_arr(i_arr:round(i_arr + current_packetSize)) = lfp_data(i_lfp:round(i_lfp + current_packetSize));
            i_lfp = i_lfp + current_packetSize;
            i_arr = i_arr + current_packetSize;
            i_packet = i_packet + 1;
        else
            disp('add NaNs by skipping')
            msecs_missing = (diff - 250);  % difference if one packet is missing is 500 ms

            secs_missing = msecs_missing / 1000;
            samples_missing = round(secs_missing * Fs);
            % no filling with NaNs, bcs array is created full with NaNs
            i_arr = i_arr + samples_missing;  % shift array index up by number of NaNs left in the array
        end
    end
    
    % correct in case one sample too many was in array shape
    if isnan(new_lfp_arr(end))
        new_lfp_arr = new_lfp_arr(1:end);
    end
    % plot the correction
    % plot(1:length(new_lfp_arr),new_lfp_arr)
    % na=double(isnan(new_lfp_arr));
    % na(na==0)=NaN;
    % hold on
    % plot(1:length(na),na,"r*")
    % title(data.fname, "Interpreter","none")
    hold off
    catch
        new_lfp_arr=size((i_lfp + current_packetSize),1);
    end
    new_lfp_arr=new_lfp_arr';
end