function acq = perceive_check_stim(LAmp, RAmp, hdr)

% check stim whether the recording was stim OFF or stim ON based on the amplitude
% expand the acquisition to Burst

% check Burst settings
Cycling_mode = false;
if isfield(hdr.Groups, 'Initial')
    for i=1:length(hdr.Groups.Initial)
        if hdr.Groups.Initial(i).GroupSettings.Cycling.Enabled
            if Cycling_mode
                warning('Two different cycling modes: Settings Initial do not match Settings Final. Select no-cycling mode.')
                Cycling_mode = 'Contradiction';
            else
                Cycling_mode = true;
                Cycling_OnDuration = hdr.Groups.Initial(i).GroupSettings.Cycling.OnDurationInMilliSeconds;
                Cycling_OffDuration = hdr.Groups.Initial(i).GroupSettings.Cycling.OffDurationInMilliSeconds;
                Cycling_Rate = hdr.Groups.Initial(i).ProgramSettings.RateInHertz;
            end
        end
    end
end
if isfield(hdr.Groups, 'Final')
    for i=1:length(hdr.Groups.Final)
        if hdr.Groups.Final(i).GroupSettings.Cycling.Enabled
            if Cycling_mode
                warning('Two different cycling modes: Settings Initial do not match Settings Final. Select no-cycling mode.')
                Cycling_mode = 'Contradiction';
            else
                Cycling_mode = true;
                Cycling_OnDuration = hdr.Groups.Final(i).GroupSettings.Cycling.OnDurationInMilliSeconds;
                Cycling_OffDuration = hdr.Groups.Final(i).GroupSettings.Cycling.OffDurationInMilliSeconds;
                Cycling_Rate = hdr.Groups.Final(i).ProgramSettings.RateInHertz;
            end
        end
    end
end
if strcmp(Cycling_mode, 'Contradiction')
    Cycling_mode = false;
end

LAmp(isnan(LAmp))=0;
RAmp(isnan(RAmp))=0;
LAmp=abs(LAmp);
RAmp=abs(RAmp);
if Cycling_mode
    if (sum(LAmp>0.1)) > (0.1*sum(LAmp==0)) && (sum(RAmp>0.1)) > (0.5*sum(RAmp==0))
        acq=['BurstB' 'DurOn' num2str(Cycling_OnDuration) 'DurOff' num2str(Cycling_OffDuration) 'Freq' num2str(Cycling_Rate) ];
    elseif (sum(LAmp>0.1)) > (0.1*sum(LAmp==0))
        acq=['BurstL' 'DurOn' num2str(Cycling_OnDuration) 'DurOff' num2str(Cycling_OffDuration) 'Freq' num2str(Cycling_Rate) ];
    elseif (sum(RAmp>0.1)) > (0.1*sum(RAmp==0))
        acq=['BurstR' 'DurOn' num2str(Cycling_OnDuration) 'DurOff' num2str(Cycling_OffDuration) 'Freq' num2str(Cycling_Rate) ];
    end
end
if ~exist('acq','var')
    if (mean(LAmp) > 0.5) && (mean(RAmp) > 0.5)
        acq='StimOnB';
    elseif (mean(LAmp) > 1)
        acq='StimOnL';
    elseif (mean(RAmp) > 1)
        acq='StimOnR';
    else
        acq='StimOff';
    end
end
end