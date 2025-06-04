function generateMOCK2(inputFilename,outputFilename)

%% First, deidentify original
js = jsondecode(fileread(inputFilename));
pseudonymize(js,outputFilename);
%%
replaceDigitsOnly(outputFilename, outputFilename)
%%
replaceImplausibleTimes(outputFilename, outputFilename)
%%
ReplaceFracTimestamps(outputFilename, outputFilename)
%%
updateIndividualFields(outputFilename, outputFilename)
%%
end

%% list of functions
function s = updateFieldWithSubkey(s, key, subkey)
    if isstruct(s)
        fields = fieldnames(s);
        for i = 1:numel(fields)
            fieldValue = s.(fields{i});
            
            % Check if the current field matches the key and contains the subkey
            if strcmp(fields{i}, key) && isstruct(fieldValue) && isfield(fieldValue, subkey)
                % Indefinite Streaming: special case where six first
                % Timestamps should be equal, next six should be equal etc.
                if strcmp(key, 'IndefiniteStreaming')
                    for a = 1:length(s.(fields{i}))/6
                        b=(6*(a-1)+1);
                        s.(fields{i})(b+1).(subkey) = (s.(fields{i})(b).(subkey)); % Update subkey value
                        s.(fields{i})(b+2).(subkey) = (s.(fields{i})(b).(subkey)); % Update subkey value
                        s.(fields{i})(b+3).(subkey) = (s.(fields{i})(b).(subkey)); % Update subkey value
                        s.(fields{i})(b+4).(subkey) = (s.(fields{i})(b).(subkey)); % Update subkey value
                        s.(fields{i})(b+5).(subkey) = (s.(fields{i})(b).(subkey)); % Update subkey value
                        s.(fields{i})(b+1).('TicksInMses') = (s.(fields{i})(b).('TicksInMses')); % Update subkey value
                        s.(fields{i})(b+2).('TicksInMses') = (s.(fields{i})(b).('TicksInMses')); % Update subkey value
                        s.(fields{i})(b+3).('TicksInMses') = (s.(fields{i})(b).('TicksInMses')); % Update subkey value
                        s.(fields{i})(b+4).('TicksInMses') = (s.(fields{i})(b).('TicksInMses')); % Update subkey value
                        s.(fields{i})(b+5).('TicksInMses') = (s.(fields{i})(b).('TicksInMses')); % Update subkey value
                    end
                elseif strcmp(key, 'BrainSenseTimeDomain')
                    % read the timedomaindata
                    timedomaindata = zeros(length(s.(fields{i})));
                    for j = 1:length(s.(fields{i}))
                        timedomaindata(j) = size(s.(fields{i})(j).('TimeDomainData'),1);
                    end
                    for a = 2:length(s.(fields{i}))
                        thistime = timedomaindata(a);
                        if (thistime == timedomaindata(a-1))
                            % if this recording length is the same as the 
                            % previous one: copy TicksinMses and FirstPacketDateTime
                            s.(fields{i})(a).('FirstPacketDateTime') = s.(fields{i})(a-1).('FirstPacketDateTime');
                            s.(fields{i})(a).('TicksInMses') = s.(fields{i})(a-1).('TicksInMses');
                        end
                    end
                    % for a = 1:length(s.(fields{i}))/2
                    %     b=(2*(a-1)+1);
                    %     s.(fields{i})(b+1).(subkey) = (s.(fields{i})(b).(subkey)); % Update subkey value
                    %     s.(fields{i})(b+1).('TicksInMses') = (s.(fields{i})(b).('TicksInMses')); % Update subkey value
                    % 
                    % end
                end
            elseif isstruct(fieldValue) % Handle nested structures
                if numel(fieldValue) > 1 % If it's a struct array
                    for j = 1:numel(fieldValue)
                        fieldValue(j) = updateFieldWithSubkey(fieldValue(j), key, subkey); % Process each struct separately
                    end
                    s.(fields{i}) = fieldValue; % Assign back
                else
                    s.(fields{i}) = updateFieldWithSubkey(fieldValue, key, subkey); % Recursively process scalar structs
                end
            elseif iscell(fieldValue) % Handle cell arrays containing structs
                for j = 1:numel(fieldValue)
                    if isstruct(fieldValue{j})
                        fieldValue{j} = updateFieldWithSubkey(fieldValue{j}, key, subkey);
                    end
                end
                s.(fields{i}) = fieldValue;
            end
        end
    end
