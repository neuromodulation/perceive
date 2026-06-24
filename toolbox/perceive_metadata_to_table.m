function MetaT = perceive_metadata_to_table(MetaT, data)
fname=data.fname;
if contains(fname, ["LMTD","BrainSense","ISRing","EI","ES"])
    splitted_fname = regexp(fname, '[_.]', 'split');
    % --- Assertions for required prefixes ---
    assert(startsWith(splitted_fname{2}, "ses-"),  ...
        'Invalid session format in "%s": must start with "ses-"', fname);
    assert(startsWith(splitted_fname{3}, "task-"), ...
        'Invalid task format in "%s": must start with "task-"', fname);
    assert(startsWith(splitted_fname{4}, "acq-"),  ...
        'Invalid acquisition format in "%s": must start with "acq-"', fname);
    assert(startsWith(splitted_fname{6}, "run-"),  ...
        'Invalid run format in "%s": must start with "run-"', fname);

    ses = lower(splitted_fname{2}(5:9));
    if contains(splitted_fname{2}, 'MedOnOff')
        med = 'm9';
    elseif contains(splitted_fname{2}, 'MedOn')
        med = 'm1';
    elseif contains(splitted_fname{2}, 'MedDaily')
        med = 'm3';
    elseif contains(splitted_fname{2}, 'Unknown')
        med = 'm5';
    elseif contains(splitted_fname{2}, 'MedOff')
        med = 'm0';
    else
        med = '';
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
    run = splitted_fname{6}(5:end);
    nomatch = true;
    i=0;
    tobefound = ["Bip","RingL","RingR","SegmInterL","SegmInterR","SegmIntraL","SegmIntraR", "Ring", "SegmR", "SegmL", "notspec"];
    while nomatch
        i=i+1;
        if contains(fname, tobefound(i))
            contacts = tobefound(i);
            nomatch = false;
        end
    end
    [~, ori, ~] = fileparts(data.hdr.OriginalFile);
    cellarr = {[ori '.json'], fname,  ses, cond, task, contacts, run, '', acq, 'keep'}; %add parts and stim settings
    MetaT = [MetaT; cellarr];
end
end