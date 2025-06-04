function js = perceive_load_json(jsonfile)

% function to read in json, pseudonymize and save in js

    js = jsondecode(fileread(jsonfile));

    if isfield(js, 'PatientInformation')

        js = pseudonymize(js); % Optional

    end
end

%% HELPER pseudonymize: blanks out fields containing information on patient identity

function js=pseudonymize(js)
try
    js.PatientInformation.Initial.PatientFirstName ='';
    js.PatientInformation.Initial.PatientLastName ='';
    js.PatientInformation.Initial.PatientDateOfBirth ='';
    js.PatientInformation.Final.PatientFirstName ='';
    js.PatientInformation.Final.PatientLastName ='';
    js.PatientInformation.Final.PatientDateOfBirth ='';
catch
    js = rmfield(js,'PatientInformation');
    js.PatientInformation.Initial.PatientFirstName ='';
    js.PatientInformation.Initial.PatientLastName ='';
    js.PatientInformation.Initial.PatientDateOfBirth ='';
    js.PatientInformation.Initial.Diagnosis ='';
    js.PatientInformation.Final.PatientFirstName ='';
    js.PatientInformation.Final.PatientLastName ='';
    js.PatientInformation.Final.PatientDateOfBirth ='';
    js.PatientInformation.Final.Diagnosis = '';
end
end