end
%%
function updateIndividualFields(inputFile, outputFile)
    % Read JSON file
    jsonText = fileread(inputFile);
    
    % Decode JSON to MATLAB struct
    dataStruct = jsondecode(jsonText);
    
    % Modify key-value pairs recursively
    dataStruct = updateThisField(dataStruct, 'SampleInHz', 250);
    dataStruct = updateThisField(dataStruct, 'DataVersion', '1.2');
    dataStruct = updateThisField(dataStruct, 'RateInHertz', 125);
    dataStruct = updateThisField(dataStruct, 'SampleRateInHz', 250);
    dataStruct = updateTicksInMses(dataStruct);
    [dataStruct, ~] = updateTicksInMs(dataStruct, 0);
    dataStruct = updateFieldWithSubkey(dataStruct, 'IndefiniteStreaming', 'FirstPacketDateTime');
    dataStruct = updateFieldWithSubkey(dataStruct, 'BrainSenseTimeDomain', 'FirstPacketDateTime');
    %% modify symptoms
    %'Feeling good', 'Feeling off', 'Took Medication', 'überbeweglich', 'unterbeweglich', 'Dyskinesia'
    dataStruct = updateThisField(dataStruct, 'EventName', "DummyEvent");

    % Encode back to JSON (pretty formatting)
    jsonText = jsonencode(dataStruct, 'PrettyPrint', true);
    
    % Write to output file
    fid = fopen(outputFile, 'w');
    if fid == -1
        error('Could not open output file.');
    end
    fwrite(fid, jsonText);
    fclose(fid);
    
    fprintf('Modified JSON saved to %s\n', outputFile);
end

function s = updateThisField(s, key, value)
    if isstruct(s)
        fields = fieldnames(s);
        for i = 1:numel(fields)
            fieldValue = s.(fields{i});
            
            if strcmp(fields{i}, key)
                s.(fields{i}) = value; % Update value
            elseif isstruct(fieldValue) % Handle nested structures
                if numel(fieldValue) > 1 % If it's a struct array
                    for j = 1:numel(fieldValue)
                        fieldValue(j) = updateThisField(fieldValue(j),key,value); % Process each struct separately
                    end
                    s.(fields{i}) = fieldValue; % Assign back
                else
                    s.(fields{i}) = updateThisField(fieldValue,key,value); % Recursively process scalar structs
                end
            elseif iscell(fieldValue) % Handle cell arrays containing structs
                for j = 1:numel(fieldValue)
                    if isstruct(fieldValue{j})
                        fieldValue{j} = updateThisField(fieldValue{j},key,value);
                    end
                end
                s.(fields{i}) = fieldValue;
            end
        end
    end
end

function s = updateTicksInMses(s)
    if isstruct(s)
        fields = fieldnames(s);
        for i = 1:numel(fields)
            fieldValue = s.(fields{i});
            
            if strcmp(fields{i}, 'TicksInMses')
                parts = strsplit(s.(fields{i}), ',');
                parts(end)=[];
                len = size(parts,2);
                if len
                    idx=0:(len-1);
                    newNums = str2num(parts{1})+floor(idx/2)*250;
                s.(fields{i}) = strjoin(string(newNums), ','); % Update value
                end
            elseif isstruct(fieldValue) % Handle nested structures
                if numel(fieldValue) > 1 % If it's a struct array
                    for j = 1:numel(fieldValue)
                        fieldValue(j) = updateTicksInMses(fieldValue(j)); % Process each struct separately
                    end
                    s.(fields{i}) = fieldValue; % Assign back
                else
                    s.(fields{i}) = updateTicksInMses(fieldValue); % Recursively process scalar structs
                end
            elseif iscell(fieldValue) % Handle cell arrays containing structs
                for j = 1:numel(fieldValue)
                    if isstruct(fieldValue{j})
                        fieldValue{j} = updateTicksInMses(fieldValue{j});
                    end
                end
                s.(fields{i}) = fieldValue;
            end
        end
    end
end

function [s,oldmtick] = updateTicksInMs(s, oldmtick)
    if isstruct(s)
        fields = fieldnames(s);
        for i = 1:numel(fields)
            fieldValue = s.(fields{i});
            
            if strcmp(fields{i}, 'TicksInMs')
                s.(fields{i}) = oldmtick; % Update value
                oldmtick = oldmtick +250;
            elseif isstruct(fieldValue) % Handle nested structures
                if numel(fieldValue) > 1 % If it's a struct array
                    for j = 1:numel(fieldValue)
                        [fieldValue(j),oldmtick] = updateTicksInMs(fieldValue(j),oldmtick); % Process each struct separately
                    end
                    s.(fields{i}) = fieldValue; % Assign back
                else
                    [s.(fields{i}),oldmtick] = updateTicksInMs(fieldValue,oldmtick); % Recursively process scalar structs
                end
            elseif iscell(fieldValue) % Handle cell arrays containing structs
                for j = 1:numel(fieldValue)
                    if isstruct(fieldValue{j})
                        [fieldValue{j},oldmtick] = updateTicksInMs(fieldValue{j},oldmtick);
                    end
                end
                s.(fields{i}) = fieldValue;
            end
        end
    end
