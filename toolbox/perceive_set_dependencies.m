function perceive_set_dependencies()
%#function set_firstsample check_fullname check_stim onAppClose perceive_check_stim
    % MATLAB Compiler does not trace helpers referenced only as strings in a cell array.
    % perceive.m lists them in a %#function pragma so mcc bundles them.
    if isdeployed
        perceive_set_dependencies_deployed();
    else
        perceive_set_dependencies_development();
    end
end

function perceive_set_dependencies_deployed()
    % CTF layout: optional peer folders next to the archived toolbox root (see mcc -a).
    root = ctfroot;
    subdirs = {'config', 'helper_functions', 'standalone_scripts'};
    for i = 1:numel(subdirs)
        p = fullfile(root, subdirs{i});
        if exist(p, 'dir')
            addpath(p);
        end
    end

    functionsToCheck = {'set_firstsample', 'check_fullname', 'check_stim', 'onAppClose'};
    for k = 1:numel(functionsToCheck)
        fn = functionsToCheck{k};
        if ~perceive_deployed_fexists(fn)
            error(['Deployed executable cannot resolve ''%s'' (which: %s).\n', ...
                   'Rebuild after pulling latest perceive.m (%%#function + perceive_mcc_dependency_touch). ', ...
                   'If it persists: mcc ... -a toolbox\\check_stim.m -a toolbox\\helper_functions\n', ...
                   'CTF root: %s'], fn, perceive_safe_which(fn), root);
        end
    end
end

function perceive_set_dependencies_development()
    % Add helper folders; layouts vary (MLTBX, flat, or source tree).
    thisDir = fileparts(mfilename('fullpath'));
    perceiveDir = fileparts(which('perceive'));

    rawRoots = {
        fullfile(thisDir, 'helper_functions')
        fullfile(perceiveDir, 'helper_functions')
        thisDir
        perceiveDir
    };
    candidateRoots = perceive_dedupe_nonempty_paths(rawRoots);

    functionsToCheck = {'set_firstsample', 'check_fullname', 'check_stim', 'onAppClose'};

    dirsToAdd = {};
    for k = 1:numel(functionsToCheck)
        fn = functionsToCheck{k};
        foundPath = perceive_find_helper_mfile(candidateRoots, fn);
        if isempty(foundPath)
            error(['Required helper ''%s'' was not found under any of:\n%s\n', ...
                   'Include toolbox/helper_functions (or the same .m files next to perceive.m) in the toolbox package.'], ...
                  fn, perceive_format_cell_paths(candidateRoots));
        end
        d = fileparts(foundPath);
        if isempty(dirsToAdd) || ~any(strcmp(dirsToAdd, d))
            dirsToAdd{end+1} = d; %#ok<AGROW>
        end
    end

    for i = 1:numel(dirsToAdd)
        addpath(dirsToAdd{i});
    end

    rawStandalone = {
        fullfile(thisDir, 'standalone_scripts')
        fullfile(perceiveDir, 'standalone_scripts')
    };
    for i = 1:numel(rawStandalone)
        sd = strtrim(rawStandalone{i});
        if ~isempty(sd) && exist(sd, 'dir')
            addpath(sd);
        end
    end
end

function roots = perceive_dedupe_nonempty_paths(rawRoots)
    roots = {};
    for i = 1:numel(rawRoots)
        r = strtrim(rawRoots{i});
        if isempty(r)
            continue;
        end
        dup = false;
        for j = 1:numel(roots)
            if strcmp(roots{j}, r)
                dup = true;
                break;
            end
        end
        if ~dup
            roots{end+1} = r; %#ok<AGROW>
        end
    end
end

function p = perceive_find_helper_mfile(candidateRoots, functionName)
    p = '';
    base = [functionName '.m'];
    for r = 1:numel(candidateRoots)
        root = candidateRoots{r};
        if isempty(root) || ~exist(root, 'dir')
            continue;
        end
        cand = fullfile(root, base);
        if exist(cand, 'file') == 2
            p = cand;
            return;
        end
        listing = dir(root);
        for k = 1:numel(listing)
            if listing(k).isdir
                continue;
            end
            if strcmpi(listing(k).name, base)
                p = fullfile(root, listing(k).name);
                return;
            end
        end
    end
end

function s = perceive_format_cell_paths(c)
    s = strjoin(c(:)', newline);
end

function tf = perceive_deployed_fexists(fn)
    w = which(fn);
    tf = ~isempty(w);
end

function s = perceive_safe_which(fn)
    try
        w = which(fn);
        if isempty(w)
            s = '(empty)';
        else
            s = w;
        end
    catch %#ok<CTCH>
        s = '(which failed)';
    end
end
