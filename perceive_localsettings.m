function localsettings=perceive_localsettings(localsettings)

%% load local settings
if isfield(localsettings,'name')
    if strcmp(localsettings.name, 'Charite')
        localsettings.check_followup_time=true;
        localsettings.check_gui_tasks=true;
        localsettings.check_gui_med=true;
        localsettings.datafields = {"IndefiniteStreaming","LfpMontageTimeDomain"}; %adapt where needed
        %if you want only DataVersion 1.2 specific fields:
        % localsettings.datafields = sort({'BrainSenseSurveysTimeDomain','BrainSenseSurveys'});
        localsettings.convert2bids = true;

    else
        assert(islogical(localsettings.check_followup_time))
        assert(islogical(localsettings.check_gui_tasks))
        assert(islogical(localsettings.check_gui_med))
    end
else
    localsettings.name='default';
    localsettings.check_followup_time=false;
    localsettings.check_gui_tasks=false;
    localsettings.check_gui_med=false;
    localsettings.convert2bids = false;
    localsettings.datafields = sort({'EventSummary','Impedance','MostRecentInSessionSignalCheck','BrainSenseLfp','BrainSenseTimeDomain','LfpMontageTimeDomain','IndefiniteStreaming','BrainSenseSurvey','CalibrationTests','PatientEvents','DiagnosticData','BrainSenseSurveysTimeDomain','BrainSenseSurveys'});
end

end