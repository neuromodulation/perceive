function mod_ext=perceive_check_mod_ext(labels)
%03, 13, 02, 12 are Ring contacts
%1A_2A, 1B_2B, 1C_2C LEFT are SegmInter
%1A_1B, 1A_1C, 1B_1C, 2A_2B, 2B_2C are SegmIntraL
if sum(contains(labels,'LEFT_RING'))>3 %usually 6 or 4
    mod_ext = 'RingL';
elseif sum(contains(labels,'LEFT_SEGMENT'))==6
    mod_ext = 'SegmIntraL';
elseif sum(contains(labels,'LEFT_SEGMENT'))==3
    mod_ext = 'SegmInterL';
elseif sum(contains(labels,'RIGHT_RING'))>3 %usually 6 or 4
    mod_ext = 'RingR';
elseif sum(contains(labels,'RIGHT_SEGMENT'))==6
    mod_ext = 'SegmIntraR';
elseif sum(contains(labels,'RIGHT_SEGMENT'))==3
    mod_ext = 'SegmInterR';
else
    if any(contains(labels,'0'))
        mod_ext = 'Ring';
    elseif sum(contains(labels,'A'))==3
        mod_ext = 'SegmIntra';
    elseif sum(contains(labels,'A'))==1
        mod_ext = 'SegmInter';
    elseif sum(contains(labels,'1'))==3 && sum(contains(labels,'2'))==3
        mod_ext = 'Segm';
    else
        mod_ext = 'notspec';
        warning('the LMTD/ES has no known modus, it needs to be: Bip,RingL,RingR,SegmInterL,SegmInterR,SegmIntraL,SegmIntraR,Ring\n the EI needs to be Segm or Ring.')
    end
    if any(contains(labels,'LEFT')) && ~contains(mod_ext,'notspec')
        mod_ext = [mod_ext , 'L'];
    else
        mod_ext = [mod_ext , 'R'];
    end
end
end