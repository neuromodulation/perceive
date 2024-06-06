function datanew=perceive_stitch_interruption_together(recording1, recording2)

% example
% load('sub-001_ses-Fu12mMedOff03_task-TASK4_acq-StimOff_mod-BrainSenseBip_run-1.mat')
% data4=data;
% load('sub-001_ses-Fu12mMedOff03_task-TASK4_acq-StimOff_mod-BSL_run-1.mat')
% dataBSL4=data;
% load('sub-001_ses-Fu12mMedOff03_task-TASK5_acq-StimOff_mod-BrainSenseBip_run-1.mat')
% data5=data;
% load('sub-001_ses-Fu12mMedOff03_task-TASK5_acq-StimOff_mod-BSL_run-1.mat')
% dataBSL5=data;

load(recording1,'data')
recording1=data;
load(recording2,'data')
recording2=data;
intermission=[recording1.sampleinfo(2)+1 recording2.sampleinfo(1)-1];
intermission_length = recording2.sampleinfo(1) - recording1.sampleinfo(2) + 1;
%sampleinfo = [recording1.sampleinfo intermission recording2.sampleinfo];

datanew=struct();
datanew.hdr(2)=recording1;
datanew.hdr(3)=recording2;

assert(strcmp(recording1.datatype,recording2.datatype))
datanew.datatype=recording1.datatype;

assert(isequal(recording1.label,recording2.label))
datanew.label=recording1.label;

datanew.trial(1)={[recording1.trial{1}, nan(size(recording1.trial{1},1),intermission_length), recording2.trial{1}]};
datanew.trial(2)=recording1.trial;
datanew.trial(3)=recording2.trial;

datanew.time(1)={recording1.time{1}(1):1/recording1.fsample:recording2.time{1}(end)};
datanew.time(2)=recording1.time;
datanew.time(3)=recording2.time;

assert(isequal(recording1.fsample,recording2.fsample))
datanew.fsample=recording1.fsample;

datanew.sampleinfo(1,:) = [recording1.sampleinfo(1) recording2.sampleinfo(2)];
datanew.sampleinfo(2,:) = recording1.sampleinfo;
datanew.sampleinfo(3,:) = recording2.sampleinfo;
datanew.sampleinfo_intermission = intermission;
datanew.sampleinfo_intermission_length = intermission_length;

if isfield(recording1,'BrainSenseDateTime')
    datanew.BrainSenseDateTime(1,:)=[recording1.BrainSenseDateTime(1) recording2.BrainSenseDateTime(2)];
    datanew.BrainSenseDateTime(2,:)=recording1.BrainSenseDateTime;
    datanew.BrainSenseDateTime(3,:)=recording2.BrainSenseDateTime;
    datanew.BrainSenseDateTime_intermission=[recording1.BrainSenseDateTime(end) recording2.BrainSenseDateTime(1)];
end

datanew.trialinfo = [recording1.trialinfo ; recording2.trialinfo];


assert(strcmp(strrep(recording1.fname,'_part-1',''),strrep(recording2.fname,'_part-2','')))
assert(strcmp(recording1.fname(end-7:end), '_part-1'), 'The file name of recording 1 does not end on _part-1 in data.fname and/or .mat file')
assert(strcmp(recording1.fname(end-7:end), '_part-2'), 'The file name of recording 2 does not end on _part-2 in data.fname and/or .mat file')
datanew.fname(1) = {strrep(recording1.fname,'_part-1','')};
datanew.fname(2) = {recording1.fname};
datanew.fname(3) = {recording2.fname};

assert(str2double(recording1.fnamedate) < str2double(recording2.fnamedate))
datanew.fnamedate(1) = {recording1.fnamedate};
datanew.fnamedate(2) = {recording1.fnamedate};
datanew.fnamedate(3) = {recording2.fnamedate};

if isfield(recording1,'ecg')
    datanew.ecg(2) = {recording1.ecg}; end
if isfield(recording2,'ecg')
    datanew.ecg(3) = {recording2.ecg}; end

if isfield(recording1,'ecg_cleaned') && isfield(recording2,'ecg_cleaned')
    datanew.ecg_cleaned(1)={[recording1.ecg_cleaned, nan(size(recording1.ecg_cleaned,1),intermission_length), recording2.ecg_cleaned]}; end
if isfield(recording1,'ecg_cleaned')
    datanew.ecg_cleaned(2)={recording1.ecg_cleaned}; end
if isfield(recording2,'ecg_cleaned')
    datanew.ecg_cleaned(3)={recording2.ecg_cleaned}; end
end






