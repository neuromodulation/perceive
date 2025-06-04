function [files, folder, fullfname] = perceive_ffind(string, cellmode, rec)
% perceive_ffind - cross-platform file finder
% 
% Inputs:
%   string   - pattern to match, e.g., '*.mat' or fullfile(folder, '*BSL*.mat')
%   cellmode - 1 (default): return cell array; 0: return char if only one file
%   rec      - 1: recursive search; 0 (default): current folder only
%
% Outputs:
%   files      - list of filenames
%   folder     - corresponding folder(s)
%   fullfname  - full path(s)

% --- defaults ---
if ~exist('cellmode','var') || isempty(cellmode), cellmode = 1; end
if ~exist('rec','var') || isempty(rec), rec = 0; end

% --- non-recursive mode ---
if ~rec
    % handle relative paths
    if startsWith(string, './') || startsWith(string, '.\')
        string = fullfile(pwd, string(3:end));
    elseif startsWith(string, '*') || startsWith(string, filesep)
        string = fullfile(pwd, string);
    end

    % use dir (instead of ls)
    d = dir(string);
    if isempty(d)
        files = {};
        folder = {};
        fullfname = {};
        return
    end

    files = {d.name}';
    folder = {d.folder}';
    
% --- recursive search ---
else
    rdirs = find_folders;
    outfiles = {};
    outfolders = {};
    for i = 1:length(rdirs)
        d = dir(fullfile(rdirs{i}, string));
        if ~isempty(d)
            outfiles = [outfiles; {d.name}'];
            outfolders = [outfolders; repmat(rdirs(i), numel(d), 1)];
        end
    end
    files = outfiles;
    folder = outfolders;
end

% --- clean results ---
% remove '.' and '..'
keep = ~ismember(files, {'.','..'});
files = files(keep);
folder = folder(keep);

% remove duplicates
[files, uniq_idx] = unique(files, 'stable');
folder = folder(uniq_idx);

% --- full filenames ---
if isempty(files)
    fullfname = [];
elseif ~cellmode && numel(files) == 1
    files = files{1};
    fullfname = fullfile(folder{1}, files);
else
    for a = 1:length(files)
        fullfname{a,1} = fullfile(folder{a}, files{a});
    end
end
end


