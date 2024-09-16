function data=perceive_stitch_interruption_together(recording_basename)

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

last_part = length(recording_part);
for i = 1:last_part-1
    intermission(i).part=[recording_part(i).data.sampleinfo(2)+1 recording_part(i+1).data.sampleinfo(1)-1];
    intermission_length(i).part = recording_part(i+1).data.sampleinfo(1) - recording_part(i).data.sampleinfo(2) + 1;
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
    
    data.sampleinfo = [recording_part(1).data.sampleinfo(1) recording_part(last_part).data.sampleinfo(2)];
    
    data.sampleinfo_intermission = intermission;
    data.sampleinfo_intermission_length = intermission_length;
    
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
end






