function data=perceive_stitch_interruption_together(recording_basename, optional_time_addition_ms, save_file)
% For questions contact Jojo Vanhoecke
% 
% This is a function to concatenate percept recordings by filling the gaps with NaN's, meant for
% a technical interruption. It reads in the matlab structures, and will create fieldnames.
% 
% %% Example:
% % name of the series of recordings recording
% recording1 = 'sub-001_ses-Fu12mMedOff03_task-TASK4_acq-StimOff_mod-BrainSenseBip_run-1_part-';
% % Make sure the recording filename ends on "part-". Apart from the "part-" it must have the same
% % naming as following recordings. It needs to be in your path.
% data=perceive_stitch_interruption_together('sub-001_ses-Fu12mMedOff03_task-TASK4_acq-StimOff_mod-BrainSenseBip_run-1_part-')

% %% Example to increase the NaN between recordings with 280 ms (rounded by the sample frequency)
% data=perceive_stitch_interruption_together('sub-001_ses-Fu12mMedOff03_task-TASK4_acq-StimOff_mod-BrainSenseBip_run-1_part-', 280)
% %% Example to decrease the NaN between recordings with 100 ms (rounded by the sample frequency)
% data=perceive_stitch_interruption_together('sub-001_ses-Fu12mMedOff03_task-TASK4_acq-StimOff_mod-BrainSenseBip_run-1_part-', -100)

arguments
    recording_basename (1, :) char % Must be a char vector
    optional_time_addition_ms (1, 1) {mustBeInteger} = 0 % Optional, default is 0
    save_file (1, 1) logical = false % Optional, default is false
end

recording_part = struct();
i=0;
while i<10
    i=i+1;
    recording_name = [recording_basename num2str(i) '.mat'];
    if exist(recording_name,"file")
        load(recording_name, 'data')
        recording_part(i).data=data;
    else
        if i<3
            error('Not suffient file parts found. _part-1.mat and/or _part-2.mat are missing')
        end
        i=11;
    end
end

%assert the sample frequency is 250Hz
assert(data.fsample==250)

%compute sampleinfotime based on the time
for i = 1:length(recording_part)
    recording_part(i).data.sampleinfotime = [round(recording_part(i).data.time{1}(1)*recording_part(i).data.fsample) , round(recording_part(i).data.time{1}(end)*recording_part(i).data.fsample)];
end


last_part = length(recording_part);
for i = 1:last_part-1
    intermission(i).part=[recording_part(i).data.sampleinfotime(2)+1 recording_part(i+1).data.sampleinfotime(1)-1];
    intermission_length(i).part = recording_part(i+1).data.sampleinfotime(1) - recording_part(i).data.sampleinfotime(2) + 1 + round(optional_time_addition_ms/1000*recording_part(i).data.fsample);
    assert(intermission_length(i).part>=0, 'Added NaNs in intermission length between recordings cannot be negative')
end

    data=struct();
    
    assert(strcmp(recording_part(1).data.datatype,recording_part(2).data.datatype))
    data.datatype=recording_part(1).data.datatype;
    
    assert(isequal(recording_part(1).data.label,recording_part(2).data.label))
    data.label=recording_part(1).data.label;
    
    data.trial=[recording_part(1).data.trial{1}];
    for i = 1:last_part-1
        data.trial=[data.trial  nan(size(recording_part(i).data.trial{1},1),intermission_length(i).part), recording_part(i+1).data.trial{1}];
    end
    data.trial={data.trial};
    data.time={recording_part(1).data.time{1}(1):1/recording_part(1).data.fsample:recording_part(last_part).data.time{1}(end)};
        
    assert(isequal(recording_part(1).data.fsample,recording_part(2).data.fsample))
    data.fsample=recording_part(1).data.fsample;
    
    data.sampleinfotime = [recording_part(1).data.sampleinfotime(1) recording_part(last_part).data.sampleinfotime(2)];
    
    data.sampleinfotime_intermission = intermission;
    data.sampleinfotime_intermission_length = intermission_length;
    
    if isfield(recording_part(1).data,'BrainSenseDateTime')
        data.BrainSenseDateTime=[recording_part(1).data.BrainSenseDateTime(1) recording_part(last_part).data.BrainSenseDateTime(2)];
        for i=1:last_part-1
            data.BrainSenseDateTime_intermission(i).parts=[recording_part(i).data.BrainSenseDateTime(end) recording_part(i+1).data.BrainSenseDateTime(1)];
        end
    end
        
    data.trialinfo = [recording_part(1).data.trialinfo];
    for i=2:last_part
        data.trialinfo = [data.trialinfo; recording_part(i).data.trialinfo];
    end
    
    for i = 1:last_part
        a=num2str(i);
        assert(strcmp(strrep(recording_part(1).data.fname,'_part-1',''),strrep(recording_part(i).data.fname,['_part-' a],'')))
        assert(strcmp(recording_part(i).data.fname(end-10:end), ['_part-' a '.mat']), ['The file name of recording ' a ' does not end on _part-' a ' in data.fname and/or .mat file'])
        assert(str2double(recording_part(1).data.fnamedate) <= str2double(recording_part(i).data.fnamedate)) %check for time line anachrony
    end
    data.fname = {strrep(recording_part(1).data.fname,'_part-1','')};
        
    data.fnamedate = {recording_part(1).data.fnamedate};
    data.ecg_cleaned={[]};
    % if isfield(recording1,'ecg_cleaned') && isfield(recording2,'ecg_cleaned')
    %     try
    %         data.ecg_cleaned={[recording1.ecg_cleaned, nan(size(recording1.ecg_cleaned,1),intermission_length), recording2.ecg_cleaned]};
    %     catch
    %         data.ecg_cleaned={[]};
    %     end
    % end

    if save_file
        recording_basename = strrep(recording_basename, '_part-', '');
        save(recording_basename,'data')
    end
end






