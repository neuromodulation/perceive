function my_settings=perceive_GroupHistory(files)
% https://github.com/neuromodulation/perceive
% Toolbox by Wolf-Julian Neumann
% v1.0 update by J Vanhoecke
% Merge requests from Jennifer Behnke and Mansoureh Fahimi
% Contributors Wolf-Julian Neumann, Tomas Sieger, Gerd Tinkhauser
% This is an open research tool that is not intended for clinical purposes.
%F
% INPUT:
% file          ["", 'Report_Json_Session_Report_20200115T123657.json', {'Report_Json_Session_Report_20200115T123657.json','Report_Json_Session_Report_20200115T123658.json'}, ...]
% sub           ["", 7, 21 , "021", ... ]
% sesMedOffOn01 ["","MedOff01","MedOn01","MedOff02","MedOn02","MedOff03","MedOn03","MedOffOn01"]
% extended      ["","yes"] %% gives an extensive output of chronic, calibration, lastsignalcheck, diagnostic, impedance and snapshot data
% gui           ["","yes"] %% gives option to skip gui by default settings
%% INPUT
arguments
    files {mustBeA(files,["char","cell"])} = '';
    % files:
    % All input is optional, you can specify files as cell or character array
    % (e.g. files = 'Report_Json_Session_Report_20200115T123657.json')
    % if files isn't specified or remains empty, it will automatically include
    % all files in the current working directory
    % if no files in the current working directory are found, a you can choose
    % files via the MATLAB uigetdir window.
end

%% OUTPUT

%% Recording type output naming

%% TODO:

if ~exist('files','var') || isempty(files)
    try
        files=perceive_ffind('*.json');
    catch
        files = [];
    end
    if isempty(files)
        [files,path] = uigetfile('*.json','Select .json file','MultiSelect','on');
        if isempty(files)
            return
        end
        files = strcat(path,files);

    end
end

if ischar(files)
    files = {files};
end

%% iterate over files
for a = 1:length(files)
    filename = files{a};
    disp(['RUNNING ' filename])

    js = jsondecode(fileread(filename));
  
    my_settings=struct();
    my_settings.GroupHistory = struct();
    if isfield(js,'GroupHistory')
        for i=1:size(js.GroupHistory,1)
            sessiondate=js.GroupHistory(i).SessionDate;
            if any([js.GroupHistory(i).Groups(:).ActiveGroup])
                gr=find([js.GroupHistory(i).Groups(:).ActiveGroup]);
                settings=js.GroupHistory(i).Groups(gr);                
            else
                settings='None active';
            end
            
            my_settings.GroupHistory(i).Sessiondate=sessiondate;
            my_settings.GroupHistory(i).Settings=settings;
        end
        
        jsonString = jsonencode(my_settings,'PrettyPrint', true);
    
        % Save the JSON string to a file
        fileID = fopen(strrep(filename,'.json','_GroupHistory.json'), 'w'); % Open a file for writing
        fprintf(fileID, '%s', jsonString);   % Write the JSON string to the file
        fclose(fileID);
    else
        warning('Could not process "%s" because no GroupHistory found.', filename);
    end
end