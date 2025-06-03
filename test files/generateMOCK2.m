%% First, deidentify original


inputFilename='Report_Json_Session_Report_PSEUDO47.json';
outputFilename='Report_Json_Session_Report_MOCK1.json';
replaceDigitsOnly(inputFilename, outputFilename)
%%
replaceImplausibleTimes("Report_Json_Session_Report_MOCK1.json", "Report_Json_Session_Report_MOCK2.json")

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

