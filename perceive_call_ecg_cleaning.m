function d=perceive_call_ecg_cleaning(d,hdr,raw)
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
end