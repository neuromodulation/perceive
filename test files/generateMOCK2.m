
inputFilename='Report_Json_Session_Report_PSEUDO47.json';
outputFilename='Report_Json_Session_Report_MOCK1.json';
replaceDigitsOnly(inputFilename, outputFilename)

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

