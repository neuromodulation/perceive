function [files,folder,fullfname] = perceive_ffind(string,cell,rec)
if ~exist('cell','var')
    cell = 1;
end

if ~exist('rec','var')
    rec = 0;
end


if ~rec
    x = ls(string);
    if size(x,1)>1
        files = cellstr(ls(string));
    else
        % On unix, the output of 'ls' is a rich text, see the help for LS:
        %  >> On UNIX, LS returns a character row vector of filenames
        %  >> separated by tab and space characters.
        % On top of that, the text terminates with a newline.
        % Therefore, we can't split only on spaces, but also on tabs and newlines:
        files = strsplit(x);
        % On unix, splitting on newlines can result in the last entry being empty,
        % so we remove empty entries:
        if ~isempty(files)
            nonempty=repmat(true,1,length(files));
            for i=1:length(files)
                if isempty(files{i})
                    nonempty(i)=false;
                end
            end
            files=files(nonempty);
        end
    end
    
    for a =1:length(files)
        ff = fileparts(string);
        if ~isempty(ff)
            folder{a} = ff;
        else
            folder{a} = cd;
        end

    end


else
    
    rdirs=find_folders;
    outfiles=ffind(string,1,0);
    outfolders = {};
    folders = {};
    for a = 1:length(outfiles)
        outfolders{a} = cd;
    end
    for a=1:length(rdirs)
        files=ffind([rdirs{a} filesep string],1,0);
        if ~isempty(files)
            for b = 1:length(files)
                folders{b,1} = [rdirs{a}];
            end
            outfiles = [outfiles;files];
            outfolders = [outfolders;folders];
        end
    end
    files = outfiles;
    folder = outfolders;
end
ris = logical(sum([ismember(files,'.') ,ismember(files,'..')],2));
files(ris)=[];
folder(ris)=[];
[files,x]=unique(files);
folder = folder(x);
% keyboard
if ~isempty(files)
    if ~cell && length(files) == 1
        files = files{1};
        fullfname = [folder{1} filesep files];
    elseif iscell(files) && isempty(files{1})
        files = [];
        folder = [];
        fullfname = [];
    elseif iscell(files)
        for a=1:length(files)
            fullfname{a,1} = [folder{a} filesep files{a}];
        end   
    end
else
    folder = [];
    fullfnames = [];
end
    



% keyboard