end




%%
function firstsample = set_firstsample(string_of_TicksInMses)
    parts = strsplit(string_of_TicksInMses, ',');
    % Extract the first part and convert it to a number, divide by 50ms
    firstsample = str2num(parts{1})/50;
    if isempty(firstsample)
        firstsample=1;
    end
end
%%
function ReplaceFracTimestamps(inputFilename, outputFilename)
%REPLACEFRACTIMESTAMPS  Read text (e.g. JSON), find all ISO‐style timestamps
% with fractional seconds (“YYYY-MM-DDThh:mm:ss.xxxZ”), replace each with a
% strictly increasing 2019-based timestamp that also contains fractional seconds,
% and write the modified text to a new file.
%
% Usage:
%   ReplaceFracTimestamps('in.json','out.json');
%
%   – Matches only timestamps of the form:
%       4+ digits-2 digits-2 digits 'T' 2 digits:2 digits:2 digits '.' 1+ digits 'Z'
%   – Builds a sequence in UTC starting at a random time on Jan 1, 2019, and for
%     each subsequent timestamp adds a random [0.001 s, 3600 s] increment so that
%     each new timestamp > previous.
%   – Formats each replacement with exactly three fractional digits (milliseconds).
    % Read entire file
    fid = fopen(inputFilename,'r');
    if fid < 0
        error('Cannot open input file: %s', inputFilename);
    end
    txt = fread(fid,'*char')';
    fclose(fid);
    % Regex: YYYY-MM-DDThh:mm:ss.xxxZ  (xxx = one-or-more digits)
    fracPattern = '\d{4,}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+Z';
    % Find matches with start/end indices
    [oldTimes, starts, ends] = regexp(txt, fracPattern, 'match', 'start', 'end');
    N = numel(oldTimes);
    if N == 0
        % No fractional-second timestamps → copy input to output
        fid = fopen(outputFilename,'w');
        fwrite(fid, txt);
        fclose(fid);
        return
    end
    % Preallocate datetime array with UTC timezone
    newDT = NaT(N,1,'TimeZone','UTC');
    % Initialize first timestamp: random offset in (0, 86400) seconds after 2019-01-01
    t0 = datetime(2019,1,1,0,0,0,'TimeZone','UTC');
    firstOffset = seconds(rand() * (86400 - eps));  % rand in [0,1), avoid exact 86400
    newDT(1) = t0 + firstOffset;
    % Each subsequent: add a random increment between 0.001 s and 3600 s
    tprev = newDT(1);
    for k = 2:N
        delta = rand() * (3600 - 0.001) + 0.001;  % ∈ [0.001, 3600)
        tprev = tprev + seconds(delta);
        newDT(k) = tprev;
    end
    % Format with three-digit milliseconds: “yyyy-MM-ddTHH:mm:ss.SSSZ”
    newStr = string(newDT, "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
    % Reconstruct text by splicing in replacements
    parts = strings(1, 2*N+1);
    idxPrev = 1;
    for k = 1:N
        sIdx = starts(k);
        eIdx = ends(k);
        parts(2*k-1) = txt(idxPrev:sIdx-1);
        parts(2*k)   = newStr(k);
        idxPrev = eIdx + 1;
    end
    parts(end) = txt(idxPrev:end);
    outTxt = strjoin(parts, '');
    % Write out modified text
    fid = fopen(outputFilename,'w');
    if fid < 0
        error('Cannot open output file: %s', outputFilename);
    end
    fwrite(fid, outTxt);
    fclose(fid);
end
%%
function replaceImplausibleTimes(inputFilename, outputFilename)
%REPLACEIMPLAUSIBLETIMES  Read a JSON‐formatted text, replace all ISO‐style
% timestamps (even if fields are invalid) with plausible, strictly increasing
% datetimes starting in 2019, and write the result to a new file.
%
%   ReplaceImplausibleTimes('in.json','out.json');
%
%   – Assumes timestamps appear as “YYYY-MM-DDThh:mm:ssZ” (digits separated by
%     “-”, “T”, “:”, “Z”), even if the original numbers are out of range.
%   – Each replacement is drawn by starting at Jan 1, 2019 00:00:00 UTC and
%     adding a random positive increment (1–3600 s) so that each new timestamp
%     strictly exceeds the previous one.
%   – Writes modified text (with all timestamps replaced) to outputFilename.
%

    % Read file into a char array
    fid = fopen(inputFilename,'r');
    if fid < 0
        error('Cannot open input file: %s', inputFilename);
    end
    jsonText = fread(fid,'*char')';
    fclose(fid);

    % Pattern: four or more digits, “-”, two digits, “-”, two digits, “T”,
    % two digits, “:”, two digits, “:”, two digits, “Z”
    timePattern = '\d{4,}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z';

    % Find all matches with start/end indices
    [oldTimes, starts, ends] = regexp(jsonText, timePattern, 'match', 'start', 'end');
    N = numel(oldTimes);
    if N == 0
        % No ISO‐style timestamps found; just copy input to output
        fid = fopen(outputFilename,'w');
        fwrite(fid, jsonText);
        fclose(fid);
        return
    end

    % Preallocate new‐time array
    newDatetimes = NaT(N,1);

    % Initialize first timestamp at a random time on Jan 1, 2019
    % (e.g. between 00:00:01 and 23:59:59 UTC)
    firstOffset = seconds(randi([1, 86400-1]));
    tprev = datetime(2019,1,1,0,0,0) + firstOffset;
    newDatetimes(1) = tprev;

    % For k = 2..N, add a random 1–3600 s increment to ensure strict ordering
    for k = 2:N
        incr = seconds(randi([1, 3600]));
        tprev = tprev + incr;
        newDatetimes(k) = tprev;
    end

    % Convert newDatetimes to ISO‐8601 “YYYY-MM-DDTHH:MM:SSZ” strings
    % (use UTC format explicitly)
    newTimeStrings = string(newDatetimes, 'yyyy-MM-dd''T''HH:mm:ss''Z''');

    % Reconstruct the JSON text, replacing each old timestamp with newTimeStrings{k}
    builder = strings(1, 2*N+1);
    idxPrev = 1;
    for k = 1:N
        idxStart = starts(k);
        idxEnd   = ends(k);
        builder(2*k-1) = jsonText(idxPrev:idxStart-1); 
        builder(2*k  ) = newTimeStrings(k);
        idxPrev = idxEnd + 1;
    end
    builder(end) = jsonText(idxPrev:end);
    modifiedText = strjoin(builder, '');

    % Write result to output file
    fid = fopen(outputFilename,'w');
    if fid < 0
        error('Cannot open output file: %s', outputFilename);
    end
    fwrite(fid, modifiedText);
    fclose(fid);
end

%%
function replaceDigitsOnly(inputFile, outputFile)
    % Read the file content
    fileContent = fileread(inputFile);
    
    % Replace only numeric characters (digits) with random digits
    %modifiedContent = regexprep(fileContent, '\d', @(x) num2str(randi([0,9])));

    c = char(fileContent);                 % convert to character array
    digitPos = regexp(c, '\d');  % indices of all digits
    for k = digitPos
        c(k) = char('0' + randi([1,9]));
    end
    modifiedContent = string(c);

    % Write modified content to a new file
    fid = fopen(outputFile, 'w');
    if fid == -1
        error('Could not open output file.');
    end
    fwrite(fid, modifiedContent);
    fclose(fid);
    
    fprintf('Modified content saved to %s\n', outputFile);
end

%%
function js=pseudonymize(js, outputfilename)
try
    js.PatientInformation.Initial.PatientFirstName ='';
    js.PatientInformation.Initial.PatientLastName ='';
    js.PatientInformation.Initial.PatientDateOfBirth ='';
    js.PatientInformation.Initial.PatientGender='';
    js.PatientInformation.Initial.Diagnosis ='DiagnosisTypeDef.ParkinsonsDisease';
    js.PatientInformation.Final.PatientFirstName ='';
    js.PatientInformation.Final.PatientLastName ='';
    js.PatientInformation.Final.PatientDateOfBirth ='';
    js.PatientInformation.Final.PatientGender='';
    js.PatientInformation.Final.Diagnosis ='DiagnosisTypeDef.ParkinsonsDisease';

catch
    js = rmfield(js,'PatientInformation');
    js.PatientInformation.Initial.PatientFirstName ='';
    js.PatientInformation.Initial.PatientLastName ='';
    js.PatientInformation.Initial.PatientDateOfBirth ='';
    js.PatientInformation.Initial.PatientGender='';
    js.PatientInformation.Initial.Diagnosis ='DiagnosisTypeDef.ParkinsonsDisease';
    js.PatientInformation.Final.PatientFirstName ='';
    js.PatientInformation.Final.PatientLastName ='';
    js.PatientInformation.Final.PatientDateOfBirth ='';
    js.PatientInformation.Final.PatientGender='';
    js.PatientInformation.Final.Diagnosis = 'DiagnosisTypeDef.ParkinsonsDisease';
end


jsonText = jsonencode(js, 'PrettyPrint', true);
    
    % Write JSON to file
    fid = fopen([outputfilename], 'w');
    if fid == -1
        error('Could not open file for writing.');
    end
    fwrite(fid, jsonText);
    fclose(fid);

end